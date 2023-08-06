#!/usr/bin/env python

import argparse
import collections
import contextlib
import logging
import os
from os.path import exists
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import textwrap
import typing
import zipfile

logger = logging.getLogger(__name__)


VcArchDevel = collections.namedtuple("VcArchDevel", ("dll", "dev"))


class Executer:
    def __init__(self, root: Path, dry: bool=False):
        self.root = root
        self.dry = dry

    def run(self, cmd, stdout=False, dry_out=None, force=False):
        sys.stdout.flush()
        logger.info("Executing args=%r", cmd)
        if self.dry:
            if stdout:
                return subprocess.run(["echo", dry_out or ""], stdout=subprocess.PIPE if stdout else None, text=True, cwd=self.root)
        else:
            return subprocess.run(cmd, stdout=subprocess.PIPE if stdout else None, text=True)


class SectionPrinter:
    @contextlib.contextmanager
    def group(self, title: str):
        print(f"{title}:")
        yield


class GitHubSectionPrinter(SectionPrinter):
    def __init__(self):
        super().__init__()
        self.in_group = False

    @contextlib.contextmanager
    def group(self, title: str):
        print(f"::group::{title}")
        assert not self.in_group, "Can enter a group only once"
        self.in_group = True
        yield
        self.in_group = False
        print("::endgroup::")


class VisualStudio:
    def __init__(self, executer: Executer, year: typing.Optional[str]=None):
        self.executer = executer
        self.vsdevcmd = self.find_vsdevcmd(year)
        self.msbuild = self.find_msbuild()

    @property
    def dry(self):
        return self.executer.dry

    VS_YEAR_TO_VERSION = {
        "2022": 17,
        "2019": 16,
        "2017": 15,
        "2015": 14,
        "2013": 12,
    }

    def find_vsdevcmd(self, year: typing.Optional[str]=None) -> typing.Optional[Path]:
        vswhere_spec = ["-latest"]
        if year is not None:
            try:
                version = cls.VS_YEAR_TO_VERSION[year]
            except KeyError:
                logger.error("Invalid Visual Studio year")
                return None
            vswhere_spec.extend(["-version", f"[{version},{version+1})"])
        vswhere_cmd = ["vswhere"] + vswhere_spec + ["-property", "installationPath"]
        vs_install_path = Path(self.executer.run(vswhere_cmd, stdout=True, dry_out="/tmp").stdout.strip())
        logger.info("VS install_path = %s", vs_install_path)
        assert vs_install_path.is_dir(), "VS installation path does not exist"
        vsdevcmd_path = vs_install_path / "Common7/Tools/vsdevcmd.bat"
        logger.info("vsdevcmd path = %s", vsdevcmd_path)
        if self.dry:
            vsdevcmd_path.parent.mkdir(parents=True, exist_ok=True)
            vsdevcmd_path.touch(exist_ok=True)
        assert vsdevcmd_path.is_file(), "vsdevcmd.bat batch file does not exist"
        return vsdevcmd_path

    def find_msbuild(self) -> typing.Optional[Path]:
        vswhere_cmd = ["vswhere", "-latest", "-requires", "Microsoft.Component.MSBuild", "-find", "MSBuild\**\Bin\MSBuild.exe"]
        msbuild_path = Path(self.executer.run(vswhere_cmd, stdout=True, dry_out="/tmp/MSBuild.exe").stdout.strip())
        logger.info("MSBuild path = %s", msbuild_path)
        if self.dry:
            msbuild_path.parent.mkdir(parents=True, exist_ok=True)
            msbuild_path.touch(exist_ok=True)
        assert msbuild_path.is_file(), "MSBuild.exe does not exist"
        return msbuild_path

    def build(self, arch: str, platform: str, configuration: str, projects: list[Path]):
        assert projects, "Need at least one project to build"

        vsdev_cmd_str = f"\"{self.vsdevcmd}\" -arch={arch}"
        msbuild_cmd_str = " && ".join([f"\"{self.msbuild}\" \"{project}\" /m /p:BuildInParallel=true /p:Platform={platform} /p:Configuration={configuration}" for project in projects])
        bat_contents = f"{vsdev_cmd_str} && {msbuild_cmd_str}\n"
        bat_path = Path(tempfile.gettempdir()) / "cmd.bat"
        with bat_path.open("w") as f:
            f.write(bat_contents)

        logger.info("Running cmd.exe script (%s): %s", bat_path, bat_contents)
        cmd = ["cmd.exe", "/D", "/E:ON", "/V:OFF", "/S", "/C", f"CALL {str(bat_path)}"]
        self.executer.run(cmd)


class Releaser:
    def __init__(self, root: Path, commit: str, dist_path: Path, section_printer: SectionPrinter, executer=Executer):
        self.root = root
        self.project = self.extract_project_name(root=root)
        self.bare_project = re.sub("[0-9]", "", self.project)
        self.version = self.extract_sdl_version(root=root, project=self.project, bare_project=self.bare_project)
        self.commit = commit
        self.dist_path = dist_path
        self.section_printer = section_printer
        self.executer = executer
        self.artifacts = {}

    @property
    def dry(self):
        return self.executer.dry

    def prepare(self):
        logger.debug("Creating dist folder")
        self.dist_path.mkdir(parents=True, exist_ok=True)

    def _git_archive(self, out: Path):
        out.unlink(missing_ok=True)
        self.executer.run(["git", "archive", self.commit, "--prefix", f"{self.project}-{self.version}/", "-o", out], force=True)
        if self.dry:
            out.touch(exist_ok=True)
        assert out.is_file(), "Source archive has not been created"

    def create_source_archives(self):
        archive_base = f"{self.project}-{self.version}"
        temp_tar_gz = Path(tempfile.gettempdir()) / f"{archive_base}-temp.tar.gz"

        logger.debug("Running git archive to create a temporary tar.gz source archive (%s)...", temp_tar_gz)
        self._git_archive(out=temp_tar_gz)

        def file_filter(member: tarfile.TarInfo, path: str, /) -> tarfile.TarInfo | None:
            name_path = Path(member.name)
            if name_path.name == ".gitignore":
                logger.debug("Removing %s from source archives", member.name)
                return None
            if any(e == ".github" for e in name_path.parts):
                logger.debug("Removing %s from source archives", member.name)
                return None
            if any(".xcframework" in e or ".framework" in e for e in name_path.parts):
                logger.debug("Removing %s from source archives", member.name)
                return None
            return member

        temp_extract = Path(tempfile.gettempdir()) / f"{archive_base}-temp"
        shutil.rmtree(temp_extract, ignore_errors=True)
        temp_extract.mkdir(parents=True)

        if not self.dry:
            logger.debug("Extracting source git archive to temporary directory for filtering (%s)", temp_extract)
            tf = tarfile.open(temp_tar_gz, mode="r:gz")
            tf.extractall(temp_extract, filter=file_filter)

        tar_xz = self.dist_path / f"{archive_base}.tar.gz"
        logger.debug("Creating tar.xz source archive (%s)...", tar_xz)
        with tarfile.open(tar_xz, mode="w:xz") as tf:
            tf.add(temp_extract / archive_base, arcname=archive_base)
        self.artifacts["src-tar-xz"] = tar_xz

        zip = self.dist_path / f"{archive_base}.zip"
        logger.debug("Creating zip source archive (%s)...", zip)
        with zipfile.ZipFile(zip, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(temp_extract):
                root = Path(root)
                rel_root = root.relative_to(temp_extract)
                for dir in dirs:
                    zf.mkdir(str(rel_root / dir))
                for file in files:
                    zf.write(root / file, arcname=rel_root / file)

        self.artifacts["src-zip"] = zip

    def create_xcframework(self, configuration:str="Release"):
        dmg_in = self.root / f"Xcode/SDL/build/{self.project}.dmg"
        dmg_in.unlink(missing_ok=True)
        self.executer.run(["xcodebuild", "-project", self.root / f"Xcode/{self.bare_project}/{self.bare_project}.xcodeproj", "-target", f"{self.project}.dmg", "-configuration", configuration])
        if self.dry:
            dmg_in.parent.mkdir(parents=True, exist_ok=True)
            dmg_in.touch()

        assert dmg_in.is_file(), f"{self.project} was not created by xcodebuild"

        dmg_out = self.dist_path / f"{self.project}-{self.version}.dmg"
        shutil.copy(dmg_in, dmg_out)
        self.artifacts["dmg"] = dmg_out

    def build_vs(self, arch: str, platform: str, vs: VisualStudio, configuration: str="Release"):
        solution_path = self.root / f"VisualC/{self.bare_project}.sln"
        assert solution_path.exists(), f"Cannot find {self.bare_project}.sln"

        main_project = solution_path.parent / f"{self.bare_project}.vcxproj"
        if not main_project.is_file():
            main_project = solution_path.parent / f"{self.bare_project}/{self.bare_project}.vcxproj"
        assert main_project.is_file(), f"Cannot find {self.bare_project}.vcxproj"
        projects = [
            main_project,
        ]
        dll_artifacts = [
            solution_path.parent / f"{platform}/{configuration}/{self.project}.dll",
        ]
        dev_artifacts = [
            solution_path.parent / f"{platform}/{configuration}/{self.project}.lib",
        ]

        test_project = self.root / f"VisualC/{self.bare_project}_test/{self.bare_project}_test.vcxproj"
        if test_project.is_file():
            projects.append(projects)
            dev_artifacts.append(solution_path.parent / f"{platform}/{configuration}/{self.project}_test.lib")

        artifacts = dll_artifacts + dev_artifacts

        for artifact in artifacts:
            artifact.unlink(missing_ok=True)

        vs.build(arch=arch, platform=platform, configuration=configuration, projects=projects)

        if self.dry:
            for artifact in artifacts:
                artifact.parent.mkdir(parents=True, exist_ok=True)
                artifact.touch()

        for artifact in artifacts:
            assert artifact.is_file(), f"{artifact.name} has not been created"

        zip_path = self.dist_path / f"{self.project}-{self.version}-win32-{arch}.zip"
        zip_path.unlink(missing_ok=True)
        logger.info("Creating %s", zip_path)
        with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
            for dll in dll_artifacts:
                logger.debug("Adding %s", dll.name)
                zf.write(dll, arcname=dll.name)

            optionals = self.root / f"VisualC/external/optional/{arch}"
            if optionals.is_dir():
                for opt in optionals.iterdir():
                    logger.debug("Adding %s to optional/%s", opt, opt.name)
                    zf.write(opt, arcname=f"optional/{opt.name}")

            for readme in ("README-SDL.txt", "README.txt"):
                readme_path = self.root / readme
                if readme_path.is_file():
                    logger.debug("Adding %s", readme)
                    zf.write(readme_path, arcname=readme_path.name)
                    break
            if not readme_path.is_file():
                assert readme_path.is_file(), "Cannot find a readme text file"

        self.artifacts[f"VC-{arch}"] = zip_path

        return VcArchDevel(dll=dll_artifacts, dev=dev_artifacts)

    def build_vs_devel(self, arch_vc: dict[str, VcArchDevel]):
        zip_path = self.dist_path / f"{self.project}-devel-{self.version}-VC.zip"
        archive_prefix = f"{self.project}-{self.version}"

        def zip_file(zf: zipfile.ZipFile, path: Path, arcrelpath: str):
            arcname = f"{archive_prefix}/{arcrelpath}"
            logger.debug("Adding %s to %s", path, arcname)
            zf.write(path, arcname=arcname)

        def zip_directory(zf: zipfile.ZipFile, directory: Path, arcrelpath: str):
            for f in directory.iterdir():
                if f.is_file():
                    arcname = f"{archive_prefix}/{arcrelpath}/{f.name}"
                    logger.debug("Adding %s to %s", f, arcname)
                    zf.write(f, arcname=arcname)

        with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
            for arch, binaries in arch_vc.items():
                for dll in binaries.dll:
                    zip_file(zf, path=dll, arcrelpath=f"lib/{arch}/{dll.name}")
                for lib in binaries.dev:
                    zip_file(zf, path=lib, arcrelpath=f"lib/{arch}/{lib.name}")

                optionals = self.root / f"VisualC/external/optional/{arch}"
                if optionals.is_dir():
                    for opt in optionals.iterdir():
                        zip_file(zf, path=opt, arcrelpath=f"lib/{arch}/optional/{opt.name}")

            zip_directory(zf, directory=self.root / f"include/{self.project}", arcrelpath=f"include/{self.project}")
            zip_directory(zf, directory=self.root / "docs", arcrelpath="docs")
            zip_directory(zf, directory=self.root / "VisualC/pkg-support/cmake", arcrelpath="cmake")

            for txt in ("BUGS.txt", "README-SDL.txt", "WhatsNew.txt", "LICENSE.txt", "CHANGES.txt"):
                txt_path = self.root / txt
                if txt_path.is_file():
                    zip_file(zf, path=txt_path, arcrelpath=txt_path.name)
            for readme in ("README.md", "README.txt"):
                readme_path = self.root / readme
                if readme_path.is_file():
                    zip_file(zf, path=readme_path, arcrelpath=readme_path.name)
                    break
            assert readme_path.is_file(), "Could not find readme text file"

        self.artifacts["VC-devel"] = zip_path

    @classmethod
    def extract_project_name(cls, root: Path) -> str:
        text = (root / "CMakeLists.txt").open().read()
        return next(re.finditer(r"^project\(([A-Za-z0-9_]+)\s", text, flags=re.M)).group(1)

    @classmethod
    def extract_sdl_version(cls, root: Path, project: str, bare_project: str) -> str:
        version_path = root / f"include/{project}/{bare_project}_version.h"
        if not version_path.exists():
            version_path = root / f"include/{project}/{bare_project}.h"
        logger.debug("Extracting version from %s", version_path)

        with version_path.open() as f:
            text = f.read()

        major = next(re.finditer(rf"^#define {bare_project.upper()}_MAJOR_VERSION\s+([0-9]+)$", text, flags=re.M)).group(1)
        minor = next(re.finditer(rf"^#define {bare_project.upper()}_MINOR_VERSION\s+([0-9]+)$", text, flags=re.M)).group(1)
        patch = next(re.finditer(rf"^#define {bare_project.upper()}_PATCHLEVEL\s+([0-9]+)$", text, flags=re.M)).group(1)
        return f"{major}.{minor}.{patch}"


def main(argv=None):
    parser = argparse.ArgumentParser(allow_abbrev=False, description="Create SDL release artifacts")
    parser.add_argument("--root", metavar="DIR", type=Path, default=Path(__file__).resolve().parents[1], help="Root of SDL")
    parser.add_argument("--out", "-o", metavar="DIR", dest="dist_path", type=Path, default="dist", help="Output directory")
    parser.add_argument("--github", action="store_true", help="Script is running on a GitHub runner")
    parser.add_argument("--commit", default="HEAD", help="Git commit/tag of which a release should be created")
    parser.add_argument("--create", choices=["source", "win32", "xcframework"], required=True,action="append", dest="actions", help="SDL version")
    parser.set_defaults(loglevel=logging.INFO)
    parser.add_argument('--vs-year', dest="vs_year", help="Visual Studio year")
    parser.add_argument('--debug', action='store_const', const=logging.DEBUG, dest="loglevel", help="Print script debug information")
    parser.add_argument('--dry-run', action='store_true', dest="dry", help="Don't execute anythin")

    args = parser.parse_args(argv)
    logging.basicConfig(level=args.loglevel, format='[%(levelname)s] %(message)s')
    args.actions = set(args.actions)
    args.dist_path = args.dist_path.resolve()
    args.root = args.root.resolve()
    args.dist_path = args.dist_path.resolve()
    if args.dry:
        args.dist_path = args.dist_path / "dry"

    if args.github:
        section_printer = GitHubSectionPrinter()
    else:
        section_printer = SectionPrinter()

    executer = Executer(root=args.root, dry=args.dry)

    releaser = Releaser(commit=args.commit, root=args.root, dist_path=args.dist_path, executer=executer, section_printer=section_printer)

    with section_printer.group("Arguments"):
        print(f"project         = {releaser.project}")
        print(f"version         = {releaser.version}")
        print(f"bare-project    = {releaser.bare_project}")
        print(f"commit          = {args.commit}")
        print(f"out             = {args.dist_path}")
        print(f"actions         = {','.join(args.actions)}")
        print(f"dry             = {args.dry}")

    releaser.prepare()

    if "source" in args.actions:
        with section_printer.group("Create source archives"):
            releaser.create_source_archives()

    if "xcframework" in args.actions:
        if platform.system() != "Darwin" and not args.dry:
            parser.error("xcframework artifact(s) can only be built on Darwin")

        releaser.create_xcframework()

    if "win32" in args.actions:
        if platform.system() != "Windows" and not args.dry:
            parser.error("win32 artifact(s) can only be built on Windows")
        with section_printer.group("Find Visual Studio"):
            vs = VisualStudio(executer=executer)
        with section_printer.group("Build x86 VS binary"):
            x86 = releaser.build_vs(arch="x86", platform="Win32", vs=vs)
        with section_printer.group("Build x64 VS binary"):
            x64 = releaser.build_vs(arch="x64", platform="x64", vs=vs)
        with section_printer.group("Create SDL VC development zip"):
            arch_vc = {
                "x86": x86,
                "x64": x64,
            }
            releaser.build_vs_devel(arch_vc)

    with section_printer.group("Summary"):
        print(f"artifacts = {releaser.artifacts}")

    if args.github:
        if not "GITHUB_OUTPUT" in os.environ:
            logger.warning("GITHUB_OUTPUT environment variable not set! Setting dummy variable.")
            os.environ["GITHUB_OUTPUT"] = str(args.dist_path / "github_output.txt")
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"project={releaser.project}\n")
            f.write(f"version={releaser.version}\n")
            f.write(f"bare-project={releaser.bare_project}\n")
            for k, v in releaser.artifacts.items():
                f.write(f"{k}={v.name}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

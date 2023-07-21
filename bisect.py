#!/usr/bin/env python

import re
import subprocess
import sys

COMMIT_INVALID_RESULT = 125
COMMIT_BAD_RESULT = 1
COMMIT_GOOD_RESULT = 0

print("arguments", sys.argv)


def build_sdl():
    print("Running 'cmake -S . -B build -GNinja' -DSDL_TEST=ON -DSDL_TESTS=ON -DSDL_SHARED=ON -DSDL_STATIC=OFF")
    build_result = subprocess.run(["cmake", "-S", ".", "-B", "build", "-GNinja", "-DSDL_TEST=ON", "-DSDL_TESTS=ON", "-DSDL_SHARED=ON", "-DSDL_STATIC=OFF", "-DCMAKE_BUILD_TYPE=Release"], capture_output=True,text=True)
    if build_result.returncode != 0:
        print("Configure failed => skipping commit")
        return COMMIT_INVALID_RESULT
    print("Running 'cmake --build build'")
    build_result = subprocess.run(["cmake", "--build", "build"], capture_output=True,text=True)
    if build_result.returncode != 0:
        print("Build failed => skipping commit")
        return COMMIT_INVALID_RESULT
    return COMMIT_GOOD_RESULT


def test_sdl():
    print("Running 'ctest --test-dir build -E testsem'")
    for i in range(20):
        print("test", i)
        test_result = subprocess.run(["ctest", "--test-dir", "build", "-E", "testsem", "-E", "testatomic"], capture_output=True, text=True)
        timeouts = re.findall("([a-zA-Z0-9_]+)[ \t.*]+Timeout", txt ,flags=re.I)
        if timeouts:
            print("fimeouts=", timeouts, "(only testlocale and testfilesystem matter)")
        if any(e in timeouts for e in ("testlocale", "testfilesystem"):
            print("BAD COMMIT! TIMEOUT detected in", timeouts)
            return COMMIT_BAD_RESULT
        if test_result.returncode != 0:
            print("test failed for some reason")
            return COMMIT_INVALID_RESULT

    print("all tests good")
    return COMMIT_GOOD_RESULT


ORIGINAL_TXT = None


def patch_sdl():
    global ORIGINAL_TXT

    print("patching...")
    with open("test/CMakeLists.txt", "r") as f:
        ORIGINAL_TXT = f.read()
    new_txt, count = re.subn(" 10", " 4", ORIGINAL_TXT)
    with open("test/CMakeLists.txt", "w") as f:
        f.write(new_txt)
    if count == 0:
        print("patch failed")
        return COMMIT_INVALID_RESULT
    return COMMIT_GOOD_RESULT


def revert_patch_sdl():
    global ORIGINAL_TXT

    print("reverting patch...")

    if ORIGINAL_TXT:
        with open("test/CMakeLists.txt", "w") as f:
            f.write(ORIGINAL_TXT)
    return COMMIT_GOOD_RESULT


def do_sdl_build_test():
    r = build_sdl()
    if r != COMMIT_GOOD_RESULT:
        return r
    r = test_sdl()
    if r != COMMIT_GOOD_RESULT:
        return r
    return COMMIT_GOOD_RESULT


def main():
    r = patch_sdl()
    if r != COMMIT_GOOD_RESULT:
        return r

    result = do_sdl_build_test()

    revert_patch_sdl()

    return result


if __name__ == "__main__":
    raise SystemExit(main())

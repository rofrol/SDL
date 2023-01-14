/*
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/

/* Simple program: download bmp from internet and show it in a window */

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include <SDL3/SDL_test.h>

#include "curl_rwops.h"

/*
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/

/* Print out all the scancodes we have, just to verify them */

#include <stdlib.h>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

static const char *BMP_URL1 = "https://filesamples.com/samples/image/bmp/sample_640%C3%97426.bmp";
static const char *WAV_URL1 = "https://file-examples.com/storage/fea8fc38fd63bc5c39cf20b/2017/11/file_example_WAV_1MG.wav";

static void dl_LoadFile_RW_non_preloaded() {
    SDL_RWops * rwops;
    size_t size;
    void * buffer;

    rwops = rwops_curl_dl_CreateRW(BMP_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", BMP_URL1);

    buffer = SDL_LoadFile_RW(rwops, &size, 1);
    SDLTest_AssertCheck(buffer != NULL, "Validate SDL_LoadFile_RW( ) does not return NULL");
}
static const SDLTest_TestCaseReference dlopsTest1 = {
        (SDLTest_TestCaseFp)dl_LoadFile_RW_non_preloaded, "dl_LoadFile_RW_non_preloaded",
            "Load non pre-downloaded file using SDL_LoadFile_RW", TEST_ENABLED
};

static void dl_LoadFile_RW_preloaded() {
    SDL_RWops * rwops;
    size_t size;
    void * buffer;

    rwops = rwops_curl_dl_CreateRW(BMP_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", BMP_URL1);

    while (rwops_curl_perform()) {
        SDL_Delay(10);
    }

    buffer = SDL_LoadFile_RW(rwops, &size, 1);
    SDLTest_AssertCheck(buffer != NULL, "Validate SDL_LoadFile_RW( ) does not return NULL");
}
static const SDLTest_TestCaseReference dlopsTest2 = {
        (SDLTest_TestCaseFp)dl_LoadFile_RW_preloaded, "dl_LoadFile_RW_preloaded",
        "Load pre-downloaded file using SDL_LoadFile_RW", TEST_ENABLED
};

static void dl_LoadBMP_RW_non_preloaded() {
    SDL_RWops * rwops;
    SDL_Surface * surface;

    rwops = rwops_curl_dl_CreateRW(BMP_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", BMP_URL1);

    surface = SDL_LoadBMP_RW(rwops, 1);
    SDLTest_AssertCheck(surface != NULL, "Validate SDL_LoadBMP_RW( ) does not return NULL");

    SDL_DestroySurface(surface);
}
static const SDLTest_TestCaseReference dlopsTest3 = {
        (SDLTest_TestCaseFp)dl_LoadBMP_RW_non_preloaded, "dl_LoadBMP_RW_non_preloaded",
            "Load non pre-downloaded file using SDL_LoadBMP_RW", TEST_ENABLED
};

static void dl_LoadBMP_RW_preloaded() {
    SDL_RWops * rwops;
    SDL_Surface * surface;

    rwops = rwops_curl_dl_CreateRW(BMP_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", BMP_URL1);

    while (rwops_curl_perform()) {
        SDL_Delay(10);
    }

    surface = SDL_LoadBMP_RW(rwops, 1);
    SDLTest_AssertCheck(surface != NULL, "Validate SDL_LoadBMP_RW( ) does not return NULL");

    SDL_DestroySurface(surface);
}
static const SDLTest_TestCaseReference dlopsTest4 = {
        (SDLTest_TestCaseFp)dl_LoadBMP_RW_preloaded, "dl_LoadBMP_RW_preloaded",
        "Load pre-downloaded file using SDL_LoadBMP_RW", TEST_ENABLED
};

static void dl_LoadWAV_RW_non_preloaded() {
    SDL_RWops * rwops;
    SDL_AudioSpec audio_spec;
    SDL_AudioSpec * spec_res;
    Uint8 * audio_buf;
    Uint32 audio_len;

    rwops = rwops_curl_dl_CreateRW(WAV_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", WAV_URL1);

    spec_res = SDL_LoadWAV_RW(rwops, 1, &audio_spec, &audio_buf, &audio_len);
    SDLTest_AssertCheck(spec_res != NULL, "Validate SDL_LoadWAV_RW( ) does not return NULL");

    SDL_free(audio_buf);
}
static const SDLTest_TestCaseReference dlopsTest5 = {
        (SDLTest_TestCaseFp)dl_LoadWAV_RW_non_preloaded, "dl_LoadWAV_RW_non_preloaded",
            "Load non pre-downloaded file using SDL_LoadWAV_RW", TEST_ENABLED
};

static void dl_LoadWAV_RW_preloaded() {
    SDL_RWops * rwops;
    SDL_AudioSpec audio_spec;
    SDL_AudioSpec * spec_res;
    Uint8 * audio_buf;
    Uint32 audio_len;

    rwops = rwops_curl_dl_CreateRW(WAV_URL1);
    SDLTest_AssertCheck(rwops != NULL, "Validate rwops_curl_dl_CreateRW(\"%s\") does not return NULL", WAV_URL1);

    while (rwops_curl_perform()) {
        SDL_Delay(10);
    }

    spec_res = SDL_LoadWAV_RW(rwops, 1, &audio_spec, &audio_buf, &audio_len);
    SDLTest_AssertCheck(spec_res != NULL, "Validate SDL_LoadWAV_RW( ) does not return NULL");

    SDL_free(audio_buf);
}
static const SDLTest_TestCaseReference dlopsTest6 = {
        (SDLTest_TestCaseFp)dl_LoadWAV_RW_preloaded, "dl_LoadWAV_RW_preloaded",
        "Load pre-downloaded file using SDL_LoadWAV_RW", TEST_ENABLED
};

static void DLRWopsSetUp(void *args) {;
}

static void DLRWopsTearDown(void *args) {;
}

static const SDLTest_TestCaseReference *dlopsTests[] = {
    &dlopsTest1, &dlopsTest2, &dlopsTest3, &dlopsTest4, &dlopsTest5, &dlopsTest6, NULL
};

SDLTest_TestSuiteReference dlrwopsTestSuite = {
    "DL_RWops", DLRWopsSetUp, dlopsTests, DLRWopsTearDown,
};

static SDLTest_TestSuiteReference *allTestSuites[] = {
    &dlrwopsTestSuite,
    NULL
};

static SDLTest_CommonState *state;

/* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
static void
quit(int rc)
{
    SDLTest_CommonQuit(state);
    exit(rc);
}

int main(int argc, char *argv[])
{
    int result;
    int testIterations = 1;
    Uint64 userExecKey = 0;
    char *userRunSeed = NULL;
    char *filter = NULL;
    int i, done;
    SDL_Event event;

    /* Initialize test framework */
    state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
    if (state == NULL) {
        return 1;
    }

    /* Parse commandline */
    for (i = 1; i < argc;) {
        int consumed;

        consumed = SDLTest_CommonArg(state, i);
        if (consumed == 0) {
            consumed = -1;
            if (SDL_strcasecmp(argv[i], "--iterations") == 0) {
                if (argv[i + 1]) {
                    testIterations = SDL_atoi(argv[i + 1]);
                    if (testIterations < 1) {
                        testIterations = 1;
                    }
                    consumed = 2;
                }
            } else if (SDL_strcasecmp(argv[i], "--execKey") == 0) {
                if (argv[i + 1]) {
                    (void)SDL_sscanf(argv[i + 1], "%" SDL_PRIu64, &userExecKey);
                    consumed = 2;
                }
            } else if (SDL_strcasecmp(argv[i], "--seed") == 0) {
                if (argv[i + 1]) {
                    userRunSeed = SDL_strdup(argv[i + 1]);
                    consumed = 2;
                }
            } else if (SDL_strcasecmp(argv[i], "--filter") == 0) {
                if (argv[i + 1]) {
                    filter = SDL_strdup(argv[i + 1]);
                    consumed = 2;
                }
            }
        }
        if (consumed < 0) {
            static const char *options[] = { "[--iterations #]", "[--execKey #]", "[--seed string]", "[--filter suite_name|test_name]", NULL };
            SDLTest_CommonLogUsage(state, argv[0], options);
            quit(1);
        }

        i += consumed;
    }

    /* Initialize common state */
    if (!SDLTest_CommonInit(state)) {
        quit(2);
    }

    /* Call Harness */
    result = SDLTest_RunSuites(allTestSuites, NULL, 0, NULL, 0);

    /* Empty event queue */
    done = 0;
    for (i = 0; i < 100; i++) {
        while (SDL_PollEvent(&event)) {
            SDLTest_CommonEvent(state, &event, &done);
        }
        SDL_Delay(10);
    }

    /* Clean up */
    SDL_free(userRunSeed);
    SDL_free(filter);

    /* Shutdown everything */
    quit(result);
    return result;
}

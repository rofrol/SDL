/*
  Copyright (C) 1997-2024 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3/SDL_test.h>

static int a_global_var = 77;
static SDL_bool qsort_is_broken = SDL_FALSE;

static int SDLCALL
num_compare(const void *_a, const void *_b)
{
    const int a = *((const int *)_a);
    const int b = *((const int *)_b);
    return (a < b) ? -1 : ((a > b) ? 1 : 0);
}

static int SDLCALL
num_compare_r(void *userdata, const void *a, const void *b)
{
    if (userdata != &a_global_var) {
        SDL_Log("Uhoh, num_compare_r got invalid userdata during SDL_qsort_r!");
        qsort_is_broken = SDL_TRUE;
    }
    return num_compare(a, b);
}

static int SDLCALL
num_compare_non_transitive_r(void *userdata, const void *_a, const void *_b)
{
    if (userdata != &a_global_var) {
        SDL_Log("Uhoh, num_compare_non_transitive_r got invalid userdata during SDL_qsort_r!");
        qsort_is_broken = SDL_TRUE;
    }
    const int a = *((const int *)_a);
    const int b = *((const int *)_b);
    return a < b;
}

static void
test_sort(const char *desc, int *nums, const int arraylen)
{
    int *nums_copy = SDL_malloc(arraylen * sizeof(int));
    int i;
    int prev;

    SDL_Log("test: %s arraylen=%d", desc, arraylen);

    SDL_memcpy(nums_copy, nums, arraylen * sizeof (*nums));
    SDL_qsort_r(nums_copy, arraylen, sizeof(nums[0]), num_compare_non_transitive_r, &a_global_var);
    prev = nums[0];
    for (i = 1; i < arraylen; i++) {
        const int val = nums_copy[i];
        if (val < prev) {
            SDL_Log("sorting using a non-transitive compare function is broken!");
            qsort_is_broken = SDL_TRUE;
            goto free_resources;
        }
        prev = val;
    }

    SDL_memcpy(nums_copy, nums, arraylen * sizeof (*nums));
    SDL_qsort_r(nums_copy, arraylen, sizeof(nums[0]), num_compare_r, &a_global_var);

    SDL_qsort(nums, arraylen, sizeof(nums[0]), num_compare);

    prev = nums[0];
    for (i = 1; i < arraylen; i++) {
        const int val = nums[i];
        const int val2 = nums_copy[i];
        if (val < prev || val != val2) {
            SDL_Log("sort is broken!");
            qsort_is_broken = SDL_TRUE;
            goto free_resources;
        }
        prev = val;
    }
free_resources:
    SDL_free(nums_copy);
}

int main(int argc, char *argv[])
{
    static const int itervals[] = { 0, 1, 12, 100, 100 * 1024 };
    int i;
    int iteration;
    SDLTest_RandomContext rndctx;
    SDLTest_CommonState *state;
    int seed_seen = 0;

    SDL_zero(rndctx);

    /* Initialize test framework */
    state = SDLTest_CommonCreateState(argv, 0);
    if (!state) {
        return 1;
    }

    /* Parse commandline */
    for (i = 1; i < argc;) {
        int consumed;

        consumed = SDLTest_CommonArg(state, i);
        if (!consumed) {
            if (!seed_seen) {
                Uint64 seed = 0;
                char *endptr = NULL;

                seed = SDL_strtoull(argv[i], &endptr, 0);
                if (endptr != argv[i] && *endptr == '\0') {
                    seed_seen = 1;
                    consumed = 1;
                } else {
                    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Invalid seed. Use a decimal or hexadecimal number.\n");
                    return 1;
                }
                if (seed <= ((Uint64)0xffffffff)) {
                    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Seed must be equal or greater than 0x100000000.\n");
                    return 1;
                }
                SDLTest_RandomInit(&rndctx, (unsigned int)(seed >> 32), (unsigned int)(seed & 0xffffffff));
            }
        }
        if (consumed <= 0) {
            static const char *options[] = { "[seed]", NULL };
            SDLTest_CommonLogUsage(state, argv[0], options);
            return 1;
        }

        i += consumed;
    }

    if (!seed_seen) {
        SDLTest_RandomInitTime(&rndctx);
    }
    SDL_Log("Using random seed 0x%08x%08x\n", rndctx.x, rndctx.c);

    for (iteration = 0; iteration < SDL_arraysize(itervals); iteration++) {
        const int arraylen = itervals[iteration];
        int *nums = SDL_malloc(sizeof(int) * arraylen);

        for (i = 0; i < arraylen; i++) {
            nums[i] = i;
        }
        test_sort("already sorted", nums, arraylen);

        for (i = 0; i < arraylen; i++) {
            nums[i] = i;
        }
        nums[arraylen - 1] = -1;
        test_sort("already sorted except last element", nums, arraylen);

        for (i = 0; i < arraylen; i++) {
            nums[i] = (arraylen - 1) - i;
        }
        test_sort("reverse sorted", nums, arraylen);

        for (i = 0; i < arraylen; i++) {
            nums[i] = SDLTest_RandomInt(&rndctx);
        }
        test_sort("random sorted", nums, arraylen);
        SDL_free(nums);
    }

    SDLTest_CommonDestroyState(state);
    SDL_Quit();

    return qsort_is_broken;
}

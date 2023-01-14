/*
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/

/* RWops using libcurl for downloading resources */

#include "curl_rwops.h"

#include <SDL3/SDL.h>

#include <curl/curl.h>

struct download_state {
    Uint8 *buffer;
    Uint64 buffer_size_thus_far;
    Uint64 read_pos;
    int finished;
    CURL *curl;
    struct download_state *next;
    struct download_state **ptr_prev_next;
};

struct download_global_state {
    int initialized;
    CURLM *curl_multi;
    struct download_state *childs;
};

static struct download_global_state dl_global;

static void dl_global_init(void) {
    if (dl_global.initialized) {
        return;
    }
    if (curl_global_init_mem(CURL_GLOBAL_DEFAULT, SDL_malloc, SDL_free, SDL_realloc, SDL_strdup, SDL_calloc)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "curl_global_init failed");
        return;
    }
    dl_global.curl_multi = curl_multi_init();
    if (!dl_global.curl_multi) {
        return;
    }
    dl_global.childs = NULL;
    dl_global.initialized = 1;
}

#if 0
static void dl_global_destroy(void) {
    for (struct download_state *child = dl_global.childs; child; child = child->next) {
        curl_multi_remove_handle(dl_global.curl_multi, child->curl);
        curl_easy_cleanup(child->curl);
        child->curl = NULL;
    }
    if (curl_multi_cleanup(dl_global.curl_multi) != CURLM_OK) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "curl_multi_cleanup failed");
    }
    curl_global_cleanup();
    dl_global.initialized = 0;
}
#endif

static size_t dl_curl_callback_write(char *ptr, size_t size, size_t nmemb, void *userdata) {
    struct download_state *state = userdata;

    state->buffer = SDL_realloc(state->buffer, state->buffer_size_thus_far + size * nmemb);
    SDL_memcpy(&state->buffer[state->buffer_size_thus_far], ptr, size * nmemb);
    state->buffer_size_thus_far += size * nmemb;

    return size * nmemb;
}

struct download_state *dl_create(const char *url) {
    struct download_state *state;

    dl_global_init();

    state = SDL_malloc(sizeof(struct download_state));
    if (!state) {
        return NULL;
    }
    state->curl = curl_easy_init();
    if (!state->curl) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "curl_easy_init(%s) failed", url);
        SDL_free(state);
        return NULL;
    }
    curl_easy_setopt(state->curl, CURLOPT_URL, url);
    curl_easy_setopt(state->curl, CURLOPT_PRIVATE, state);
    curl_easy_setopt(state->curl, CURLOPT_WRITEFUNCTION, dl_curl_callback_write);
    curl_easy_setopt(state->curl, CURLOPT_WRITEDATA, state);
//    curl_easy_setopt(state->curl, CURLOPT_NOPROGRESS, 0);
    curl_multi_add_handle(dl_global.curl_multi, state->curl);

    state->buffer = NULL;
    state->buffer_size_thus_far = 0;
    state->read_pos = 0;
    state->finished = 0;

    if (dl_global.childs) {
        dl_global.childs->ptr_prev_next = &state->next;
    }
    state->next = dl_global.childs;
    state->ptr_prev_next = &dl_global.childs;
    dl_global.childs = state;

    return state;
}

static void dl_destroy(struct download_state *state) {
    if (state->curl) {
        curl_multi_remove_handle(dl_global.curl_multi, state->curl);
        curl_easy_cleanup(state->curl);
    }
    if (state->next) {
        state->next->ptr_prev_next = state->ptr_prev_next;
    }
    if (state->ptr_prev_next) {
        *state->ptr_prev_next = state->next;
    }
    SDL_free(state->buffer);
    SDL_free(state);
}

static void dl_finished(struct download_state *state) {
    state->finished = 1;
    SDL_assert(state->curl);
    curl_multi_remove_handle(dl_global.curl_multi, state->curl);
    curl_easy_cleanup(state->curl);
    state->curl = NULL;
    if (state->next) {
        state->next->ptr_prev_next = state->ptr_prev_next;
    }
    *state->ptr_prev_next = state->next;
    state->next = NULL;
    state->ptr_prev_next = NULL;
}

static Sint64 dl_rwops_size(struct SDL_RWops * context) {
    struct download_state * state = context->hidden.unknown.data1;

    if (!state->finished) {
        rwops_curl_perform();
    }
    if (state->finished) {
        return state->buffer_size_thus_far;
    } else {
        return -2;
    }
}

static Sint64 dl_rwops_seek(struct SDL_RWops * context, Sint64 offset, int whence) {
    struct download_state * state = context->hidden.unknown.data1;
    Sint64 new_pos;

    switch (whence) {
        case SDL_RW_SEEK_SET:
            new_pos = offset;
            break;
        case SDL_RW_SEEK_CUR:
            new_pos = state->read_pos + offset;
            break;
        case SDL_RW_SEEK_END:
            if (!state->finished) {
                return -2;
            }
            new_pos = state->buffer_size_thus_far + offset;
            break;
        default:
            return -1;
    }
    if (new_pos < 0) {
        return -1;
    }
    if ((Uint64)new_pos >= state->buffer_size_thus_far) {
        if (state->finished) {
            new_pos = state->buffer_size_thus_far;
        } else {
            rwops_curl_perform();
        }
    }
    if ((Uint64)new_pos >= state->buffer_size_thus_far) {
        if (state->finished) {
            new_pos = state->buffer_size_thus_far;
        } else {
            return -2;
        }
    }
    state->read_pos = new_pos;
    return state->read_pos;
}

static Sint64 dl_rwops_read(struct SDL_RWops * context, void *ptr, Sint64 size) {
    struct download_state * state = context->hidden.unknown.data1;
    Sint64 amount_to_read;

    amount_to_read = SDL_min((Uint64)size, state->buffer_size_thus_far - state->read_pos);
    if (amount_to_read == 0 && !state->finished) {
        rwops_curl_perform();
    }
    amount_to_read = SDL_min((Uint64)size, state->buffer_size_thus_far - state->read_pos);
    if (amount_to_read == 0 && !state->finished) {
        return -2;
    }
    SDL_memcpy(ptr, &state->buffer[state->read_pos], amount_to_read);
    state->read_pos += amount_to_read;
    return amount_to_read;
}

static Sint64 dl_rwops_write(struct SDL_RWops * context, const void *ptr, Sint64 size) {
    return -1;
}

static int dl_rwops_close(struct SDL_RWops * context) {
    struct download_state * state = context->hidden.unknown.data1;

    dl_destroy(state);
    SDL_DestroyRW(context);

    return 0;
}

SDL_RWops *rwops_curl_dl_CreateRW(const char *url) {
    SDL_RWops *rwops;
    struct download_state *dl_state;

    dl_state = dl_create(url);
    if (!dl_state) {
        return NULL;
    }

    rwops = SDL_CreateRW();
    if (!rwops) {
        dl_destroy(dl_state);
        return NULL;
    }
    rwops->size = dl_rwops_size;
    rwops->seek = dl_rwops_seek;
    rwops->read = dl_rwops_read;
    rwops->write = dl_rwops_write;
    rwops->close = dl_rwops_close;
    rwops->hidden.unknown.data1 = dl_state;

    return rwops;
}

int rwops_curl_perform(void) {
    CURLMsg *msg;
    int count;

    while ((msg = curl_multi_info_read(dl_global.curl_multi, &count)) != NULL) {
        struct download_state *state;
        switch (msg->msg) {
            case CURLMSG_DONE:
                curl_easy_getinfo(msg->easy_handle, CURLINFO_PRIVATE, &state);
                dl_finished(state);
                break;
            default:
                break;
        }
    }
    curl_multi_perform(dl_global.curl_multi, &count);

    return count != 0;
}

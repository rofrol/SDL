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

#include <SDL3/SDL_rwops.h>

SDL_RWops *rwops_curl_dl_CreateRW(const char *url);

int rwops_curl_perform(void);

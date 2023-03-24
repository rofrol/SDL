/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#ifndef SDL_test_internal_h_
#define SDL_test_internal_h_

#define COLOR_RED_YES       "\033[0;31m"
#define COLOR_GREEN_YES     "\033[0;32m"
#define COLOR_YELLOW_YES    "\033[0;93m"
#define COLOR_BLUE_YES      "\033[0;94m"
#define COLOR_END_YES       "\033[0m"

#define COLOR_RED_NO        ""
#define COLOR_GREEN_NO      ""
#define COLOR_BLUE_NO       ""
#define COLOR_YELLOW_NO     ""
#define COLOR_END_NO        ""

#define COLOR_RED(X)        COLOR_GREEN_##X
#define COLOR_GREEN(X)      COLOR_GREEN_##X
#define COLOR_YELLOW(X)     COLOR_YELLOW_##X
#define COLOR_BLUE(X)       COLOR_BLUE_##X
#define COLOR_END(X)        COLOR_END_##X

#define COLORIZE_MESSAGE(NAME, X)       \
    static const char *NAME[2] = {      \
       X(NO),                           \
       X(YES),                          \
    }

#define PASSED_GREEN_C(X) COLOR_GREEN(X) "Passed" COLOR_END(X)
COLORIZE_MESSAGE(PASSED_GREEN, PASSED_GREEN_C);

#define PASSED_RED_C(X) COLOR_RED(X) "Passed" COLOR_END(X)
COLORIZE_MESSAGE(PASSED_RED, PASSED_RED_C);

#define FAILED_RED_C(X) COLOR_RED(X) "Failed" COLOR_END(X)
COLORIZE_MESSAGE(FAILED_RED, FAILED_RED_C);

#define NOASSERTS_BLUE_C(X) COLOR_BLUE(X) "No Asserts" COLOR_END(X)
COLORIZE_MESSAGE(NOASSERTS_BLUE, NOASSERTS_BLUE_C);

#endif /* SDL_test_internal_h_ */

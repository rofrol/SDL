/*
  Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely.
*/

#include "testnative.h"

#ifdef TEST_NATIVE_WINDOWS

#include "testnativew32.h"

#include <windows.h>

static HACCEL gHAccelTable;

static void *CreateWindowNative(int w, int h);
static void LoopWindowNative(void *window, int *done);
static void DestroyWindowNative(void *window);

NativeWindowFactory WindowsWindowFactory = {
    "windows",
    CreateWindowNative,
    LoopWindowNative,
    DestroyWindowNative
};

static INT_PTR CALLBACK AboutDlgProc(HWND hdlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);

    switch (msg) {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            EndDialog(hdlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
    case WM_COMMAND: {
        int wmId = LOWORD(wParam);
        switch (wmId) {
        case IDM_ABOUT:
            DialogBox(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_ABOUTBOX), hwnd, AboutDlgProc);
            break;
        case IDM_EXIT: {
            SDL_Event event;
            event.type = SDL_EVENT_QUIT;
            SDL_PushEvent(&event);
            break;
        }
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
        }
        break;
    }
    default:
        return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

static void *CreateWindowNative(int w, int h)
{
    HWND hwnd;
    WNDCLASSEX wc;

    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = GetModuleHandle(NULL);
    wc.hIcon = LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(IDI_ICON));
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = MAKEINTRESOURCE(IDC_TESTNATIVE);;
    wc.lpszClassName = "SDL Test";
    wc.hIconSm = LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(IDI_ICON));

    if (!RegisterClassEx(&wc)) {
        MessageBox(NULL, "Window Registration Failed!", "Error!",
                   MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    gHAccelTable = LoadAccelerators(GetModuleHandle(NULL), MAKEINTRESOURCE(IDC_TESTNATIVE));

    hwnd = CreateWindow("SDL Test", NULL, WS_VISIBLE | WS_OVERLAPPEDWINDOW | WS_THICKFRAME | WS_SIZEBOX,
                     CW_USEDEFAULT, CW_USEDEFAULT, w, h, NULL, NULL, GetModuleHandle(NULL), NULL);
    if (!hwnd) {
        MessageBox(NULL, "Window Creation Failed!", "Error!",
                   MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    ShowWindow(hwnd, SW_SHOW);

    return hwnd;
}

static void
LoopWindowNative(void *window, int *done)
{
    MSG msg;
    while (!*done && GetMessage(&msg, (HWND)window, 0, 0)) {
        if (!TranslateAccelerator(msg.hwnd, gHAccelTable, &msg)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
}

static void
DestroyWindowNative(void *window)
{
    DestroyWindow((HWND)window);
    DestroyAcceleratorTable(gHAccelTable);
}

#endif

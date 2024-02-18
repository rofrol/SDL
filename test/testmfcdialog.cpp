#include "testmfcdialog.h"

#include <SDL3/SDL.h>

#include <afxwin.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

#define IDT_10MS 1000

#define USE_DIALOG_WINDOW  1    // Create SDL_Window from CDialog HWND handle
#define USE_STATIC_CONTROL 2    // Create SDL_Window from CStatic HWND handle

#define USE_WHAT_WND USE_STATIC_CONTROL

class CSDLDialog : public CDialog {
public:
    CSDLDialog(CWnd *pParent = NULL): CDialog(IDD_DIALOG, pParent), m_window(NULL) {
    }
protected:
    BOOL OnInitDialog() {
        BOOL res = CDialog::OnInitDialog();
        if (!res) {
            SDL_Log("CDialog::OnInitDialog() failed");
            return FALSE;
        }
        ::SetTimer(m_hWnd, IDT_10MS, 10, (TIMERPROC) NULL);

        CWnd *ctrl = GetDlgItem(IDC_CONTROL);
        SDL_PropertiesID props = SDL_CreateProperties();
#if USE_WHAT_WND == USE_DIALOG_WINDOW
        SDL_SetProperty(props, SDL_PROP_WINDOW_CREATE_WIN32_HWND_POINTER, m_hWnd);
#elif USE_WHAT_WND == USE_STATIC_CONTROL
        SDL_SetProperty(props, SDL_PROP_WINDOW_CREATE_WIN32_HWND_POINTER, ctrl->m_hWnd);
#else
        SDL_SetProperty(props, SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, AfxGetInstanceHandle);
#error "Invalid USE_WHAT_WND"
#endif
        m_window = SDL_CreateWindowWithProperties(props);
        SDL_DestroyProperties(props);
        m_renderer = SDL_CreateRenderer(m_window, NULL, 0);
        return TRUE;
    }
    afx_msg void OnClose() {
        SDL_DestroyRenderer(m_renderer);
        SDL_DestroyWindow(m_window);
        ::KillTimer(m_hWnd, IDT_10MS);
    }
    afx_msg void OnTimer(UINT_PTR timer) {
        if ((int)timer == IDT_10MS) {
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
            }
            SDL_SetRenderDrawColor(m_renderer, 80, 80, 80, SDL_ALPHA_OPAQUE);
            SDL_RenderClear(m_renderer);
        }
    }
    DECLARE_MESSAGE_MAP()
private:
    SDL_Window *m_window;
    SDL_Renderer *m_renderer;
};

BEGIN_MESSAGE_MAP(CSDLDialog, CDialog)
ON_WM_CLOSE()
ON_WM_TIMER()
END_MESSAGE_MAP()

class CTestApp : public CWinApp {
public:
    CTestApp() {
        SetAppID(_T("org.libsdl.sdl.testmfcdialog"));
    }
    BOOL InitInstance() {
        if (!CWinApp::InitInstance()) {
            return FALSE;
        }

        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            SDL_Log("SDL_Init(SDL_INIT_VIDEO) failed");
            return FALSE;
        }

        CCommandLineInfo cmdInfo;
        ParseCommandLine(cmdInfo);

        CSDLDialog dialog;
        m_pMainWnd = &dialog;
        dialog.DoModal();

        return FALSE;
    }
    int ExitInstance() {
        SDL_Quit();
        return CWinApp::ExitInstance();
    }
};

CTestApp theApp;

#include "testmfcmdi.h"

#include <SDL3/SDL.h>

#include <afxwin.h>         // MFC core and standard components
//#include <afxext.h>         // MFC extensions
#include <afxcontrolbars.h>     // MFC support for ribbons and control bars

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

class CChildFrame : public CMDIChildWndEx
{
protected:
    DECLARE_DYNCREATE(CChildFrame)
public:
    CChildFrame() : m_window(NULL) {}

    virtual BOOL OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) {

        SDL_PropertiesID props = SDL_CreateProperties();

        SDL_SetProperty(props, SDL_PROP_WINDOW_WIN32_HWND_POINTER, m_hWnd);
        SDL_SetProperty(props, SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, AfxGetInstanceHandle);

        m_window = SDL_CreateWindowWithProperties(props);

        SDL_DestroyProperties(props);
        return TRUE;
    }
    virtual BOOL PreCreateWindow(CREATESTRUCT& cs) {
        if (!CMDIChildWndEx::PreCreateWindow(cs)) {
            return FALSE;
        }
        cs.style = WS_CHILD | WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU
                   | FWS_ADDTOTITLE | WS_THICKFRAME;

        return TRUE;
    }
  protected:
    SDL_Window* m_window;
};
IMPLEMENT_DYNCREATE(CChildFrame, CMDIChildWndEx)

class CMainFrame : public CMDIFrameWndEx
{
protected:
    DECLARE_DYNAMIC(CMainFrame)
    CToolBar          m_wndToolBar;
    CStatusBar        m_wndStatusBar;
    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CMDIFrameWndEx::OnCreate(lpCreateStruct) == -1) {
            return -1;
        }
        CMDITabInfo mdiTabParams;
        mdiTabParams.m_style = CMFCTabCtrl::STYLE_3D_ONENOTE; // other styles available...
        mdiTabParams.m_bActiveTabCloseButton = TRUE;      // set to FALSE to place close button at right of tab area
        mdiTabParams.m_bTabIcons = FALSE;    // set to TRUE to enable document icons on MDI taba
        mdiTabParams.m_bAutoColor = TRUE;    // set to FALSE to disable auto-coloring of MDI tabs
        mdiTabParams.m_bDocumentMenu = TRUE; // enable the document menu at the right edge of the tab area
        EnableMDITabbedGroups(TRUE, mdiTabParams);

        if (!m_wndStatusBar.Create(this)) {
            TRACE0("Failed to create status bar\n");
            return -1;
        }

        // Switch the order of document name and application name on the window title bar. This
        // improves the usability of the taskbar because the document name is visible with the thumbnail.
        ModifyStyle(0, FWS_PREFIXTITLE);

        return 0;
    }
    DECLARE_MESSAGE_MAP()
};
IMPLEMENT_DYNAMIC(CMainFrame, CMDIFrameWndEx)
BEGIN_MESSAGE_MAP(CMainFrame, CMDIFrameWndEx)
ON_WM_CREATE()
END_MESSAGE_MAP()

class CMFCApplication1Doc : public CDocument
{
  protected:
    DECLARE_DYNCREATE(CMFCApplication1Doc)
};
IMPLEMENT_DYNCREATE(CMFCApplication1Doc, CDocument)

class CMFCApplication1View : public CView
{
  protected:
    DECLARE_DYNCREATE(CMFCApplication1View)
    CMFCApplication1View() noexcept {}
    virtual ~CMFCApplication1View() {}

  public:
    CMFCApplication1Doc* GetDocument() const { return reinterpret_cast<CMFCApplication1Doc*>(m_pDocument); }
    virtual void OnDraw(CDC* pDC) {}
  protected:
    DECLARE_MESSAGE_MAP()
};
IMPLEMENT_DYNCREATE(CMFCApplication1View, CView)
BEGIN_MESSAGE_MAP(CMFCApplication1View, CView)
END_MESSAGE_MAP()


class CMFCApplication1App : public CWinAppEx
{
  public:
    CMFCApplication1App() {
        SetAppID(_T("MFCApplication1.AppID.NoVersion"));
    }


    // Overrides
  public:
    virtual BOOL InitInstance() {
        CWinAppEx::InitInstance();

        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            SDL_Log("SDL_Init(SDL_INIT_VIDEO) failed (%s)", SDL_GetError());
            return FALSE;
        }

        // Standard initialization
        // If you are not using these features and wish to reduce the size
        // of your final executable, you should remove from the following
        // the specific initialization routines you do not need
        // Change the registry key under which our settings are stored
        SetRegistryKey(_T("testmfcmdi"));
        LoadStdProfileSettings(4);  // Load standard INI file options (including MRU)

        // Register the application's document templates.  Document templates
        //  serve as the connection between documents, frame windows and views
        CMultiDocTemplate* pDocTemplate;
        pDocTemplate = new CMultiDocTemplate(IDR_MFCApplication1TYPE,
                                             RUNTIME_CLASS(CMFCApplication1Doc),
                                             RUNTIME_CLASS(CChildFrame), // custom MDI child frame
                                             RUNTIME_CLASS(CMFCApplication1View));
        if (!pDocTemplate)
            return FALSE;
        AddDocTemplate(pDocTemplate);

        // create main MDI Frame window
        CMainFrame* pMainFrame = new CMainFrame;
        if (!pMainFrame || !pMainFrame->LoadFrame(IDR_MAINFRAME))
        {
            delete pMainFrame;
            return FALSE;
        }
        m_pMainWnd = pMainFrame;

        // Parse command line for standard shell commands, DDE, file open
        CCommandLineInfo cmdInfo;
        ParseCommandLine(cmdInfo);

        // Dispatch commands specified on the command line.  Will return FALSE if
        // app was launched with /RegServer, /Register, /Unregserver or /Unregister.
        if (!ProcessShellCommand(cmdInfo))
            return FALSE;
        // The main window has been initialized, so show and update it
        pMainFrame->ShowWindow(m_nCmdShow);
        pMainFrame->UpdateWindow();

        return TRUE;
    }
    virtual int ExitInstance() {
        SDL_Quit();
        //TODO: handle additional resources you may have added
        return CWinAppEx::ExitInstance();
    }

    // Implementation
    DECLARE_MESSAGE_MAP()
};
BEGIN_MESSAGE_MAP(CMFCApplication1App, CWinAppEx)
ON_COMMAND(ID_FILE_NEW, &CWinAppEx::OnFileNew)
ON_COMMAND(ID_FILE_OPEN, &CWinAppEx::OnFileOpen)
END_MESSAGE_MAP()

CMFCApplication1App theApp;

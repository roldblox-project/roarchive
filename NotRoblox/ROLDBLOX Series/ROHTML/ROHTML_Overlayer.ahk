#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn VarUnset, Off

; set the script tray icon (use A_ScriptDir to resolve current folder)
TraySetIcon(A_ScriptDir "\RoHTML\icons\RoHTML.ico")

; --- Library ---
#Include RoHTML\Lib\WebViewToo.ahk


; --- Process Priority Constants ---
PROCESS_SET_INFORMATION := 0x0200
HIGH_PRIORITY_CLASS := 0x00000080
ABOVE_NORMAL_PRIORITY_CLASS := 0x00008000

; --- Configuration ---
global roblox_window_title := "ahk_exe RobloxPlayerBeta.exe"
global robloxHwnd := ""
global myGui := ""
global inputForwarderPID := 0
global customCursorPID := 0
global robloxIconPID := 0
global robloxMacrosPID := 0

; --- Main ---
Main()

Main() {
    global roblox_window_title, robloxHwnd

    ; Launch companion scripts
    LaunchCompanionScripts()

    ; --- 1. Pre-create the overlay GUI to make it appear faster later ---
    PreCreateOverlay()

    ; --- 2. Set up Shell Hook to watch for window creation/destruction ---
    static DHW_ShellMessage := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
    OnMessage(DHW_ShellMessage, ShellProc)
    
    ; This hidden GUI must be static so it doesn't get destroyed when Main() finishes.
    ; Its existence is what keeps the script running in the background.
    static hiddenGui := Gui()
    DllCall("user32\RegisterShellHookWindow", "Ptr", hiddenGui.Hwnd)
    SetTimer(() => {}, 60000) ; Do-nothing timer to ensure script persistence.
    
    ; --- 3. Check if Roblox is already running on startup ---
    if (robloxHwnd := WinExist(roblox_window_title)) {
        AttachOverlay(robloxHwnd)
    }
}

LaunchCompanionScripts() {
    global customCursorPID, robloxIconPID, robloxMacrosPID

    ; Launch CustomCursor.ahk
    Run('"' A_AhkPath '" "' A_ScriptDir '\RoHTML\Lib\RoHTML\CustomCursor.ahk"',, "", &customCursorPID)
    if customCursorPID
        SetProcessPriority(customCursorPID, HIGH_PRIORITY_CLASS)

    ; Launch ChangeRobloxIcon.ahk
    Run('"' A_AhkPath '" "' A_ScriptDir '\RoHTML\Lib\RoHTML\ChangeRobloxIcon.ahk"',, "", &robloxIconPID)
    if robloxIconPID
        SetProcessPriority(robloxIconPID, HIGH_PRIORITY_CLASS)

    ; Launch Roblox_Macros.ahk
    Run('"' A_AhkPath '" "' A_ScriptDir '\RoHTML\Lib\RoHTML\Roblox_Macros.ahk"',, "", &robloxMacrosPID)
    if robloxMacrosPID
        SetProcessPriority(robloxMacrosPID, HIGH_PRIORITY_CLASS)
}

ShellProc(wParam, lParam, *) {
    global roblox_window_title, robloxHwnd
    static HSHELL_WINDOWCREATED := 1, HSHELL_WINDOWDESTROYED := 2

    if (wParam = HSHELL_WINDOWCREATED) {
        ; Check if the newly created window is Roblox and we don't already have an overlay attached
        if (WinExist(roblox_window_title . " ahk_id " . lParam) && !robloxHwnd) {
            AttachOverlay(lParam)
        }
    } else if (wParam = HSHELL_WINDOWDESTROYED) {
        ; Check if the window being destroyed is our tracked Roblox window
        if (lParam = robloxHwnd) {
            DetachOverlay()
        }
    }
}

SetProcessPriority(pid, priority := HIGH_PRIORITY_CLASS) {
    if !pid {
        return false
    }
    
    try {
        ; Open process with PROCESS_SET_INFORMATION access
        hProcess := DllCall("OpenProcess", "UInt", PROCESS_SET_INFORMATION, "Int", 0, "UInt", pid, "Ptr")
        if !hProcess {
            return false
        }
        
        ; Set priority class
        result := DllCall("SetPriorityClass", "Ptr", hProcess, "UInt", priority)
        
        ; Close handle
        DllCall("CloseHandle", "Ptr", hProcess)
        
        return result
    } catch {
        return false
    }
}

AttachOverlay(hwnd) {
    global robloxHwnd, myGui
    
    robloxHwnd := hwnd

    ; Set high priority for Roblox process
    robloxPID := WinGetPID("ahk_id " hwnd)
    SetProcessPriority(robloxPID, HIGH_PRIORITY_CLASS)
    
    ; Set high priority for our own process
    SetProcessPriority(DllCall("GetCurrentProcessId"), HIGH_PRIORITY_CLASS)

    ; Navigate to the page now, ensuring a fresh load each time.
    myGui.Navigate("https://ahk.localhost/index.html")
    ; Give Windows a moment to process parenting before launching the forwarder
    LaunchInputForwarder()
    ; Parent the GUI to the Roblox window
    DllCall("SetParent", "Ptr", myGui.Hwnd, "Ptr", robloxHwnd)

    ; Size the overlay to match the parent's client area
    rect := Buffer(16, 0)
    DllCall("GetClientRect", "Ptr", robloxHwnd, "Ptr", rect)
    myGui.Move(0, 0, NumGet(rect, 8, "Int"), NumGet(rect, 12, "Int"))

    myGui.Show("NoActivate")
    SetTimer(UpdateOverlayPosition, 250)  ; Reduced from 100ms to 250ms for better performance
    
    Sleep(5500)
    WinActivate("ahk_id " hwnd)
    Send("^+g")
    Send("{Shift}")


}

DetachOverlay() {
    global robloxHwnd, myGui, inputForwarderPID

    SetTimer(UpdateOverlayPosition, 0)
    myGui.Hide()
    ; Un-parent the GUI so it can be used again
    DllCall("SetParent", "Ptr", myGui.Hwnd, "Ptr", 0) 
    robloxHwnd := ""

    if IsSet(inputForwarderPID) && inputForwarderPID {
        ProcessClose(inputForwarderPID)
        inputForwarderPID := 0
    }
}

PreCreateOverlay() {
    global myGui

    ; --- Create WebView GUI, but keep it hidden and un-parented ---
    try {
        wvSettings := { DllPath: A_ScriptDir "\RoHTML\Lib\Webview2Loader.dll" }
        myGui := WebViewGui("-Caption +ToolWindow +E0x80020", , , wvSettings)
        
        myGui.BackColor := "000000"
        myGui.wv.Settings.IsDefaultContextMenusEnabled := False

        margins := Buffer(16, 0)
        NumPut("Int", -1, margins)
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", myGui.Hwnd, "Ptr", margins)

    } catch as e {
        MsgBox("Failed to create WebView2 GUI.`n`n"
             . "Please ensure you have the WebView2 Runtime installed and that Webview2Loader.dll is in the Lib folder.`n`n"
             . "Error: " e.Message, "ROHTML Error", 48)
        ExitApp
    }

    myGui.wvc.DefaultBackgroundColor := 0x00000000
    myGui.wv.SetVirtualHostNameToFolderMapping("ahk.localhost", A_ScriptDir "\RoHTML", 0)
    ; Listen for WM_COPYDATA messages from InputForwarder
    OnMessage(0x4A, ReceiveInputData)
    OnExit(ExitCleanup)
    
    myGui.OnEvent("Close", (*) => ExitApp())
}

UpdateOverlayPosition() {
    global robloxHwnd, myGui
    static lastW := -1, lastH := -1

    if !WinExist("ahk_id " robloxHwnd) {
        SetTimer(UpdateOverlayPosition, 0)
        return
    }

    ; Get the size of the Roblox client area.
    rect := Buffer(16, 0)
    DllCall("GetClientRect", "Ptr", robloxHwnd, "Ptr", rect)
    
    w := NumGet(rect, 8, "Int")
    h := NumGet(rect, 12, "Int")

    ; Only update if the size has changed.
    if (w > 0 and h > 0 and (w != lastW or h != lastH)) {
        ; As a child window, our position is (0,0) relative to the parent's client area.
        myGui.Move(0, 0, w, h)
        lastW := w, lastH := h
    }
}

; --- Input Forwarder Management -------------------------------------------------

LaunchInputForwarder() {
    global myGui, inputForwarderPID

    ; If a previous forwarder is running, terminate it first
    if IsSet(inputForwarderPID) && inputForwarderPID {
        ProcessClose(inputForwarderPID)
    }

    if !IsObject(myGui) || !myGui.Hwnd {
        return
    }

    commandToRun := '"' A_AhkPath '" "' A_ScriptDir '\RoHTML\Lib\RoHTML\InputForwarder.ahk" ' myGui.Hwnd
    Run(commandToRun, "", "", &inputForwarderPID)
    
    ; Set REALTIME priority for input forwarder for maximum responsiveness
    if inputForwarderPID {
        SetProcessPriority(inputForwarderPID, 0x00000100)  ; REALTIME_PRIORITY_CLASS
    }
}

ExitCleanup(*) {
    global inputForwarderPID, customCursorPID, robloxIconPID, robloxMacrosPID
    
    ; Close InputForwarder
    if IsSet(inputForwarderPID) && inputForwarderPID {
        ProcessClose(inputForwarderPID)
        inputForwarderPID := 0
    }

    ; Close CustomCursor
    if IsSet(customCursorPID) && customCursorPID {
        ProcessClose(customCursorPID)
        customCursorPID := 0
    }

    ; Close ChangeRobloxIcon
    if IsSet(robloxIconPID) && robloxIconPID {
        ProcessClose(robloxIconPID)
        robloxIconPID := 0
    }

    ; Close Roblox_Macros
    if IsSet(robloxMacrosPID) && robloxMacrosPID {
        ProcessClose(robloxMacrosPID)
        robloxMacrosPID := 0
    }
}

; Handle WM_COPYDATA from InputForwarder ----------------------------------------------------
ReceiveInputData(wParam, lParam, msg, hwnd) {
    global myGui

    dataPtr := NumGet(lParam, A_PtrSize * 2, "Ptr")
    if !dataPtr {
        return 1
    }
    data := StrGet(dataPtr, "UTF-8")

    js := "handleAhkInput(`"" . data . "`")"
    try {
        ; Use synchronous execution for zero latency
        myGui.wv.ExecuteScript(js)
    } catch as e {
        ; Only handle critical errors silently
    }
    return 1
}
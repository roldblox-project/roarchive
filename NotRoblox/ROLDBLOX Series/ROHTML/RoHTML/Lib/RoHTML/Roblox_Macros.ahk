#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir
DetectHiddenWindows true

; --- Functions ---
LeaveGame() {
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate()
        Sleep 10
        Send "^+g" ; Press Ctrl+Shift+G
        Sleep 10 ; Wait for menu to open
        Send "l"
        Sleep 10
        Send "{Enter}"
        Sleep 10 ; Wait for menu to open
        Send "^+g" ; Press Ctrl+Shift+G
        Send "{Shift}" ; Press Shift, to prevent the weird shiftlock problem
    }
}

ResetCharacter() {
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate()
        Sleep 10
        Send "^+g" ; Press Ctrl+Shift+G
        Sleep 10 ; Wait for menu to open
        Send "r"
        Sleep 10
        Send "{Enter}"
        Sleep 10 ; Wait for menu to open
        Send "^+g" ; Press Ctrl+Shift+G
        Send "{Shift}" ; Press Shift, to prevent the weird shiftlock problem
    }
}

; --- Hotkeys ---
#HotIf WinActive("ahk_exe RobloxPlayerBeta.exe")
Numpad1::ResetCharacter()
Numpad2::LeaveGame()
#HotIf

; Set up message handling
OnMessage(0x4A, ReceiveMessage) ; WM_COPYDATA

ReceiveMessage(wParam, lParam, msg, hwnd) {
    static WM_COPYDATA := 0x4A
    
    MsgBox("Debug: Message received!", "RoHTML Debug", "T2")  ; Debug line to check if function is called
    
    ; Get the data from the message
    data := StrGet(NumGet(lParam + 2*A_PtrSize, "Ptr"), "UTF-8")
    
    try {
        MsgBox("Debug: Data received = " data, "RoHTML Debug", "T2")  ; Show what data we received
        
        parts := StrSplit(data, ";")
        if (parts.Length >= 2) {
            MsgBox("Debug: Message type = " parts[1] ", action = " parts[2], "RoHTML Debug", "T2")
            
            if (parts[1] = "macros") {
                if (parts[2] = "resetCharacter") {
                    MsgBox("Reset Character button pressed!", "RoHTML Test", "T2")  ; Shows for 2 seconds
                    ResetCharacter()
                }
                else if (parts[2] = "leaveGame") {
                    MsgBox("Leave Game button pressed!", "RoHTML Test", "T2")  ; Shows for 2 seconds
                    LeaveGame()
                }
            }
        }
    }
    catch as e {
        MsgBox "Error: " e.Message  ; Show errors for debugging
    }
    return true
}

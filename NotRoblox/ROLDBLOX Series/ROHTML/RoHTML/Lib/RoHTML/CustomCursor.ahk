#Requires AutoHotkey v2.0

; Paths to cursor images
FAR_CURSOR := A_ScriptDir "\..\..\content\textures\ArrowFarCursor.png"
HOVER_CURSOR := A_ScriptDir "\..\..\content\textures\ArrowCursor.png"

; Create cursors from PNG files
CreateCursorFromPNG(pngPath) {
    try {
        ; Load the PNG as an icon first
        hIcon := LoadPicture(pngPath, "Icon")
        if !hIcon {
            MsgBox "Failed to load cursor image: " pngPath
            return 0
        }
        return hIcon
    } catch as err {
        MsgBox "Error creating cursor: " err.Message
        return 0
    }
}

; Set system cursor
SetSystemCursor(hCursor) {
    try {
        ; OCR_NORMAL = 32512 (IDC_ARROW)
        DllCall("SetSystemCursor", "Ptr", DllCall("CopyIcon", "Ptr", hCursor), "UInt", 32512)
    } catch as err {
        MsgBox "Error setting system cursor: " err.Message
    }
}

; Restore original system cursors
RestoreSystemCursors() {
    DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)  ; SPI_SETCURSORS
}

; Check if cursor is over Roblox window
IsCursorOverRoblox() {
    MouseGetPos(,, &win)
    return WinExist("ahk_exe RobloxPlayerBeta.exe ahk_id " win)
}

; Create cursors
if !FileExist(FAR_CURSOR) || !FileExist(HOVER_CURSOR) {
    MsgBox "Cursor images not found!"
    ExitApp
}

hFarCursor := CreateCursorFromPNG(FAR_CURSOR)
hHoverCursor := CreateCursorFromPNG(HOVER_CURSOR)

; Monitor cursor position and update system cursor
SetTimer(MonitorCursor, 16)  ; ~60fps update rate

MonitorCursor() {
    static lastState := false
    
    if IsCursorOverRoblox() {
        if !lastState {
            SetSystemCursor(hFarCursor)
            lastState := true
        }
    } else if lastState {
        RestoreSystemCursors()
        lastState := false
    }
}

; Clean up on script exit
ExitFunc(ExitReason, ExitCode) {
    RestoreSystemCursors()
}
OnExit(ExitFunc) 
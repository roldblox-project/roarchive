#Requires AutoHotkey v2.0

; ===================== CONFIGURATION =====================
CONFIG_FILE := A_ScriptDir "\..\..\..\RoHTML\config.js"    ; Path corrected to go from Lib/RoHTML to the main RoHTML folder
ICON_PATH := A_ScriptDir "\..\..\..\RoHTML\icons\AppIcon.ico"    ; Icon file exists in icons directory
; =====================================================

; Read the custom title from config file
ReadCustomTitle() {
    try {
        if FileExist(CONFIG_FILE) {
            ; Read and parse JS
            configText := FileRead(CONFIG_FILE)
            ; Use RegEx to find the title in the nested window object - matches actual config structure
            if RegExMatch(configText, '"window"\s*:\s*{[^}]*"title"\s*:\s*"([^"]+)"', &match) {
                return match[1]
            }
            ; Fallback pattern for different formatting
            if RegExMatch(configText, '"title"\s*:\s*"([^"]+)"', &match) {
                return match[1]
            }
            ; Another fallback pattern
            if RegExMatch(configText, 'title\s*:\s*"([^"]+)"', &match) {
                return match[1]
            }
        }
    } catch as err {
        ; Silent error handling
    }
    return "ROBLOX"  ; Default title if config file can't be read
}

; Function to modify Roblox window
ModifyRobloxWindow() {
    try {
        ; Set window matching modes
        SetTitleMatchMode 2  ; Match anywhere in the title
        SetTitleMatchMode "Fast"  ; Use faster matching mode
        
        ; Get current custom title
        customTitle := ReadCustomTitle()
        
        ; Try to find and modify all Roblox windows
        windowList := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        
        for hwnd in windowList {
            ; Skip invisible or child windows
            if !WinExist("ahk_id " hwnd) {
                continue
            }
            
            ; Get current window title
            currentTitle := WinGetTitle("ahk_id " hwnd)
            if !currentTitle {
                continue
            }
            
            ; Always try to set the title (more aggressive approach)
            try {
                ; Method 1: Try WinSetTitle first
                WinSetTitle customTitle, "ahk_id " hwnd
                
                ; Method 2: Also try direct API call as backup
                DllCall("SetWindowText", "Ptr", hwnd, "Str", customTitle)
                
                ; Verify the title was actually set
                Sleep 100
                newTitle := WinGetTitle("ahk_id " hwnd)
                if (newTitle = customTitle) {
                } else {
                }
            } catch as err {
            }
            
            ; Change the window icon if icon file exists
            if FileExist(ICON_PATH) {
                try {
                    ; Use SendMessage to change the icon in AHK v2
                    iconWidth := 32  ; Standard icon size
                    hIcon := LoadPicture(ICON_PATH, "Icon w" iconWidth, &iconWidth)  ; Load the icon with width parameter
                    if hIcon {
                        SendMessage(0x80, 0, hIcon,, "ahk_id " hwnd)    ; ICON_SMALL
                        SendMessage(0x80, 1, hIcon,, "ahk_id " hwnd)    ; ICON_BIG
                    }
                } catch as err {
                }
            } else {
            }
        }
    } catch as err {
    }
}

; Main loop - continuously monitor for Roblox
Loop {
    ; Wait for Roblox process to exist
    ProcessWait "RobloxPlayerBeta.exe"
    
    ; Give Roblox a moment to create its window
    Sleep 2000  ; Increased wait time to ensure window is fully created
    
    ; Keep checking while Roblox is running
    while ProcessExist("RobloxPlayerBeta.exe") {
        ; Try to modify any Roblox windows
        ModifyRobloxWindow()
        ; Check every 10 seconds to maintain title and icon (more frequent)
        Sleep 10000  ; 10 seconds - more aggressive refresh
    }
    
    ; When Roblox closes, wait for it to start again
    ProcessWaitClose "RobloxPlayerBeta.exe"
}

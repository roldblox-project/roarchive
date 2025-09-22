#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%

; Add admin check at the start of the script
if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}

; === CONFIG ===
sensitivity := 0.2
baseMove1 := 53
baseMove2 := 10
freezeTime := 50 ; milliseconds to stay frozen
unfreezeTime := 100 ; milliseconds to stay unfrozen
flickerInterval := 50 ; milliseconds between flickers
repeatFlicker := false ; whether to repeatedly flicker or just once
frozen := false
lagSpikeMode := false
robloxPID := 0
frozenPID := 0
suspendInterval := 16  ; How long to stay suspended (ms)
resumeInterval := 1    ; How long to stay resumed (ms)
antiDisconnectInterval := 800  ; Unfreeze every 800ms (0.8 seconds)
microUnfreezeTime := 1  ; Microsecond unfreeze time
maxRetries := 50  ; Maximum number of unfreeze retries
gameResizable := false  ; Keep this to avoid errors but it won't be used
keepAliveInterval := 200  ; Window message every 200ms

; Windows Messages Constants
WM_SYSCOMMAND := 0x0112
SC_MONITORPOWER := 0xF170

; DirectX Constants
D3DERR_DEVICELOST := 0x88760868
D3DERR_DEVICENOTRESET := 0x88760869

; Windows Constants
PROCESS_ALL_ACCESS := 0x1F0FFF
WM_ACTIVATE := 0x0006
WA_INACTIVE := 0
WA_ACTIVE := 1
WM_SYSCOMMAND := 0x0112
SC_MOVE := 0xF010

; Windows Constants
THREAD_SUSPEND_RESUME := 0x0002
THREAD_TERMINATE := 0x0001
TH32CS_SNAPTHREAD := 0x00000004
INFINITE := 0xFFFFFFFF
PROCESS_TERMINATE := 0x0001
HIGH_PRIORITY_CLASS := 0x00000080
REALTIME_PRIORITY_CLASS := 0x00000100
WM_NULL := 0x0000
WM_PAINT := 0x000F

; Default keybind values - used for reset
defaultFreezeKey := "^z"    ; Default Ctrl+Z
defaultLagKey := "^f" ; Default Ctrl+F
defaultFlick1Key := "XButton1" ; Default Mouse4
defaultFlick2Key := "XButton2" ; Default Mouse5
defaultResetKey := "r" ; Default R
defaultLeaveKey := "^Escape" ; Default Ctrl+Escape
defaultDanceKey := "F1"    ; Default F1
defaultLaughKey := "F2"    ; Default F2
defaultCheerKey := "F3"    ; Default F3

; Current keybind values
freezeKey := defaultFreezeKey
lagToggleKey := defaultLagKey
flick1Key := defaultFlick1Key
flick2Key := defaultFlick2Key
resetKey := defaultResetKey
leaveKey := defaultLeaveKey
danceKey := defaultDanceKey
laughKey := defaultLaughKey
cheerKey := defaultCheerKey

; Shortcut toggles
resetEnabled := true
leaveEnabled := true
danceEnabled := true
laughEnabled := true
cheerEnabled := true

; Disable existing hotkeys while setting new ones
settingHotkey := false

; Windows Constants
WS_THICKFRAME := 0x00040000
WS_MAXIMIZEBOX := 0x00010000
WS_MINIMIZEBOX := 0x00020000
GWL_STYLE := -16
SWP_FRAMECHANGED := 0x0020
SWP_NOMOVE := 0x0002
SWP_NOSIZE := 0x0001
SWP_NOZORDER := 0x0004
WS_CAPTION := 0x00C00000
WS_SYSMENU := 0x00080000
WS_SIZEBOX := 0x00040000

; Add these constants
NORMAL_PRIORITY_CLASS := 0x00000020
BELOW_NORMAL_PRIORITY_CLASS := 0x00004000
ABOVE_NORMAL_PRIORITY_CLASS := 0x00008000
PROCESS_SET_QUOTA := 0x0100
PROCESS_SET_INFORMATION := 0x0200
JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE := 0x2000

; Add path constants for Roblox
ROBLOX_PROTOCOL := "roblox://"
ROBLOX_PROCESS := "RobloxPlayerBeta.exe"

; Window manipulation constants
GWLP_WNDPROC := -4
WM_GETMINMAXINFO := 0x0024
WM_NCCALCSIZE := 0x0083
WM_WINDOWPOSCHANGED := 0x0047
isResizing := false
lastWidth := 0
lastHeight := 0

; DWM constants
DWMWA_EXTENDED_FRAME_BOUNDS := 9
DWM_EC_DISABLECOMPOSITION := 0
DWM_EC_ENABLECOMPOSITION := 1

; Add lag switch variables
defaultLagSwitchKey := "^b" ; Default Ctrl+B
lagSwitchKey := defaultLagSwitchKey
lagSwitchEnabled := true
networkBlocked := false

; Add global variable for auto-reconnect timer
global autoReconnectTimer := 2000 ; 3 seconds in milliseconds

; === Modern UI Polish (Comfortable Spacing) ===
Gui, New, +Resize +MinSize400x600
Gui, Font, s9, Segoe UI
Gui, Add, Tab3, x10 y10 w380 h580 vMainTab, Main|Keybinds|Lag Switch|About

; === Main Tab ===
Gui, Tab, 1

; Status Panel
Gui, Add, GroupBox, x20 y40 w360 h50, Status
Gui, Add, Text, x30 y60 w100 vFrozenStatus, % "Frozen: " . (frozen ? "Yes" : "No")
Gui, Add, Text, x140 y60 w100 vLagModeStatus, % "Lag Switch: " . (networkBlocked ? "On" : "Off")
Gui, Add, Text, x250 y60 w120 vRobloxStatus, % "Roblox: " . (robloxPID ? "Running" : "Unknown")

; Quick Controls
Gui, Add, GroupBox, x20 y100 w360 h60, Quick Controls
Gui, Add, Button, x30 y120 w100 h25 gToggleLagMode vBtnToggleLag, Toggle Lag
Gui, Add, Button, x140 y120 w100 h25 gRestartRoblox vBtnRestartRoblox, Restart Roblox
Gui, Add, Button, x250 y120 w100 h25 gApplySettings vBtnApplySettings, Apply Settings

; Shortcuts Group
Gui, Add, GroupBox, x20 y170 w360 h120, Shortcuts
Gui, Add, Checkbox, x30 y190 w160 vResetEnabledCheck gToggleReset Checked%resetEnabled%, Enable Reset Character
Gui, Add, Checkbox, x30 y215 w160 vLeaveEnabledCheck gToggleLeave Checked%leaveEnabled%, Enable Leave Game
Gui, Add, Checkbox, x30 y240 w160 vDanceEnabledCheck gToggleDance Checked%danceEnabled%, Enable Dance Emote
Gui, Add, Checkbox, x30 y265 w160 vLaughEnabledCheck gToggleLaugh Checked%laughEnabled%, Enable Laugh Emote
Gui, Add, Checkbox, x200 y190 w160 vCheerEnabledCheck gToggleCheer Checked%cheerEnabled%, Enable Cheer Emote

; Settings Panel
Gui, Add, GroupBox, x20 y300 w360 h180, Settings

; Mouse Settings
Gui, Add, Text, x30 y320, Mouse Settings:
Gui, Add, Text, x40 y345, Sensitivity:
Gui, Add, Edit, x110 y342 w50 vSensitivityEdit, %sensitivity%
Gui, Add, Text, x200 y345, Base Move 1:
Gui, Add, Edit, x270 y342 w50 vBaseMove1Edit, %baseMove1%

Gui, Add, Text, x40 y370, Base Move 2:
Gui, Add, Edit, x110 y367 w50 vBaseMove2Edit, %baseMove2%

; Timing Settings
Gui, Add, Text, x30 y400, Timing Settings:
Gui, Add, Text, x40 y425, Freeze (ms):
Gui, Add, Edit, x110 y422 w50 vFreezeTimeEdit, %freezeTime%
Gui, Add, Text, x200 y425, Unfreeze (ms):
Gui, Add, Edit, x270 y422 w50 vUnfreezeTimeEdit, %unfreezeTime%

; Flicker Settings
Gui, Add, Text, x40 y450, FlicInterval (ms):
Gui, Add, Edit, x110 y447 w50 vFlickerIntervalEdit, %flickerInterval%
Gui, Add, Text, x200 y450, Mode:
Gui, Add, DropDownList, x270 y447 w70 vFlickerModeList, Single||Repeat

; === Keybinds Tab ===
Gui, Tab, 2
Gui, Add, GroupBox, x20 y40 w360 h520, Keybinds Configuration

; Create a more organized layout for keybinds
Gui, Add, Text, x30 y60, Game Controls:
keyY := 85

; Game Controls Section
Gui, Add, Text, x40 y%keyY%, Freeze:
Gui, Add, Edit, x130 y%keyY% w140 vFreezeKeyEdit ReadOnly, % freezeKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetFreezeKey vBtnSetFreeze, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetFreezeKey vBtnResetFreeze, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Lag Mode:
Gui, Add, Edit, x130 y%keyY% w140 vLagToggleKeyEdit ReadOnly, % lagToggleKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetLagToggleKey vBtnSetLagToggle, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetLagToggleKey vBtnResetLagToggle, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Flick Hold (M4):
Gui, Add, Edit, x130 y%keyY% w140 vFlick1KeyEdit ReadOnly, % flick1Key
Gui, Add, Button, x280 y%keyY% w45 h23 gSetFlick1Key vBtnSetFlick1, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetFlick1Key vBtnResetFlick1, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Continuous (M5):
Gui, Add, Edit, x130 y%keyY% w140 vFlick2KeyEdit ReadOnly, % flick2Key
Gui, Add, Button, x280 y%keyY% w45 h23 gSetFlick2Key vBtnSetFlick2, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetFlick2Key vBtnResetFlick2, Reset

; Character Actions Section
keyY += 45
Gui, Add, Text, x30 y%keyY%, Character Actions:
keyY += 25
Gui, Add, Text, x40 y%keyY%, Reset Character:
Gui, Add, Edit, x130 y%keyY% w140 vResetKeyEdit ReadOnly, % resetKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetResetKey vBtnSetReset, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetResetKey vBtnResetReset, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Leave Game:
Gui, Add, Edit, x130 y%keyY% w140 vLeaveKeyEdit ReadOnly, % leaveKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetLeaveKey vBtnSetLeave, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetLeaveKey vBtnResetLeave, Reset

; Emotes Section
keyY += 45
Gui, Add, Text, x30 y%keyY%, Emotes:
keyY += 25
Gui, Add, Text, x40 y%keyY%, Dance:
Gui, Add, Edit, x130 y%keyY% w140 vDanceKeyEdit ReadOnly, % danceKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetDanceKey vBtnSetDance, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetDanceKey vBtnResetDance, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Laugh:
Gui, Add, Edit, x130 y%keyY% w140 vLaughKeyEdit ReadOnly, % laughKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetLaughKey vBtnSetLaugh, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetLaughKey vBtnResetLaugh, Reset

keyY += 30
Gui, Add, Text, x40 y%keyY%, Cheer:
Gui, Add, Edit, x130 y%keyY% w140 vCheerKeyEdit ReadOnly, % cheerKey
Gui, Add, Button, x280 y%keyY% w45 h23 gSetCheerKey vBtnSetCheer, Set
Gui, Add, Button, x330 y%keyY% w45 h23 gResetCheerKey vBtnResetCheer, Reset

; Add Apply button at the bottom with proper spacing
Gui, Add, Button, x130 y520 w140 h25 gApplyKeybinds vBtnApplyKeybinds, Apply Keybinds

; === Lag Switch Tab ===
Gui, Tab, 3
Gui, Add, GroupBox, x20 y40 w360 h520, Network Control

; Status Section
Gui, Add, GroupBox, x30 y60 w340 h60, Status
Gui, Add, Text, x40 y80, Current Status:
Gui, Add, Text, x120 y80 w240 vLagSwitchStatus, % (networkBlocked ? "Network Blocked" : "Network Active")

; Controls Section
Gui, Add, GroupBox, x30 y130 w340 h90, Controls
Gui, Add, Button, x40 y150 w180 h25 gToggleLagSwitch vBtnToggleLagSwitch, Toggle Network Block
Gui, Add, Text, x40 y185, Hotkey:
Gui, Add, Edit, x120 y182 w140 vLagSwitchKeyEdit ReadOnly, % lagSwitchKey
Gui, Add, Button, x270 y182 w45 h23 gSetLagSwitchKey vBtnSetLagSwitch, Set
Gui, Add, Button, x320 y182 w45 h23 gResetLagSwitchKey vBtnResetLagSwitch, Reset

; Information Section
Gui, Add, GroupBox, x30 y230 w340 h310, Information
Gui, Add, Text, x40 y250 w320, Network blocking allows you to temporarily stop all network traffic for Roblox. This can be useful for:
Gui, Add, Text, x50 y290 w310, • Creating artificial lag spikes
Gui, Add, Text, x50 y310 w310, • Preventing unwanted network activity
Gui, Add, Text, x50 y330 w310, • Testing network-dependent features
Gui, Add, Text, x40 y370 w320, Note: Blocking network traffic for extended periods may result in disconnection from the game.

; === About Tab ===
Gui, Tab, 4
Gui, Add, GroupBox, x20 y40 w360 h520, About This Tool

; Tool Information
Gui, Add, GroupBox, x30 y60 w340 h140, Tool Information
Gui, Add, Text, x40 y80 w320, This tool provides advanced control and automation for Roblox, including process freezing, lag simulation, and custom keybinds.

Gui, Add, Text, x40 y110, Features:
Gui, Add, Text, x50 y130 w310, • Process freezing and lag simulation
Gui, Add, Text, x50 y150 w310, • Custom keybinds for various actions
Gui, Add, Text, x50 y170 w310, • Mouse flick controls with customizable settings

; Usage Instructions
Gui, Add, GroupBox, x30 y210 w340 h240, How to Use
Gui, Add, Text, x40 y230 w320, 1. Use the Main tab to monitor status and adjust settings
Gui, Add, Text, x40 y250 w320, 2. Configure your preferred keybinds in the Keybinds tab
Gui, Add, Text, x40 y270 w320, 3. Use the Lag Switch tab to control network behavior
Gui, Add, Text, x40 y290 w320, 4. All changes are applied immediately when using Apply
Gui, Add, Text, x40 y310 w320, 5. The tool only works when Roblox is the active window
Gui, Add, Text, x40 y330 w320, 6. Use responsibly and in accordance with game rules

; Credits
Gui, Add, GroupBox, x30 y460 w340 h80, Credits
Gui, Add, Text, x40 y480 w320, Created with AutoHotkey and WinDivert
Gui, Add, Text, x40 y500 w320, Version 1.0

Gui, Tab
Gui, Show, w400 h400, Roblox Control Panel

; Auto-apply keybinds on launch
#IfWinActive ahk_exe RobloxPlayerBeta.exe
if (freezeKey) {
    Hotkey, % "$" freezeKey, FreezeToggle, UseErrorLevel On
    Hotkey, % "$" freezeKey " up", FreezeToggleUp, UseErrorLevel On
}
if (lagToggleKey)
    Hotkey, $%lagToggleKey%, LagToggle, On
if (resetKey && resetEnabled)
    Hotkey, $%resetKey%, DoReset, On
if (leaveKey && leaveEnabled)
    Hotkey, $%leaveKey%, DoLeave, On
if (flick1Key != "XButton1")
    Hotkey, $%flick1Key%, Flick1, On
if (flick2Key != "XButton2")
    Hotkey, $%flick2Key%, Flick2, On
if (danceKey && danceEnabled)
    Hotkey, $%danceKey%, DoDance, On
if (laughKey && laughEnabled)
    Hotkey, $%laughKey%, DoLaugh, On
if (cheerKey && cheerEnabled)
    Hotkey, $%cheerKey%, DoCheer, On
if (lagSwitchKey && lagSwitchEnabled)
    Hotkey, $%lagSwitchKey%, ToggleLagSwitch, On
#IfWinActive

; === GUI Functions ===
ApplySettings:
Gui, Submit, NoHide
sensitivity := SensitivityEdit
baseMove1 := BaseMove1Edit
baseMove2 := BaseMove2Edit
freezeTime := FreezeTimeEdit
unfreezeTime := UnfreezeTimeEdit
flickerInterval := FlickerIntervalEdit
repeatFlicker := (FlickerModeList = "Repeat")
return

ToggleLagMode:
if (!settingHotkey)
    Gosub, LagToggle
return

; === Reset Functions ===
ResetFreezeKey:
GuiControl,, FreezeKeyEdit, %defaultFreezeKey%
return

ResetLagToggleKey:
GuiControl,, LagToggleKeyEdit, %defaultLagKey%
return

ResetFlick1Key:
GuiControl,, Flick1KeyEdit, %defaultFlick1Key%
return

ResetFlick2Key:
GuiControl,, Flick2KeyEdit, %defaultFlick2Key%
return

ResetResetKey:
GuiControl,, ResetKeyEdit, %defaultResetKey%
return

ResetLeaveKey:
GuiControl,, LeaveKeyEdit, %defaultLeaveKey%
return

ResetDanceKey:
GuiControl,, DanceKeyEdit, %defaultDanceKey%
return

ResetLaughKey:
GuiControl,, LaughKeyEdit, %defaultLaughKey%
return

ResetCheerKey:
GuiControl,, CheerKeyEdit, %defaultCheerKey%
return

; Add Lag Switch reset
ResetLagSwitchKey:
GuiControl,, LagSwitchKeyEdit, %defaultLagSwitchKey%
return

; === Keybind Setting Functions ===
SetFreezeKey:
SetHotkey("FreezeKeyEdit")
return

SetLagToggleKey:
SetHotkey("LagToggleKeyEdit")
return

SetFlick1Key:
SetHotkey("Flick1KeyEdit")
return

SetFlick2Key:
SetHotkey("Flick2KeyEdit")
return

SetResetKey:
SetHotkey("ResetKeyEdit")
return

SetLeaveKey:
SetHotkey("LeaveKeyEdit")
return

SetDanceKey:
SetHotkey("DanceKeyEdit")
return

SetLaughKey:
SetHotkey("LaughKeyEdit")
return

SetCheerKey:
SetHotkey("CheerKeyEdit")
return

; Add Lag Switch set function
SetLagSwitchKey:
SetHotkey("LagSwitchKeyEdit")
return

SetHotkey(controlName) {
    global settingHotkey
    settingHotkey := true
    
    ; Start listening for input before showing the message
    Input, SingleKey, L1 V M, {LButton}{RButton}{MButton}{XButton1}{XButton2}{Escape}
    
    if (ErrorLevel = "EndKey:Escape") {
        ; User pressed Escape, cancel setting hotkey
        GuiControl,, %controlName%, % %controlName%
    } else if (InStr(ErrorLevel, "EndKey:")) {
        ; Mouse button was pressed
        newKey := StrReplace(ErrorLevel, "EndKey:")
        GuiControl,, %controlName%, %newKey%
    } else if (ErrorLevel = "Max") {
        ; Normal key was pressed
        modifiers := ""
        modifiers .= GetKeyState("Ctrl", "P") ? "^" : ""
        modifiers .= GetKeyState("Alt", "P") ? "!" : ""
        modifiers .= GetKeyState("Shift", "P") ? "+" : ""
        GuiControl,, %controlName%, %modifiers%%SingleKey%
    }
    
    settingHotkey := false
}

; === Toggle Functions ===
ToggleReset:
Gui, Submit, NoHide
resetEnabled := ResetEnabledCheck

if (resetEnabled) {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%resetKey%, DoReset, On
    #IfWinActive
} else {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%resetKey%, DoReset, Off
    #IfWinActive
}
return

ToggleLeave:
Gui, Submit, NoHide
leaveEnabled := LeaveEnabledCheck

if (leaveEnabled) {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%leaveKey%, DoLeave, On
    #IfWinActive
} else {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%leaveKey%, DoLeave, Off
    #IfWinActive
}
return

ToggleDance:
Gui, Submit, NoHide
danceEnabled := DanceEnabledCheck

if (danceEnabled) {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%danceKey%, DoDance, On
    #IfWinActive
} else {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%danceKey%, DoDance, Off
    #IfWinActive
}
return

ToggleLaugh:
Gui, Submit, NoHide
laughEnabled := LaughEnabledCheck

if (laughEnabled) {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%laughKey%, DoLaugh, On
    #IfWinActive
} else {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%laughKey%, DoLaugh, Off
    #IfWinActive
}
return

ToggleCheer:
Gui, Submit, NoHide
cheerEnabled := CheerEnabledCheck

if (cheerEnabled) {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%cheerKey%, DoCheer, On
    #IfWinActive
} else {
    #IfWinActive ahk_exe RobloxPlayerBeta.exe
    Hotkey, $%cheerKey%, DoCheer, Off
    #IfWinActive
}
return

ApplyKeybinds:
Gui, Submit, NoHide

; Store new values temporarily
newFreezeKey := FreezeKeyEdit
newLagToggleKey := LagToggleKeyEdit
newFlick1Key := Flick1KeyEdit
newFlick2Key := Flick2KeyEdit
newResetKey := ResetKeyEdit
newLeaveKey := LeaveKeyEdit
newDanceKey := DanceKeyEdit
newLaughKey := LaughKeyEdit
newCheerKey := CheerKeyEdit
newLagSwitchKey := LagSwitchKeyEdit

; Disable old hotkeys
#IfWinActive ahk_exe RobloxPlayerBeta.exe
if (freezeKey) {
    Hotkey, % "$" freezeKey, FreezeToggle, UseErrorLevel Off
    Hotkey, % "$" freezeKey " up", FreezeToggleUp, UseErrorLevel Off
}
if (lagToggleKey)
    Hotkey, $%lagToggleKey%, LagToggle, Off
if (resetKey && resetEnabled)
    Hotkey, $%resetKey%, DoReset, Off
if (leaveKey && leaveEnabled)
    Hotkey, $%leaveKey%, DoLeave, Off
if (flick1Key != "XButton1")
    Hotkey, $%flick1Key%, Flick1, Off
if (flick2Key != "XButton2")
    Hotkey, $%flick2Key%, Flick2, Off
if (danceKey && danceEnabled)
    Hotkey, $%danceKey%, DoDance, Off
if (laughKey && laughEnabled)
    Hotkey, $%laughKey%, DoLaugh, Off
if (cheerKey && cheerEnabled)
    Hotkey, $%cheerKey%, DoCheer, Off
if (lagSwitchKey && lagSwitchEnabled)
    Hotkey, $%lagSwitchKey%, ToggleLagSwitch, Off

; Update to new values
freezeKey := newFreezeKey
lagToggleKey := newLagToggleKey
flick1Key := newFlick1Key
flick2Key := newFlick2Key
resetKey := newResetKey
leaveKey := newLeaveKey
danceKey := newDanceKey
laughKey := newLaughKey
cheerKey := newCheerKey
lagSwitchKey := newLagSwitchKey

; Enable new hotkeys
if (freezeKey) {
    Hotkey, % "$" freezeKey, FreezeToggle, UseErrorLevel On
    Hotkey, % "$" freezeKey " up", FreezeToggleUp, UseErrorLevel On
}
if (lagToggleKey)
    Hotkey, $%lagToggleKey%, LagToggle, On
if (resetKey && resetEnabled)
    Hotkey, $%resetKey%, DoReset, On
if (leaveKey && leaveEnabled)
    Hotkey, $%leaveKey%, DoLeave, On
if (flick1Key != "XButton1")
    Hotkey, $%flick1Key%, Flick1, On
if (flick2Key != "XButton2")
    Hotkey, $%flick2Key%, Flick2, On
if (danceKey && danceEnabled)
    Hotkey, $%danceKey%, DoDance, On
if (laughKey && laughEnabled)
    Hotkey, $%laughKey%, DoLaugh, On
if (cheerKey && cheerEnabled)
    Hotkey, $%cheerKey%, DoCheer, On
if (lagSwitchKey && lagSwitchEnabled)
    Hotkey, $%lagSwitchKey%, ToggleLagSwitch, On
#IfWinActive
return

GuiClose:
ExitApp

UpdateStatus:
GuiControl,, FrozenStatus, % "Frozen: " . (frozen ? "Yes" : "No")
GuiControl,, LagModeStatus, % "Lag Switch: " . (networkBlocked ? "On" : "Off")
GuiControl,, LagSwitchStatus, % (networkBlocked ? "On" : "Off")
GuiControl,, RobloxStatus, % "Roblox: " . (robloxPID ? "Running" : "Unknown")
return

; === Main Functions ===
#IfWinActive ahk_exe RobloxPlayerBeta.exe
Flick1:
MouseGetPos, origX, origY
moveAmount := baseMove1 * (0.2 / sensitivity)
MouseMove, origX - moveAmount, origY, 0
KeyWait, %flick1Key%
MouseMove, origX, origY, 0
return

Flick2:
if (repeatFlicker) {
    Gosub, DoFlick ; Do first flick immediately
    SetTimer, DoFlick, %flickerInterval%
} else {
    Gosub, DoFlick
}
KeyWait, %flick2Key%
SetTimer, DoFlick, Off
return

; Keep XButton1/XButton2 as backup if custom keys fail
XButton1::
if (!settingHotkey && flick1Key = "XButton1") {
    MouseGetPos, origX, origY
    moveAmount := baseMove1 * (0.2 / sensitivity)
    MouseMove, origX - moveAmount, origY, 0
}
return

XButton1 up::
if (!settingHotkey && flick1Key = "XButton1") {
    MouseMove, origX, origY, 0
}
return

XButton2::
if (!settingHotkey && flick2Key = "XButton2") {
    if (repeatFlicker) {
        Gosub, DoFlick ; Do first flick immediately
        SetTimer, DoFlick, %flickerInterval%
    } else {
        Gosub, DoFlick
    }
}
return

XButton2 up::
if (!settingHotkey && flick2Key = "XButton2") {
    SetTimer, DoFlick, Off
}
return

DoFlick:
MouseGetPos, origX, origY
moveAmount := baseMove2 * (0.2 / sensitivity)

; Check if 'a' is being held to reverse the direction
if (GetKeyState("a", "P")) {
    MouseMove, origX + moveAmount, origY, 0
} else {
    MouseMove, origX - moveAmount, origY, 0
}
MouseMove, origX, origY, 0
return

FreezeToggle:
if (settingHotkey || lagSpikeMode)
    return

WinGet, robloxPID, PID, ahk_exe RobloxPlayerBeta.exe
if (!robloxPID)
    return

if (!frozen) {
    ; Freeze instantly first
    hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", robloxPID, "Ptr")
    if (hProc) {
        DllCall("ntdll\NtSuspendProcess", "Ptr", hProc)
        DllCall("CloseHandle", "Ptr", hProc)
    }
    
    ; Then update state and start timers
    frozenPID := robloxPID
    frozen := true
    Gosub, UpdateStatus
    SetTimer, KeepAliveTimer, %keepAliveInterval%
    SetTimer, AntiDisconnectTimer, %antiDisconnectInterval%
} else {
    ; Unfreeze instantly first
    hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", frozenPID, "Ptr")
    if (hProc) {
        DllCall("ntdll\NtResumeProcess", "Ptr", hProc)
        DllCall("CloseHandle", "Ptr", hProc)
    }
    
    ; Then update state and stop timers
    frozen := false
    frozenPID := 0
    Gosub, UpdateStatus
    SetTimer, AntiDisconnectTimer, Off
    SetTimer, KeepAliveTimer, Off
}
return

; Keep-alive timer to prevent "Not Responding"
KeepAliveTimer:
if (!frozen || !frozenPID)
    return

WinGet, robloxHwnd, ID, ahk_pid %frozenPID%
if (robloxHwnd) {
    PostMessage, WM_NULL, 0, 0,, ahk_id %robloxHwnd%
    PostMessage, 0x0200, 0, 0,, ahk_id %robloxHwnd%
    DllCall("UpdateWindow", "Ptr", robloxHwnd)
}
return

; Anti-disconnect timer function
AntiDisconnectTimer:
if (!frozen || !frozenPID)
    return

hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", frozenPID, "Ptr")
if (hProc) {
    DllCall("ntdll\NtResumeProcess", "Ptr", hProc)
    Sleep, 1
    DllCall("ntdll\NtSuspendProcess", "Ptr", hProc)
    DllCall("CloseHandle", "Ptr", hProc)
}
return

LagToggle:
if (settingHotkey)
    return

lagSpikeMode := !lagSpikeMode
if (lagSpikeMode) {
    ; Start with a freeze
    WinGet, robloxPID, PID, ahk_exe RobloxPlayerBeta.exe
    if (robloxPID) {
        frozen := true
        hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", robloxPID, "Ptr")
        DllCall("ntdll\NtSuspendProcess", "Ptr", hProc)
        DllCall("CloseHandle", "Ptr", hProc)
        SetTimer, LagSpikeLoop, % freezeTime
    }
} else {
    SetTimer, LagSpikeLoop, Off
    if (frozen) {
        WinGet, robloxPID, PID, ahk_exe RobloxPlayerBeta.exe
        if (robloxPID) {
            hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", robloxPID, "Ptr")
            DllCall("ntdll\NtResumeProcess", "Ptr", hProc)
            DllCall("CloseHandle", "Ptr", hProc)
            frozen := false
        }
    }
}
Gosub, UpdateStatus
return

LagSpikeLoop:
WinGet, robloxPID, PID, ahk_exe RobloxPlayerBeta.exe
if (!robloxPID)
    return

; Check if window is responding
if (!WinExist("ahk_exe RobloxPlayerBeta.exe") || WinExist("ahk_exe RobloxPlayerBeta.exe ahk_class #32770")) {
    SetTimer, LagSpikeLoop, Off
    lagSpikeMode := false
    frozen := false
    Gosub, UpdateStatus
    return
}

hProc := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", false, "UInt", robloxPID, "Ptr")

if (frozen) {
    ; If currently frozen, unfreeze and set timer for unfreeze duration
    DllCall("ntdll\NtResumeProcess", "Ptr", hProc)
    frozen := false
    SetTimer, LagSpikeLoop, % unfreezeTime
} else {
    ; If currently unfrozen, freeze and set timer for freeze duration
    DllCall("ntdll\NtSuspendProcess", "Ptr", hProc)
    frozen := true
    SetTimer, LagSpikeLoop, % freezeTime
}

DllCall("CloseHandle", "Ptr", hProc)
return

; === Shortcut Functions ===
#IfWinActive ahk_exe RobloxPlayerBeta.exe
DoReset:
if (!resetEnabled)
    return
BlockInput, On
SetKeyDelay, 1, 1
Send {Escape}
Sleep 50
Send r
Sleep 50
Send {Enter}
BlockInput, Off
return

DoLeave:
if (!leaveEnabled)
    return
BlockInput, On
SetKeyDelay, 1, 1
Send {Escape}
Sleep 50
Send l
Sleep 50
Send {Enter}
BlockInput, Off
return

DoDance:
if (!danceEnabled)
    return
BlockInput, On
clipboard := "/e dance2"
Send ^/
Sleep 10
Send ^v
Sleep 10
Send {Enter}
BlockInput, Off
return

DoLaugh:
if (!laughEnabled)
    return
BlockInput, On
clipboard := "/e laugh"
Send ^/
Sleep 10
Send ^v
Sleep 10
Send {Enter}
BlockInput, Off
return

DoCheer:
if (!cheerEnabled)
    return
BlockInput, On
clipboard := "/e cheer"
Send ^/
Sleep 10
Send ^v
Sleep 10
Send {Enter}
BlockInput, Off
return
#IfWinActive

ToggleGameResize:
return

CheckRobloxWindow:
return

; === New Restart Function ===
RestartRoblox:
Gui, +OwnDialogs
MsgBox, 4, Confirm Restart, Are you sure you want to restart Roblox?
IfMsgBox, No
    return

; Get current Roblox window info before closing
WinGet, robloxPID, PID, ahk_exe %ROBLOX_PROCESS%
if (!robloxPID) {
    MsgBox, Roblox is not running.
    return
}

; Get the command line of the current Roblox process to extract the URL
WinGet, robloxHwnd, ID, ahk_pid %robloxPID%
WinGetTitle, gameTitle, ahk_id %robloxHwnd%

; Force close Roblox
Process, Close, %robloxPID%

; Wait for process to fully close
WinWaitClose, ahk_pid %robloxPID%

; Small delay to ensure clean shutdown
Sleep, 1000

; Try to get the game URL from the window title
if (InStr(gameTitle, " - ")) {
    ; Extract game name from title
    gameName := RegExReplace(gameTitle, " - Roblox$")
    
    ; Construct search URL
    searchURL := "https://www.roblox.com/games?searchString=" . UriEncode(gameName)
    
    ; Open Roblox with search URL
    Run, %ROBLOX_PROTOCOL%%searchURL%
} else {
    ; If we can't get the specific game, just launch Roblox
    Run, %ROBLOX_PROTOCOL%
}
return

; URI Encode function for game name
UriEncode(str) {
    f = %A_FormatInteger%
    SetFormat, Integer, Hex
    If RegExMatch(str, "^\w+:/{0,2}", pr)
        StringTrimLeft, str, str, StrLen(pr)
    StringReplace, str, str, `%, `%25, All
    Loop
        If RegExMatch(str, "i)[^\w\.~%/:\[\]-]", char)
            StringReplace, str, str, %char%, % "%" . SubStr(Asc(char),3), All
        Else Break
    SetFormat, Integer, %f%
    Return, pr . str
}

; === Lag Switch Function ===
ToggleLagSwitch:
if (settingHotkey)
    return

networkBlocked := !networkBlocked

if (networkBlocked) {
    lagSwitchExe := A_ScriptDir . "\\netfilter.exe"
    ; Block all network traffic
    Run, %lagSwitchExe% "true", , Hide, lagSwitchPID
    GuiControl,, LagModeStatus, Network Blocked: Yes
} else {
    if (lagSwitchPID) {
        Process, Close, %lagSwitchPID%
        lagSwitchPID := 0
    }
    GuiControl,, LagModeStatus, Network Blocked: No
}
return

; Auto-reconnect function
AutoReconnect:
SetTimer, AutoReconnect, Off ; Clear the timer
networkBlocked := false
RunWait, % "netsh interface set interface ""Wi-Fi"" enabled",, Hide
RunWait, % "netsh interface set interface ""Ethernet"" enabled",, Hide
GuiControl,, LagModeStatus, % "Network Blocked: No"
return
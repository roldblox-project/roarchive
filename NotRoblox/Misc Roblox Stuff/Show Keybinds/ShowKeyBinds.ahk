#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#MaxHotkeysPerInterval 99999
Process, Priority,, High
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
Critical, On

; Initialize GDI+
If !pToken := Gdip_Startup()
{
    MsgBox, 48, GDI+ Error, GDI+ failed to start. Please ensure you have GDI+ on your system
    ExitApp
}

; Fixed dimensions
global imageSize := 48
global spaceWidth := 148
global spaceHeight := 32
global padding := 2
global totalWidth := 192  ; Changed to 192
global totalHeight := 176 ; Changed to 176

; Track key states
global wDown := false
global aDown := false
global sDown := false
global dDown := false
global spaceDown := false

; Create window
Gui, 1: +LastFound -Caption +ToolWindow +E0x80000
Gui, 1: Show, Hide w%totalWidth% h%totalHeight%
hwnd1 := WinExist()

; Create graphics
hbm := CreateDIBSection(totalWidth, totalHeight)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, 4)

; Load images
global pBitmapBG := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\BG.png")
global pBitmapW := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\W.png")
global pBitmapWHeld := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\W_Held.png")
global pBitmapA := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\A.png")
global pBitmapAHeld := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\A_Held.png")
global pBitmapS := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\S.png")
global pBitmapSHeld := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\S_Held.png")
global pBitmapD := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\D.png")
global pBitmapDHeld := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\D_Held.png")
global pBitmapSpace := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\Space.png")
global pBitmapSpaceHeld := Gdip_CreateBitmapFromFile(A_ScriptDir . "\Images\Space_Held.png")

; Calculate positions to be centered in the new background
global keyBlockHeight := imageSize + padding + imageSize + padding + spaceHeight
global asdBlockWidth := (imageSize * 3) + (padding * 2)
global asdBlockX := (totalWidth - asdBlockWidth) // 2

global yPosW := (totalHeight - keyBlockHeight) // 2
global yPosASD := yPosW + imageSize + padding
global spaceY := yPosASD + imageSize + padding

global xPosW := (totalWidth - imageSize) // 2
global xPosA := asdBlockX
global xPosS := xPosA + imageSize + padding
global xPosD := xPosS + imageSize + padding
global spaceX := (totalWidth - spaceWidth) // 2

; Make window click-through and non-interactive
WinSet, ExStyle, +0x20, ahk_id %hwnd1%  ; WS_EX_TRANSPARENT

UpdateAndRender() {
    global
    static lastOwnerHwnd := 0 ; Track the current owner window

    ; Get Roblox window
    WinGet, robloxHwnd, ID, ahk_exe RobloxPlayerBeta.exe
    if (!robloxHwnd) {
        Gui, 1:Hide
        lastOwnerHwnd := 0 ; Reset owner when Roblox closes
        return
    }

    ; Set Roblox as the owner window if it has changed
    if (robloxHwnd != lastOwnerHwnd) {
        Gui, 1:+Owner%robloxHwnd%
        lastOwnerHwnd := robloxHwnd
    }
    
    ; Get client area size
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "Ptr", robloxHwnd, "Ptr", &rect)
    clientW := NumGet(rect, 8, "Int")
    clientH := NumGet(rect, 12, "Int")
    
    ; Prepare bottom-right client point
    VarSetCapacity(pt, 8, 0)
    NumPut(clientW, pt, 0, "Int")
    NumPut(clientH, pt, 4, "Int")
    DllCall("ClientToScreen", "Ptr", robloxHwnd, "Ptr", &pt)
    screenX := NumGet(pt, 0, "Int")
    screenY := NumGet(pt, 4, "Int")
    
    ; Calculate overlay position (bottom right, no gap)
    newX := screenX - totalWidth
    newY := screenY - totalHeight
    
    ; Update key states
    wDown := GetKeyState("w", "P")
    aDown := GetKeyState("a", "P")
    sDown := GetKeyState("s", "P")
    dDown := GetKeyState("d", "P")
    spaceDown := GetKeyState("Space", "P")
    
    ; Clear the graphics and draw
    Gdip_GraphicsClear(G, 0x00000000)

    ; Draw BG.png as the background
    Gdip_DrawImage(G, pBitmapBG, 0, 0, totalWidth, totalHeight)

    ; Draw WASD keys
    Gdip_DrawImage(G, wDown ? pBitmapWHeld : pBitmapW, xPosW, yPosW, imageSize, imageSize)
    Gdip_DrawImage(G, aDown ? pBitmapAHeld : pBitmapA, xPosA, yPosASD, imageSize, imageSize)
    Gdip_DrawImage(G, sDown ? pBitmapSHeld : pBitmapS, xPosS, yPosASD, imageSize, imageSize)
    Gdip_DrawImage(G, dDown ? pBitmapDHeld : pBitmapD, xPosD, yPosASD, imageSize, imageSize)
    
    ; Draw Space key
    Gdip_DrawImage(G, spaceDown ? pBitmapSpaceHeld : pBitmapSpace, spaceX, spaceY, spaceWidth, spaceHeight)
    
    ; Update window content and position in one atomic operation
    UpdateLayeredWindow(hwnd1, hdc, newX, newY, totalWidth, totalHeight)
    Gui, 1:Show, NA, ShowKeyBinds
}

; Main loop timer
SetTimer, UpdateAndRender, 33 ; ~30 FPS

return

GuiClose:
; Clean up
Gdip_DeleteGraphics(G)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Gdip_Shutdown(pToken)
ExitApp

#Include %A_ScriptDir%\Gdip_All.ahk
;#####################################################################################
; GDI+ library
; by Tic (Tariq Porter)
; Requires: AutoHotkey_L
;#####################################################################################

; Function:             UpdateLayeredWindow
; Description:          Updates a layered window with the handle to the gdi bitmap
UpdateLayeredWindow(hwnd, hdc, x:="", y:="", w:="", h:="", Alpha:=255) {
    if ((x != "") && (y != ""))
        VarSetCapacity(pt, 8), NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt")

    if (w = "") || (h = "")
        WinGetPos,,, w, h, ahk_id %hwnd%

    return DllCall("UpdateLayeredWindow"
    , "UPtr", hwnd
    , "UPtr", 0
    , "UPtr", ((x = "") && (y = "")) ? 0 : &pt
    , "Int64*", w|h<<32
    , "UPtr", hdc
    , "Int64*", 0
    , "UInt", 0
    , "UInt*", Alpha<<16|1<<24
    , "UInt", 2)
}

;#####################################################################################

; Function:             BitBlt
; Description:         The BitBlt function performs a bit-block transfer of the color data corresponding to a rectangle 
;                               of pixels from the specified source device context into a destination device context.
;
; BitBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, Raster="")

BitBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, Raster:="") {
    return DllCall("gdi32\BitBlt"
    , "UPtr", dDC
    , "Int", dx
    , "Int", dy
    , "Int", dw
    , "Int", dh
    , "UPtr", sDC
    , "Int", sx
    , "Int", sy
    , "UInt", Raster ? Raster : 0x00CC0020)
}

;#####################################################################################

; Function:             CreateDIBSection
; Description:          The CreateDIBSection function creates a DIB (Device Independent Bitmap) that applications can write to directly
CreateDIBSection(w, h, hdc:="", bpp:=32, ByRef ppvBits:=0) {
    hdc2 := hdc ? hdc : GetDC()
    VarSetCapacity(bi, 40, 0)
    NumPut(w, bi, 4, "UInt")
    NumPut(h, bi, 8, "UInt")
    NumPut(40, bi, 0, "UInt")
    NumPut(1, bi, 12, "UShort")
    NumPut(0, bi, 16, "UInt")
    NumPut(bpp, bi, 14, "UShort")
    
    hbm := DllCall("CreateDIBSection"
    , "UPtr", hdc2
    , "UPtr", &bi
    , "UInt", 0
    , "UPtr*", ppvBits
    , "UPtr", 0
    , "UInt", 0, "UPtr")

    if !hdc
        ReleaseDC(hdc2)
    return hbm
}

;#####################################################################################

; Function:             CreateCompatibleDC
; Description:          This function creates a memory device context (DC) compatible with the specified device
CreateCompatibleDC(hdc:=0) {
    return DllCall("CreateCompatibleDC", "UPtr", hdc)
}

;#####################################################################################

; Function:             SelectObject
; Description:          The SelectObject function selects an object into the specified device context (DC). The new object replaces the previous object of the same type
SelectObject(hdc, hgdiobj) {
    return DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
}

;#####################################################################################

; Function:             DeleteObject
; Description:          This function deletes a logical pen, brush, font, bitmap, region, or palette, freeing all system resources associated with the object
DeleteObject(hObject) {
    return DllCall("DeleteObject", "UPtr", hObject)
}

;#####################################################################################

; Function:             GetDC
; Description:          This function retrieves a handle to a display device context (DC) for the client area of the specified window.
;                               The display device context can be used in subsequent graphics display interface (GDI) functions to draw in the client area of the window.
GetDC(hwnd:=0) {
    return DllCall("GetDC", "UPtr", hwnd)
}

;#####################################################################################

; Function:             ReleaseDC
; Description:          This function releases a device context (DC), freeing it for use by other applications. The effect of ReleaseDC depends on the type of device context
ReleaseDC(hdc, hwnd:=0) {
    return DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
}

;#####################################################################################

; Function:             DeleteDC
; Description:          The DeleteDC function deletes the specified device context (DC)
DeleteDC(hdc) {
    return DllCall("DeleteDC", "UPtr", hdc)
}

;#####################################################################################

; Function:             Gdip_BitmapFromHBITMAP
; Description:          Gets a pointer to a gdi+ bitmap from a GDI HBITMAP
Gdip_BitmapFromHBITMAP(hBitmap, Palette:=0) {
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPtr", hBitmap, "UPtr", Palette, "UPtr*", pBitmap)
    return pBitmap
}

;#####################################################################################

; Function:             Gdip_CreateBitmapFromFile
; Description:          Creates a bitmap from a file
Gdip_CreateBitmapFromFile(sFile) {
    DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", sFile, "UPtr*", pBitmap)
    return pBitmap
}

;#####################################################################################

; Function:             Gdip_DrawImage
; Description:          This function draws a bitmap onto a graphics
Gdip_DrawImage(pGraphics, pBitmap, dx:="", dy:="", dw:="", dh:="", sx:="", sy:="", sw:="", sh:="", Matrix:=1) {
    if (Matrix&1 = "")
        ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
    else if (Matrix != 1)
        ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
        
    if (sx = "") && (sy = "") && (sw = "") && (sh = "")
    {
        if (dx = "") && (dy = "") && (dw = "") && (dh = "")
        {
            sx := dx := 0, sy := dy := 0
            sw := dw := Gdip_GetImageWidth(pBitmap)
            sh := dh := Gdip_GetImageHeight(pBitmap)
        }
        else
        {
            sx := sy := 0
            sw := Gdip_GetImageWidth(pBitmap)
            sh := Gdip_GetImageHeight(pBitmap)
        }
    }
    
    E := DllCall("gdiplus\GdipDrawImageRectRect"
    , "UPtr", pGraphics
    , "UPtr", pBitmap
    , "Float", dx
    , "Float", dy
    , "Float", dw
    , "Float", dh
    , "Float", sx
    , "Float", sy
    , "Float", sw
    , "Float", sh
    , "Int", 2
    , "UPtr", ImageAttr
    , "UPtr", 0
    , "UPtr", 0)
    
    if ImageAttr
        Gdip_DisposeImageAttributes(ImageAttr)
    return E
}

;#####################################################################################

; Function:             Gdip_SetImageAttributesColorMatrix
; Description:          This function creates an image matrix ready for drawing
Gdip_SetImageAttributesColorMatrix(Matrix) {
    VarSetCapacity(ColourMatrix, 100, 0)
    Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
    StringSplit, Matrix, Matrix, |
    Loop, 25
    {
        M := (Matrix%A_Index% != "") ? Matrix%A_Index% : 0
        NumPut(M, ColourMatrix, (A_Index-1)*4, "Float")
    }
    DllCall("gdiplus\GdipCreateImageAttributes", "UPtr*", ImageAttr)
    DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "UPtr", ImageAttr, "Int", 1, "Int", 1, "UPtr", &ColourMatrix, "UPtr", 0, "Int", 0)
    return ImageAttr
}

;#####################################################################################

; Function:             Gdip_GraphicsFromHDC
; Description:          This function gets the graphics from the handle to a device context
Gdip_GraphicsFromHDC(hdc) {
    DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", pGraphics)
    return pGraphics
}

;#####################################################################################

; Function:             Gdip_GraphicsClear
; Description:          Clears the graphics of all shapes
Gdip_GraphicsClear(pGraphics, ARGB:=0x00ffffff) {
    return DllCall("gdiplus\GdipGraphicsClear", "UPtr", pGraphics, "Int", ARGB)
}

;#####################################################################################

; Function:             Gdip_DeleteGraphics
; Description:          This function deletes the graphics that was created
Gdip_DeleteGraphics(pGraphics) {
    return DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
}

;#####################################################################################

; Function:             Gdip_DisposeImage
; Description:          This function deletes a GDI+ image
Gdip_DisposeImage(pBitmap) {
    return DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
}

;#####################################################################################

; Function:             Gdip_GetImageWidth
; Description:          This function gets the width of a GDI+ image
Gdip_GetImageWidth(pBitmap) {
    DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "UInt*", Width)
    return Width
}

;#####################################################################################

; Function:             Gdip_GetImageHeight
; Description:          This function gets the height of a GDI+ image
Gdip_GetImageHeight(pBitmap) {
    DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "UInt*", Height)
    return Height
}

;#####################################################################################

; Function:             Gdip_DeleteBrush
; Description:          This function deletes a brush that was created
Gdip_DeleteBrush(pBrush) {
    return DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
}

;#####################################################################################

; Function:             Gdip_BrushCreateSolid
; Description:          Creates a solid brush using ARGB
Gdip_BrushCreateSolid(ARGB:=0xff000000) {
    DllCall("gdiplus\GdipCreateSolidFill", "Int", ARGB, "UPtr*", pBrush)
    return pBrush
}

;#####################################################################################

; Function:             Gdip_SetSmoothingMode
; Description:          Sets the smoothing mode of the graphics object
Gdip_SetSmoothingMode(pGraphics, SmoothingMode) {
    return DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", pGraphics, "Int", SmoothingMode)
}

;#####################################################################################

; Function:             Gdip_FillRoundedRectangle
; Description:          This function uses a brush to fill a rounded rectangle in the graphics of a bitmap
Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r) {
    Region := Gdip_GetClipRegion(pGraphics)
    Gdip_SetClipPath(pGraphics, Gdip_CreateRoundedRectanglePath(pGraphics, x, y, w, h, r))
    E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
    Gdip_SetClipRegion(pGraphics, Region, 0)
    Gdip_DeleteRegion(Region)
    return E
}

;#####################################################################################

; Function:             Gdip_CreateRoundedRectanglePath
; Description:          Creates a rounded rectangle path
Gdip_CreateRoundedRectanglePath(pGraphics, x, y, w, h, r) {
    pPath := Gdip_CreatePath()
    Gdip_AddPathArc(pPath, x, y, 2*r, 2*r, 180, 90)
    Gdip_AddPathArc(pPath, x+w-2*r, y, 2*r, 2*r, 270, 90)
    Gdip_AddPathArc(pPath, x+w-2*r, y+h-2*r, 2*r, 2*r, 0, 90)
    Gdip_AddPathArc(pPath, x, y+h-2*r, 2*r, 2*r, 90, 90)
    Gdip_ClosePathFigure(pPath)
    return pPath
}

;#####################################################################################

; Function:             Gdip_CreatePath
; Description:          Creates a new drawing path
Gdip_CreatePath(BrushMode:=0) {
    DllCall("gdiplus\GdipCreatePath", "Int", BrushMode, "UPtr*", pPath)
    return pPath
}

;#####################################################################################

; Function:             Gdip_AddPathArc
; Description:          Adds an arc to the current path
Gdip_AddPathArc(pPath, x, y, w, h, StartAngle, SweepAngle) {
    return DllCall("gdiplus\GdipAddPathArc", "UPtr", pPath, "Float", x, "Float", y, "Float", w, "Float", h, "Float", StartAngle, "Float", SweepAngle)
}

;#####################################################################################

; Function:             Gdip_ClosePathFigure
; Description:          Closes the current path figure
Gdip_ClosePathFigure(pPath) {
    return DllCall("gdiplus\GdipClosePathFigure", "UPtr", pPath)
}

;#####################################################################################

; Function:             Gdip_DeletePath
; Description:          Deletes a path
Gdip_DeletePath(pPath) {
    return DllCall("gdiplus\GdipDeletePath", "UPtr", pPath)
}

;#####################################################################################

; Function:             Gdip_SetClipPath
; Description:          Updates the clip region of the graphics object
Gdip_SetClipPath(pGraphics, pPath, CombineMode:=0) {
    return DllCall("gdiplus\GdipSetClipPath", "UPtr", pGraphics, "UPtr", pPath, "Int", CombineMode)
}

;#####################################################################################

; Function:             Gdip_GetClipRegion
; Description:          Gets the current clip region of the graphics object
Gdip_GetClipRegion(pGraphics) {
    Region := Gdip_CreateRegion()
    DllCall("gdiplus\GdipGetClip", "UPtr", pGraphics, "UPtr*", Region)
    return Region
}

;#####################################################################################

; Function:             Gdip_SetClipRegion
; Description:          Sets the clip region of the graphics object
Gdip_SetClipRegion(pGraphics, Region, CombineMode:=0) {
    return DllCall("gdiplus\GdipSetClipRegion", "UPtr", pGraphics, "UPtr", Region, "Int", CombineMode)
}

;#####################################################################################

; Function:             Gdip_CreateRegion
; Description:          Creates a new empty region
Gdip_CreateRegion() {
    DllCall("gdiplus\GdipCreateRegion", "UPtr*", Region)
    return Region
}

;#####################################################################################

; Function:             Gdip_DeleteRegion
; Description:          Deletes a region
Gdip_DeleteRegion(Region) {
    return DllCall("gdiplus\GdipDeleteRegion", "UPtr", Region)
}

;#####################################################################################

; Function:             Gdip_FillRectangle
; Description:          This function uses a brush to fill a rectangle in the graphics of a bitmap
Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h) {
    return DllCall("gdiplus\GdipFillRectangle", "UPtr", pGraphics, "UPtr", pBrush, "Float", x, "Float", y, "Float", w, "Float", h)
}

;#####################################################################################

; Function:             Gdip_Startup
; Description:          Initializes GDI+
Gdip_Startup() {
    if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
        DllCall("LoadLibrary", "str", "gdiplus")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", pToken, "UPtr", &si, "UPtr", 0)
    return pToken
}

;#####################################################################################

; Function:             Gdip_Shutdown
; Description:          Cleans up resources used by GDI+
Gdip_Shutdown(pToken) {
    DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
    if hModule := DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
        DllCall("FreeLibrary", "UPtr", hModule)
    return 0
}

;##################################################################################### 

; Function:             Gdip_DisposeImageAttributes
; Description:          This function disposes of GDI+ image attributes
Gdip_DisposeImageAttributes(ImageAttr) {
    return DllCall("gdiplus\GdipDisposeImageAttributes", "UPtr", ImageAttr)
}

;##################################################################################### 
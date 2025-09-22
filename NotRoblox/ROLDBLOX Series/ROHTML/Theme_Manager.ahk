#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

; --- Modern UI Theming ---
BackgroundColor := "2B2D30" ; A modern dark gray
TextColor := "CCCCCC"     ; A light gray for text
Gui, Color, %BackgroundColor%
Gui, Font, c%TextColor% s10, Segoe UI

; --- GUI Setup ---
; Left Pane
Gui, Add, ListBox, x20 y20 w200 h350 vThemeList gSelectTheme,
Gui, Add, Button, x20 y380 w200 h30 gRefreshThemes, Refresh List

; Right Pane
RightPaneX := 240
Gui, Add, Pic, x%RightPaneX% y20 w360 h202 vThumbnail, ; 16:9 aspect ratio

Gui, Font, s16 bold
Gui, Add, Text, x%RightPaneX% y235 w360 vThemeName, Theme Name

Gui, Font, s10
Gui, Add, Text, x%RightPaneX% y265, Made by:
Gui, Font, s10 italic
Gui, Add, Text, x%RightPaneX%+75 y265 w285 vThemeAuthor, Author

Gui, Font, s10
Gui, Add, Text, x%RightPaneX% y295, Description:
Gui, Add, Text, x%RightPaneX% y315 w360 h55 vThemeDescription +BackgroundTrans, A detailed description of the theme goes here and it can wrap to multiple lines if needed.

Gui, Add, Button, x520 y380 w80 h30 gApplyTheme, Apply

; --- Initial Scan ---
global themes := {}
global displayNameToFolderName := {}
ScanThemes()
Gui, Show, w620 h430, RoHTML Theme Manager
Return

; --- Functions and Subroutines ---

ScanThemes() {
    global
    themes := {}
    displayNameToFolderName := {}
    listContent := ""
    defaultThemeNameInList := ""

    ; --- 1. Process Default Theme First ---
    defaultThemeFolderName := "_RoHTML_Default"
    defaultThemeDir := A_ScriptDir . "\RoHTML\themes\" . defaultThemeFolderName
    defaultThumb := defaultThemeDir . "\Thumbnail.png"
    defaultIni := defaultThemeDir . "\theme.ini"

    if (FileExist(defaultThumb) && FileExist(defaultIni))
    {
        FileRead, iniContent, %defaultIni%
        IniRead, name, %defaultIni%, Theme, Name, %defaultThemeFolderName%
        IniRead, author, %defaultIni%, Theme, Author, Unknown
        
        desc := "No description."
        descPos := InStr(iniContent, "Description=")
        if (descPos > 0)
        {
            desc := Trim(SubStr(iniContent, descPos + 12))
        }

        themes[defaultThemeFolderName] := { "name": name, "author": author, "desc": desc, "path": defaultThemeDir }
        displayNameToFolderName[name] := defaultThemeFolderName
        listContent .= name . "|"
        defaultThemeNameInList := name
    }

    ; --- 2. Process Other Themes ---
    Loop, Files, RoHTML\themes\*, D
    {
        folderName := A_LoopFileName
        if (folderName == defaultThemeFolderName)
            continue ; Skip the default theme, it's already added

        themeDir := A_LoopFileFullPath
        thumb := themeDir . "\Thumbnail.png"
        ini := themeDir . "\theme.ini"
        
        if (FileExist(thumb) && FileExist(ini))
        {
            FileRead, iniContent, %ini%
            IniRead, name, %ini%, Theme, Name, %folderName%
            IniRead, author, %ini%, Theme, Author, Unknown
            
            desc := "No description."
            descPos := InStr(iniContent, "Description=")
            if (descPos > 0)
            {
                desc := Trim(SubStr(iniContent, descPos + 12))
            }

            themes[folderName] := { "name": name, "author": author, "desc": desc, "path": themeDir }
            displayNameToFolderName[name] := folderName
            listContent .= name . "|"
        }
    }
    listContent := RTrim(listContent, "|")
    GuiControl,, ThemeList, % "|" . listContent

    if (defaultThemeNameInList != "")
        GuiControl, Choose, ThemeList, %defaultThemeNameInList%
    else
        GuiControl, Choose, ThemeList, 1
        
    GoSub, SelectTheme
}

RefreshThemes:
    ScanThemes()
Return

SelectTheme:
    Gui, Submit, NoHide
    GuiControlGet, selectedDisplayName, , ThemeList
    
    folderName := displayNameToFolderName[selectedDisplayName]

    if (themes.HasKey(folderName))
    {
        theme := themes[folderName]

        Gui, Font, s16 bold
        GuiControl,, ThemeName, % theme.name

        Gui, Font, s10 italic
        GuiControl,, ThemeAuthor, % theme.author

        Gui, Font, s10
        GuiControl,, ThemeDescription, % theme.desc
        
        imgPath := theme.path . "\Thumbnail.png"
        GuiControl,, Thumbnail, *w360 *h202 %imgPath%
    }
    return

ApplyTheme:
    Gui, Submit, NoHide
    GuiControlGet, selectedDisplayName, , ThemeList

    folderName := displayNameToFolderName[selectedDisplayName]

    if (!themes.HasKey(folderName)) {
        MsgBox, 48, Error, Please select a valid theme from the list.
        return
    }

    selectedTheme := themes[folderName]
    
    themeDisplayName := selectedTheme.name
    MsgBox, 36, Confirm, Applying theme: %themeDisplayName%`nThis will overwrite existing content files. Continue?
    IfMsgBox, No
        return

    ; --- Create and Show Progress Window ---
    Gui, 2: +Owner1
    Gui, 2: Color, 2B2D30
    Gui, 2: Font, cCCCCCC s12, Segoe UI
    Gui, 2: Add, Text, x20 y20 w260 h30 Center, Applying Theme...
    Gui, 2: Font, s10
    Gui, 2: Add, Text, x20 y60 w260 h20 Center vStatusText, Initializing...
    Gui, 2: Show, w300 h100, Applying Theme

    ; Apply default theme first, if it exists and is not the selected one
    if (folderName != "_RoHTML_Default" && themes.HasKey("_RoHTML_Default")) {
        GuiControl, 2:, StatusText, Applying base theme: _RoHTML_Default
        ApplyThemeFiles(themes["_RoHTML_Default"].path)
    }

    ; Apply selected theme
    GuiControl, 2:, StatusText, Applying theme: %themeDisplayName%
    ApplyThemeFiles(selectedTheme.path)

    Gui, 2:Destroy

    themeDisplayName := selectedTheme.name
    MsgBox, 64, Success, Theme '%themeDisplayName%' applied successfully!
    return

ApplyThemeFiles(themePath) {
    sourceDir := themePath . "\content"
    destDir := A_ScriptDir . "\RoHTML\content"
    
    if (!FileExist(sourceDir)) {
        return ; No content to apply for this theme
    }

    Loop, Files, %sourceDir%\*.*, R
    {
        relativePath := SubStr(A_LoopFileFullPath, StrLen(sourceDir) + 2)
        destFile := destDir . "\" . relativePath
        SplitPath, destFile, , OutDir
        FileCreateDir, %OutDir%
        FileCopy, %A_LoopFileFullPath%, %destFile%, 1
    }
}

GuiClose:
ExitApp
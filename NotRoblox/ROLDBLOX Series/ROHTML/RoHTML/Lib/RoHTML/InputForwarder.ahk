#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn VarUnset, Off
ProcessSetPriority("High")
A_BatchLines := -1  ; Set script speed to maximum
Critical("On")

; --- Pre-allocated buffers for maximum performance ---
global dataBuf := Buffer(8192)    ; Larger buffer for batch operations
global cds := Buffer(A_PtrSize * 3)
global ptBuf := Buffer(16)        ; Increased for better alignment
global inputQueue := []           ; Queue for all input events
global MAX_QUEUE_SIZE := 128      ; Increased queue size
global lastProcessTime := 0       ; Last time we processed the queue
global QUEUE_PROCESS_INTERVAL := 1 ; Process queue every 1ms
global dataBuf := Buffer(4096)    ; Increased buffer size for better reliability
global cds := Buffer(A_PtrSize * 3)
global ptBuf := Buffer(8)
global inputQueue := []           ; Queue for all input events
global MAX_QUEUE_SIZE := 128      ; Increased queue size
global lastProcessTime := 0       ; Last time we processed the queue
global QUEUE_PROCESS_INTERVAL := 1 ; Process queue every 1ms#Warn VarUnset, Off

;
; InputForwarder.ahk  —  ULTRA-OPTIMIZED input forwarding for minimal latency
;
; Usage:  InputForwarder.ahk <TargetHwnd>
;         Optimized for zero-latency input forwarding to WebView overlay
;

; --- Validate CLI parameter --------------------------------------------------
if A_Args.Length < 1 {
    MsgBox "InputForwarder: Missing target HWND parameter.", "Error", 48
    ExitApp
}
try TargetHwnd := Integer(A_Args[1])
catch {
    MsgBox "InputForwarder: Invalid target HWND parameter (" A_Args[1] ").", "Error", 48
    ExitApp
}

; Find the Roblox window
global RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
if !RobloxHwnd {
    MsgBox "InputForwarder: Could not find an active Roblox window (RobloxPlayerBeta.exe).", "Error", 48
    ExitApp
}

; Check that the target window exists
if !WinExist("ahk_id " TargetHwnd) {
    MsgBox "InputForwarder: Target window does not exist (" TargetHwnd ").", "Error", 48
    ExitApp
}

; --- ULTRA-OPTIMIZED PERFORMANCE SETTINGS ---
global LastMouseX := 0
global LastMouseY := 0
global LastClientX := 0
global LastClientY := 0
global heldButton := ""

; --- Pre-allocated buffers for maximum performance ---
global dataBuf := Buffer(4096)    ; Increased buffer size for better reliability
global cds := Buffer(A_PtrSize * 3)
global ptBuf := Buffer(8)
global keyEventQueue := []
global MAX_QUEUE_SIZE := 32

; --- Ultra-optimized message queue system ---
QueueMessage(str) {
    global inputQueue, MAX_QUEUE_SIZE
    if (inputQueue.Length < MAX_QUEUE_SIZE)
        inputQueue.Push(str)
    ProcessQueue()  ; Try to process immediately
}

; --- Ultra-fast message sending with zero-copy optimization and queuing ---
SendMessageDirect(str) {
    global dataBuf, cds, TargetHwnd, lastProcessTime, QUEUE_PROCESS_INTERVAL
    static lastStr := "", lastSize := 0, lastBufPtr := 0
    
    ; Check if this is a macro message
    if (InStr(str, "macros;") = 1) {
        ForwardToRobloxMacros(str)
        return true
    }
    
    ; Fast path for repeated messages (like held keys)
    if (str == lastStr && dataBuf.Ptr == lastBufPtr) {
        DllCall("SendMessage", "Ptr", TargetHwnd, "UInt", 0x4A, "Ptr", 0, "Ptr", cds)
        return true
    }
    
    ; Get required size and resize buffer if needed
    size := StrPut(str, "UTF-8")
    if (size > dataBuf.Size)
        dataBuf := Buffer(size + 64)  ; Small padding for efficiency
    
    ; Direct string write - no buffer clearing needed
    StrPut(str, dataBuf, "UTF-8")
    
    ; Update COPYDATASTRUCT (only if size changed)
    if (size != lastSize || dataBuf.Ptr != lastBufPtr) {
        NumPut("Ptr", 0, cds, 0)             ; dwData
        NumPut("UInt", size, cds, A_PtrSize) ; cbData
        NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize*2)  ; lpData
        lastSize := size
        lastBufPtr := dataBuf.Ptr
    }
    
    lastStr := str
    return DllCall("SendMessage", "Ptr", TargetHwnd, "UInt", 0x4A, "Ptr", 0, "Ptr", cds)
}

; --- Queue processor ---
ProcessQueue() {
    global inputQueue, lastProcessTime, QUEUE_PROCESS_INTERVAL
    currentTime := A_TickCount
    
    ; Only process if enough time has passed
    if (currentTime - lastProcessTime < QUEUE_PROCESS_INTERVAL)
        return
    
    ; Process all queued messages
    while (inputQueue.Length > 0) {
        str := inputQueue.RemoveAt(1)
        SendMessageDirect(str)
    }
    
    lastProcessTime := currentTime
}

; Set up queue processor timer
SetTimer(ProcessQueue, 1)  ; Check queue every 1ms

; --- Optimized coordinate conversion (cached) ---
ScreenToClientOptimized(hwnd, x, y) {
    global ptBuf
    NumPut("Int", x, ptBuf, 0)
    NumPut("Int", y, ptBuf, 4)
    DllCall("ScreenToClient", "Ptr", hwnd, "Ptr", ptBuf)
    return [NumGet(ptBuf, 0, "Int"), NumGet(ptBuf, 4, "Int")]
}
; --- Low-level keyboard hook (optimized) ---
keyboardCallback := CallbackCreate(KeyboardProc, "Fast")
keyboardHook := DllCall("SetWindowsHookEx", "Int", 13, "Ptr", keyboardCallback,
    "Ptr", 0, "UInt", 0, "Ptr") ; WH_KEYBOARD_LL = 13, global

KeyboardProc(nCode, wParam, lParam) {
    global TargetHwnd, RobloxHwnd
    if (nCode >= 0 and WinActive("ahk_id " RobloxHwnd)) {
        static WM_KEYDOWN := 0x100, WM_KEYUP := 0x101, WM_SYSKEYDOWN := 0x104, WM_SYSKEYUP := 0x105
        
        ; Handle all key events more comprehensively
        if (wParam = WM_KEYDOWN || wParam = WM_SYSKEYDOWN) {
            vk := NumGet(lParam, 0, "UInt") & 0xFF
            scanCode := (NumGet(lParam, 0, "UInt") >> 16) & 0xFF
            extended := (NumGet(lParam, 0, "UInt") >> 24) & 0x1
            
            ; Get key name with better fallback handling
            keyName := GetKeyName("vk" Format("{:02X}", vk))
            if !keyName {
                ; Fallback for keys that might not have names
                keyName := GetKeyName("sc" Format("{:02X}", scanCode))
            }
            if !keyName {
                ; Ultimate fallback - use virtual key code
                keyName := "vk" Format("{:02X}", vk)
            }
            
            ; Queue the key event
            QueueMessage("key;down;" keyName)
            
        } else if (wParam = WM_KEYUP || wParam = WM_SYSKEYUP) {
            vk := NumGet(lParam, 0, "UInt") & 0xFF
            scanCode := (NumGet(lParam, 0, "UInt") >> 16) & 0xFF
            extended := (NumGet(lParam, 0, "UInt") >> 24) & 0x1
            
            ; Get key name with better fallback handling
            keyName := GetKeyName("vk" Format("{:02X}", vk))
            if !keyName {
                ; Fallback for keys that might not have names
                keyName := GetKeyName("sc" Format("{:02X}", scanCode))
            }
            if !keyName {
                ; Ultimate fallback - use virtual key code
                keyName := "vk" Format("{:02X}", vk)
            }
            
            ; Queue the key event
            QueueMessage("key;up;" keyName)
        }
    }
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; --- Low-level mouse hook (ultra-optimized) ---
mouseCallback := CallbackCreate(MouseProc, "Fast")
mouseHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", mouseCallback,
    "Ptr", 0, "UInt", 0, "Ptr") ; WH_MOUSE_LL = 14

MouseProc(nCode, wParam, lParam) {
    global TargetHwnd, RobloxHwnd, LastMouseX, LastMouseY, LastClientX, LastClientY, heldButton
    
    if (nCode >= 0 and WinActive("ahk_id " RobloxHwnd)) {
        static WM_MOUSEMOVE := 0x200, WM_LBUTTONDOWN := 0x201, WM_LBUTTONUP := 0x202,
              WM_RBUTTONDOWN := 0x204, WM_RBUTTONUP := 0x205, WM_MBUTTONDOWN := 0x207,
              WM_MBUTTONUP := 0x208, WM_MOUSEWHEEL := 0x20A

        x := NumGet(lParam, 0, "Int")
        y := NumGet(lParam, 4, "Int")
        
        ; Handle mouse wheel immediately (no coordinate conversion needed)
        if (wParam = WM_MOUSEWHEEL) {
            delta := wParam >> 16
            QueueMessage("mouse;wheel;" delta ";" x ";" y)
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        }
        
        ; Handle mouse movement with smart caching
        if (wParam = WM_MOUSEMOVE) {
            ; Only process if position changed significantly (reduces noise)
            if (Abs(x - LastMouseX) > 0 || Abs(y - LastMouseY) > 0) {
                LastMouseX := x
                LastMouseY := y
                coords := ScreenToClientOptimized(TargetHwnd, x, y)
                LastClientX := coords[1]
                LastClientY := coords[2]
                QueueMessage("mouse;move;" heldButton ";" LastClientX ";" LastClientY)
            }
        } else {
            ; Handle button events with immediate coordinate conversion
            coords := ScreenToClientOptimized(TargetHwnd, x, y)
            cx := coords[1]
            cy := coords[2]
            
            if (wParam = WM_LBUTTONDOWN) {
                heldButton := "left"
                QueueMessage("mouse;down;left;" cx ";" cy)
            } else if (wParam = WM_LBUTTONUP) {
                heldButton := ""
                QueueMessage("mouse;up;left;" cx ";" cy)
            } else if (wParam = WM_RBUTTONDOWN) {
                heldButton := "right"
                QueueMessage("mouse;down;right;" cx ";" cy)
            } else if (wParam = WM_RBUTTONUP) {
                heldButton := ""
                QueueMessage("mouse;up;right;" cx ";" cy)
            } else if (wParam = WM_MBUTTONDOWN) {
                heldButton := "middle"
                QueueMessage("mouse;down;middle;" cx ";" cy)
            } else if (wParam = WM_MBUTTONUP) {
                heldButton := ""
                QueueMessage("mouse;up;middle;" cx ";" cy)
            }
        }
    }
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; --- Watch for target destruction (reduced frequency) ---
SetTimer(WatchTarget, 2000)  ; Check every 2 seconds instead of 1
WatchTarget() {
    global TargetHwnd
    if !WinExist("ahk_id " TargetHwnd) {
        ExitApp
    }
}

; --- Forward messages to Roblox_Macros.ahk ---
ForwardToRobloxMacros(str) {
    static robloxMacrosHwnd := 0
    
    ; Find the Roblox_Macros window if we haven't already
    if (!robloxMacrosHwnd) {
        robloxMacrosHwnd := WinExist("ahk_class AutoHotkey ahk_pid " ProcessExist("Roblox_Macros.ahk"))
        if (!robloxMacrosHwnd)
            return
    }
    
    if (robloxMacrosHwnd) {
        ; Set up COPYDATASTRUCT for the macro
        size := StrPut(str, "UTF-8")
        if (size > dataBuf.Size)
            dataBuf := Buffer(size + 64)
        
        StrPut(str, dataBuf, "UTF-8")
        NumPut("Ptr", 0, cds, 0)
        NumPut("UInt", size, cds, A_PtrSize)
        NumPut("Ptr", dataBuf.Ptr, cds, A_PtrSize*2)
        
        DllCall("SendMessage", "Ptr", robloxMacrosHwnd, "UInt", 0x4A, "Ptr", 0, "Ptr", cds)
    }
}

; --- Cleanup ---
OnExit(Cleanup)
Cleanup(exitReason, exitCode) {
    global keyboardHook, keyboardCallback, mouseHook, mouseCallback
    if (keyboardHook)
        DllCall("UnhookWindowsHookEx", "Ptr", keyboardHook), keyboardHook := 0
    if (mouseHook)
        DllCall("UnhookWindowsHookEx", "Ptr", mouseHook),   mouseHook := 0
    if (keyboardCallback)
        CallbackFree(keyboardCallback), keyboardCallback := 0
    if (mouseCallback)
        CallbackFree(mouseCallback),   mouseCallback := 0
}

Persistent()
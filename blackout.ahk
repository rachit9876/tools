; ============================================================
;  BLACKOUT — Alt+L = black screen | Alt+U = unlock
;  Looks like monitor is off. PC keeps running in background.
;  Run as Administrator
; ============================================================

#SingleInstance Force
#Persistent
#InstallKeybdHook
#InstallMouseHook
#UseHook
#NoTrayIcon

global IsLocked := false

if !A_IsAdmin
{
    MsgBox, 16, Error, Run as Administrator.
    ExitApp
}

; Prevent sleep/screensaver so background work keeps running
DllCall("SetThreadExecutionState", "UInt", 0x80000003)  ; ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED

return

; =====================================================================
;  LOCK — Alt+L
; =====================================================================
!l::
    if IsLocked
        return
    IsLocked := true

    CoordMode, Mouse, Screen
    MouseGetPos, xpos, ypos
    SetTimer, LockMousePos, 10

    ; Suppress common escape routes
    Hotkey, #l, DoNothing, On
    Hotkey, ^Escape, DoNothing, On
    Hotkey, !F4, DoNothing, On
    Hotkey, !Tab, DoNothing, On
    Hotkey, #Tab, DoNothing, On
    Hotkey, #d, DoNothing, On

    ; Pure black fullscreen — no text, no title, nothing
    SysGet, ScreenW, 78
    SysGet, ScreenH, 79

    Gui, Black:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, Black:Color, 000000
    Gui, Black:Show, x0 y0 w%ScreenW% h%ScreenH% NoActivate

    ; Hide cursor
    Hotkey, ~LButton, DoNothing, On
    Hotkey, ~RButton, DoNothing, On

    BlockInput, On
return

; =====================================================================
;  UNLOCK — Alt+U
; =====================================================================
!u::
    if !IsLocked
        return
    IsLocked := false

    Gui, Black:Destroy

    SetTimer, LockMousePos, Off
    BlockInput, Off

    ; Restore suppressed hotkeys
    Hotkey, #l, DoNothing, Off
    Hotkey, ^Escape, DoNothing, Off
    Hotkey, !F4, DoNothing, Off
    Hotkey, !Tab, DoNothing, Off
    Hotkey, #Tab, DoNothing, Off
    Hotkey, #d, DoNothing, Off
    Hotkey, ~LButton, DoNothing, Off
    Hotkey, ~RButton, DoNothing, Off
return

; =====================================================================
;  MOUSE FREEZE
; =====================================================================
LockMousePos:
    MouseMove, %xpos%, %ypos%, 0
return

; =====================================================================
;  NOOP
; =====================================================================
DoNothing:
return

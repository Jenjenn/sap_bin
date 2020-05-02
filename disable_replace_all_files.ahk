/*
	We must destroy and burn the "Replace All in All &Opened Documents" button in Notepad++
*/

;Control, Disable,, Replace All in All Opened Doc&uments, ahk_exe notepad++.exe
;Control, Disable,, Find All in All &Opened Documents, ahk_exe notepad++.exe

ControlSetEnabled("Off", "Replace All in All Opened Doc&uments", "ahk_exe notepad++.exe")
ControlSetEnabled("Off", "Find All in All &Opened Documents", "ahk_exe notepad++.exe")

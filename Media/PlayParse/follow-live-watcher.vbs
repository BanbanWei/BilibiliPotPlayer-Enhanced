' follow-live-watcher.vbs - hidden launcher for follow-live-watcher.ps1
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
ps1 = fso.GetParentFolderName(WScript.ScriptFullName) & "\follow-live-watcher.ps1"
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """", 0, False

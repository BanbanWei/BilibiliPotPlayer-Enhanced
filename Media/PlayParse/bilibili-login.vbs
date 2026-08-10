' bilibili-login.vbs - hidden launcher for update-bilibili-cookie.ps1
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
ps1 = fso.GetParentFolderName(WScript.ScriptFullName) & "\update-bilibili-cookie.ps1"
sh.Run "powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """ -AutoRestart", 0, False

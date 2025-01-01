' Set WshShell = CreateObject("WScript.Shell")
' WshShell.Run """F:\Downloads\Merge_Masters_1\bin\Battler.exe""", 0
Set objShell = WScript.CreateObject("WScript.Shell")
objShell.Run "cmd /c F:\Downloads\Merge_Masters_1\bin\Battler.exe", 0, True

:: https://learn.microsoft.com/en-us/archive/blogs/yongrhee/wmi-stop-hurting-yourself-by-using-for-f-s-in-dir-s-b-mof-mfl-do-mofcomp-s
@echo off
sc config winmgmt start=disabled
net stop winmgmt /y
%systemdrive%
cd %windir%\system32\wbem
for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
wmiprvse /regserver
winmgmt /regserver
sc config winmgmt start=Auto
net start winmgmt
dir /b *.mof *.mfl | findstr /v /i uninstall > moflist.txt & for /F %%s in (moflist.txt) do mofcomp %%s
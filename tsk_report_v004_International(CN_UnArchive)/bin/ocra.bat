@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"ruby.exe" "C:/Users/GL121/Documents/GitHub/tsk_report/tsk_report_v004_International(CN_UnArchive)/rubyEnv/ruby-1.9.3-p551-i386-mingw32/bin/ocra" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"ruby.exe" "%~dpn0" %*

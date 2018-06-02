@echo off
c:\masm32\bin\ml /c /Zd /coff projet.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE projet.obj
c:\masm32\bin\ml /c /Zd /coff copi.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE copi.obj
pause
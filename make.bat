del GMThreads.dll

set MASMPATH=C:\masm32

%MASMPATH%\bin\rc /v resources.rc
%MASMPATH%\bin\cvtres /machine:ix86 resources.res
%MASMPATH%\bin\ml /c /coff /Cp /I%MASMPATH%\Include "main.asm"
%MASMPATH%\bin\link /DLL /section:.text,rwe /merge:.data=.text /merge:.rdata=.text /def:exports.def /libpath:%MASMPATH%\lib main.obj resources.obj /out:GMThreads.dll

del GMThreads.exp
del GMThreads.lib
del *.obj
del resources.res

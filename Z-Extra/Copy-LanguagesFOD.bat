@ECHO OFF

IF [%1]==[] GOTO INST
IF [%2]==[] GOTO INST
IF NOT EXIST "%1:\FoDMetadata_Client.cab" GOTO :EOF
IF [%2]==[1903] GOTO CONT
IF [%2]==[1909] GOTO CONT
IF [%2]==[2004] GOTO CONT
GOTO :EOF

:CONT

:: Copiar las FOD (Feature On Demand) relacionadas con los LP [Basic, Handwriting, OCR, etc.]
:: ISO FOD 1903: SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso
:: ISO FOD 1909: SW_DVD9_NTRL_Win_10_1903_64Bit_MultiLang_FOD_1_X22-01658.iso
:: ISO FOD 2004: SW_DVD9_NTRL_Win_10_2004_64Bit_MultiLang_FOD_1_X22-21311.iso

mkdir "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 FOD x64"
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 FOD x64" *languagefeatures*es-es* /xf *x86* *arm64* /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 FOD x64" *languagefeatures*en-us* /xf *x86* *arm64* /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 FOD x64" *languagefeatures*ca-es* /xf *x86* *arm64* /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 FOD x64" *languagefeatures*fr-fr* /xf *x86* *arm64* /s
goto :eof

:INST
ECHO %0 {Letra} {Version}

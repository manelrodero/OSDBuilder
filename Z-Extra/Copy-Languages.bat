@ECHO OFF

IF [%1]==[] GOTO INST
IF [%2]==[] GOTO INST
IF NOT EXIST "%1:\LocalExperiencePack" GOTO :EOF
IF [%2]==[1903] GOTO CONT
IF [%2]==[1909] GOTO CONT
IF [%2]==[2004] GOTO CONT
GOTO :EOF

:CONT

:: Copiar los LP (Language Packs)
:: ISO LP 1903: SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso
:: ISO LP 1909: SW_DVD9_NTRL_Win_10_1903_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-01656.iso
:: ISO LP 2004: SW_DVD9_NTRL_Win_10_2004_32_64_ARM64_MultiLang_LangPackAll_LIP_X22-21307.iso

mkdir "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language"
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language" *es-es.* /xd arm64 x86 /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language" *en-us.* /xd arm64 x86 /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language" *ca-es.* /xd arm64 x86 /s
robocopy %1:\ "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language" *fr-fr.* /xd arm64 x86 /s
xcopy "%1:\Windows Preinstallation Environment\x64\WinPE_OCs\WinPE-Speech-TTS.cab" "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\Windows Preinstallation Environment\x64\WinPE_OCs" /y
xcopy "%1:\Windows Preinstallation Environment\x64\WinPE_OCs\es-es\lp.cab" "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\Windows Preinstallation Environment\x64\WinPE_OCs\es-es" /y
xcopy "%1:\Windows Preinstallation Environment\x64\WinPE_OCs\en-us\lp.cab" "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\Windows Preinstallation Environment\x64\WinPE_OCs\en-us" /y
xcopy "%1:\Windows Preinstallation Environment\x64\WinPE_OCs\fr-fr\lp.cab" "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\Windows Preinstallation Environment\x64\WinPE_OCs\fr-fr" /y
xcopy %1:\LocalExperiencePack\es-es\License.xml "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\LocalExperiencePack\es-es" /y
xcopy %1:\LocalExperiencePack\en-us\License.xml "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\LocalExperiencePack\en-us" /y
xcopy %1:\LocalExperiencePack\ca-es\License.xml "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\LocalExperiencePack\ca-es" /y
xcopy %1:\LocalExperiencePack\fr-fr\License.xml "V:\OSDBuilder\Share\Content\IsoExtract\Windows 10 %2 Language\LocalExperiencePack\fr-fr" /y
goto :eof

:INST
ECHO %0 {Letra} {Version}

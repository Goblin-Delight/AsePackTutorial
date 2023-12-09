@echo off
setlocal enabledelayedexpansion

set "ParentPath=..\ArtStaging\Ases"

call "copyases.bat"

for /D %%D in ("%ParentPath%\*") do (
    set "_subdirectory=%%~nxD"

    for %%i in ("%%D\*.ase") do (
        set "UserInputPath=%%~ni"
        call "deleteold.bat" !_subdirectory! !UserInputPath!
    )
)

for /R "%ParentPath%" %%D in (.) do (
    if EXIST "%%D" (
        set "_subdirectory=%%~nxD"
        pushd "%%D"
        
        cd ..
        for %%x in (!CD!) do set "ParentDirName=%%~nxx"
        
        popd 
        @ECHO dir is %%D
        @ECHO parent dir is !ParentDirName!

        if not "!ParentDirName!"=="Ases" (
            for %%i in ("%%D\*.ase") do (
                set "UserInputPath=%%~ni"
                set "Combined=!ParentDirName!/!_subdirectory!"
                @echo trying to save !Combined!
                call "save.bat" !Combined! "%%i" !UserInputPath!
                call "pack.bat" !Combined! !UserInputPath!
            )
        ) 

        if "!ParentDirName!"=="Ases" (
            for %%i in ("%%D\*.ase") do (
                set "UserInputPath=%%~ni"
                @echo trying to save %%i
                call "save.bat" !_subdirectory! "%%i" !UserInputPath!
                call "pack.bat" !_subdirectory! !UserInputPath!
            )
        )
    )
)
pause
endlocal
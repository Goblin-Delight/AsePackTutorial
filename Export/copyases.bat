@ECHO OFF
setlocal enabledelayedexpansion

set "ParentPath=..\ArtStaging\Ases"
set "DestinationPath=AnimationArchive\Ases"

for /D %%D in ("%ParentPath%\*") do (
    set "_subdirectory=%%~nxD"
    set "_destinationPath=%DestinationPath%\!_subdirectory!"
    
    ECHO Copying from "%%D" to "!_destinationPath!"
    
    ROBOCOPY "%%D" "!_destinationPath!" *.ase /E
)

ECHO Copying root .ase files to "%DestinationPath%"
ROBOCOPY "%ParentPath%" "%DestinationPath%" *.ase

pause
endlocal
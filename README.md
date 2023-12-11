# AsePackBatchTutorial
this tutorial will explain how you can pack Aseprite animations into texture sheets and datafiles, ready for easy import into Unreal Engine

I’m licensing this tutorial under the MIT license – use it and the provided scripts however you want! You can even use Mr Acrobat (aka John Smith) in your own projects, but I don't know why you'd do something like that. 

Credit not required but is appreciated.

**NOTE**: My files and folders have kind of long names in this example, so if you're not keeping your project at the root of your hard drive, you might need to think about truncating or just making smaller names to avoid Windows MAX_PATH length limit (256 chars).

if you're interested in checking out my work, my current upcoming game is [yumyum.cool](https://yumyum.cool), and you can check out my studio at [goblindelight.com](https://goblindelight.com)

# Intro
This is specifically targeted for Aseprite users, and also makes use of a great tool called [TexturePacker](https://www.codeandweb.com/texturepacker) by CodeAndWeb. Andreas from CodeAndWeb always helps me out when I email them, and the software itself is awesome imo.

## Filesystem Structure
First, a little context for the file structure. `ArtStaging` and `Export` are folders that live in my Unreal project, parallel to `Content` (not inside it).

Inside `ArtStaging`, I have various folders where I keep my source files, organized by file type. The only relevant one here is going to be my `Ases` folder. 

This `Ases` folder contains the most up-to-date source files for all of my animated sprites.

In the `Ases` folder, based on the way I wrote the scripts, I’m able to have up to 2 additional levels of organization below the `Ases` folder. 

For example:
- `Ases/Characters` is OKAY 
- `Ases/Characters/PlayerCharacters` or `Ases/Characters/NPCs` is OKAY
- `Ases/Characters/PlayerCharacters/JohnSmith/` is **NOT OKAY**.

If someone can help me improve the script to allow for unlimited depth below the root, that would be sick, but it’s not really required.

I have another folder inside my project called `Export` - this is where the packed sprites will land after we run the script and also where all the scripts live, as well:

![export folder](https://github.com/scalliondelight/AsePackBatchTutorial/assets/52948136/0f274137-af26-4c80-85fa-f8d316426775)

The full structure for the top-level of the project looks like this:

![project-root](https://github.com/scalliondelight/AsePackBatchTutorial/assets/52948136/70a5f402-a265-4945-975c-492dede3d6a1)

## .ase File Structure & Tagging
Inside a given Aseprite file, each animation is broken up by a tag. As an example, you can see my animation structure here:

![ase structure example](https://github.com/scalliondelight/AsePackBatchTutorial/assets/52948136/f8dd27f0-23b5-4cb0-948d-657ce3fb3d02)

# Scripts Overview
So basically, everything kicks off from the `export.bat` script. This is the file you actually click on to extract and pack your animations – the other scripts are all just helpers called by `export.bat` or other helpers. 

What `export.bat` does, at a high level: it looks inside `ArtStaging/Ases` for the source files and copies them to another staging folder, extracts the frames from the `.ase` files it finds, via the Aseprite CLI, then packs them into textures via the TexturePacker CLI. 

I’m going to highlight a few key points from each script. 

At the top of `export.bat` we have:
`set "ParentPath=..\ArtStaging\Ases"`

This line defines where we should be looking for the source files. `..\` means to go out of the directory that we’re running the file in (in my case `Export`), and then access `ArtStaging` in the folder above and the `Ases` subdirectory under that.

## copyases.bat overview
We don't want to fuck up the source files in any way, so to make the script a bit safer, I do a `ROBOCOPY` to a different `Ases` folder, this one living in `Export/`. The `Export/Ases` folder should never be touched except for troubleshooting -- again, your source files live in `ArtStaging/Ases` instead. This also has the benefit of leaving `.ase` files in `Export/Ases` that might get removed for whatever reason from `ArtStaging/Ases`, which could be useful if you have packed sheets in `Export/Packed` but can’t find sources in `ArtStaging/Ases` anymore.

### Path Parameters
```
set "ParentPath=..\ArtStaging\Ases"
set "DestinationPath=AnimationArchive\Ases"
```
`ParentPath` needs to be the same as ParentPath defined in export.bat.
`DestinationPath` is the folder where Ase files will land when copied. `Export/AnimationArchive` needs to exist in your filesystem before the script will work.

This section in `copyases.bat` handles subdirectories:
```
for /D %%D in ("%ParentPath%\*") do (
    set "_subdirectory=%%~nxD"
    set "_destinationPath=%DestinationPath%\!_subdirectory!"
    
    ECHO Copying from "%%D" to "!_destinationPath!"
    
    ROBOCOPY "%%D" "!_destinationPath!" *.ase /E
)
```
And this handles ase files that are just sitting in the `ArtStaging/Ases` root folder:
```
ECHO Copying root .ase files to "%DestinationPath%"
ROBOCOPY "%ParentPath%" "%DestinationPath%" *.ase
```

## Back in export.bat:
Next, we're using the filename without an extension as the `UserInputPath`. So if your source file is `ArtStaging/Ases/Characters/JohnSmithAnimations.ase`, the `UserInputPath` will end up being `JohnSmithAnimations`. 

## deleteold.bat overview
Now, before we do anything else, we're gonna wipe out all the old individual frame exports from `Export/Frames` to make sure we're always using only the most up-to-date frames. This is located in the `deleteold.bat` script:

`FOR /d /r . %%d IN (%2) DO @IF EXIST "%%d" rd /s /q "%%d"`

Here, we're recursing into subfolders to find any folders that have the name of the `.ase` file (i.e. the `UserInputPath`), and we delete them one by one.

## save.bat overview
Next, is `save.bat` -- this is the batch file that interacts with Aseprite. 
```
@set ASEPRITE="C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"
%ASEPRITE% -b %2 --save-as AnimationArchive\Frames\%1\%3\%3{tag}\{frame01}.png
```
Here we're telling it to start the Aseprite CLI, exporting individual frames to `Export\AnimationArchive\Frames\[ParentDirName]\[_subdirectory]\[UserInputPath]\UserInputPath+tag\01.png, etc.`

- `ParentDirName` would be equivalent to `Ases/Characters` in my example (without `Ases`)
- `_subdirectory` is equivalent to `Ases/Characters/PlayerCharacters` (without `Ases/Characters`)
- `UserInputPath` is the actual filename of the .ase file, so in other words, the destination for frames is going to be `Export/Frames/Characters/PlayerCharacters/filename/filename+Tag/`. 

This gives us a dump of every frame in the file, organized by its tag. I append the filename to all of the animation names, because I have many characters that have idles, and Unreal will complain if we call them all Idle -- and ultimately, it's just easier to search for later. So consider this, if we have `ArtStaging/Ases/Characters/JohnSmithAnimations.ase`, and inside `JohnSmithAnimations.ase` we have 3 animations - represented as tags - idle, jump, and walk, the result would be:

```
Export/Frames/Characters/JohnSmithAnimations/JohSmithAnimationsIdle/01.png, .., etc
Export/Frames/Characters/JohnSmithAnimations/JohSmithAnimationsWalk/01.png, .., etc
Export/Frames/Characters/JohnSmithAnimations/JohSmithAnimationsJump/01.png, .., etc
```

Again, it might seem redundant to have `JohnSmithAnimations/JohnSmithAnimationsWalk` instead of just `JohnSmithAnimations/Walk`, but I promise it’s not. If we don’t have some indicator here to separate John’s walks from Bob’s walks, Unreal is going to yell at you when you extract the flipbooks from the data file.

## pack.bat overview
finally, we call `pack.bat`, which is the file that talks to the TexturePacker CLI:

`TexturePacker configuration.tps --default-pivot-point 0.5,1.0 --sheet Packed/%1/%2.png --data Packed/%1/%2.paper2dsprites AnimationArchive/Frames/%1/%2`

Here you're defining the config file, the pivot point, the location the sheet will export to and the name of the resulting texture, and the location of the data file -- these should always be next to each other for ease of use. Finally, you're telling it the folder where it can get the frames that need to be packed.

## In Unreal
Now, all you have to do is drag ONLY the `.paper2dsprites data file` from `Export/Packed/etc` into Unreal. This will automatically import the texture and extract the sprites. 

If you have a lot of sprites, this could lock up Unreal for a few, even if you have a beefy CPU.

At last, `right click` the `.paper2dsprites data file` in Unreal and choose `Create Flipbooks`.

# Appendix
## Scripts
### export.bat
```
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
```
### copyases.bat
```
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
```
### deleteold.bat
```
FOR /d /r . %%d IN (%2) DO @IF EXIST "%%d" rd /s /q "%%d"
```
### save.bat
```
@set ASEPRITE="C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"
%ASEPRITE% -b %2 --save-as AnimationArchive\Frames\%1\%3\%3{tag}\{frame01}.png
```
### pack.bat
```
TexturePacker configuration.tps --default-pivot-point 0.5,1.0 --sheet Packed/%1/%2.png --data Packed/%1/%2.paper2dsprites AnimationArchive/Frames/%1/%2
```




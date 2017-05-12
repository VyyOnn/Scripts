#SPECIFIES VARIABLE FOR FOLDERS TO COPY TO
for %%D in (
\\sample
) do xcopy "C:\sample" %%D /v /s /y /z 

@echo off
if errorlevel 4 goto lowmemory 
if errorlevel 2 goto abort 
if errorlevel 0 goto exit 

:lowmemory 
echo Insufficient memory to copy files or 
echo invalid drive or command-line syntax. 
goto exit

:abort 
echo You pressed CTRL+C to end the copy operation. 
goto exit

:exit

exit



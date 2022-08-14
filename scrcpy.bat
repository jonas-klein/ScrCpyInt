@echo off
setlocal enableextensions EnableDelayedExpansion

set ADB="scrcpy\adb.exe"
set scrcpy="scrcpy\scrcpy.exe"
echo/
echo -----------------------------------------------
echo -- Gullys ugly Meta Quest 2 scrcpy interface --
echo -----------------------------------------------
echo/

%ADB% devices > result.txt
set /p adbresult=<result.txt

set n=0
for /f "tokens=1,2 delims=	" %%i in (result.txt) do (
  if not "%%i" == "List of devices attached" (
    set tokens1[!n!]=%%i
	set tokens2[!n!]=%%j
	set /A n+=1
  )
)

echo These are the connected ADB devices
set /A n-=1
for /l %%a in (0,1,%n%-1) do (
  echo %%a - !tokens1[%%a]!
)
echo/
set /p addrIdx=Select one of them to scrcpy:
set target=!tokens1[%addrIdx%]!

goto :isTargetIPPort


:isTargetIPPort
set tmp=%target::=$%
if not !tmp! == !target! (
  echo %tmp%>tmp.txt
  echo %target%>target.txt

  echo ip detected
  echo L %tmp% E
  echo R %target% E
  set addrToConnect=%target%
  goto :connected
) else (
  echo no ip detected, 
  goto :enableTCPIPForGivenSerial
)

:enableTCPIPForGivenSerial
%ADB% -s !target! shell ip addr show wlan0 > result.txt
for /f "tokens=1,2" %%a in (result.txt) do (
  if "%%a" == "inet" (
    set foundip=%%b
  )
)
if "%foundip%"=="" (
  echo is not connected to wlan. retry in 5 sec
  timeout 5 > NUL
  goto :enableTCPIPForGivenSerial
)
%ADB% -s !target! tcpip 5555
timeout 2 > NUL
set addrToConnect=%foundip:/24=%:5555
goto :ipaddrPresent


:ipaddrPresent
echo try to connect to %addrToConnect%
%ADB% connect %addrToConnect% > result.txt
goto :connected


:connected
%scrcpy% -e --crop 1600:900:2017:510 REM 16:9


:exit
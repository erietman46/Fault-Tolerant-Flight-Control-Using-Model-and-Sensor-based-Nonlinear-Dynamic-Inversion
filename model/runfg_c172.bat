@echo off

"C:\Program Files\FlightGear 2024.1\bin\fgfs.exe" ^
 --fg-root="C:\Users\eltjo\FlightGear\Downloads\fgdata_2024_1" ^
 --aircraft=c172p ^
 --fdm=network,localhost,5501,5502,5503 ^
 --fog-fastest ^
 --disable-clouds ^
 --start-date-lat=2004:06:01:09:00:00 ^
 --disable-sound ^
 --on-ground ^
 --enable-freeze ^
 --airport=KSFO ^
 --runway=10L ^
 --altitude=0 ^
 --heading=113 ^
 --offset-distance=0 ^
 --offset-azimuth=0

pause
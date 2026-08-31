
<Flightgear install drive>:
cd <Flightgear install directory>

SET FG_ROOT=<Flightgear install directory>\data
.\\bin\fgfs --aircraft=c172p --fdm=network,localhost,5501,5502,5503 --fog-fastest --disable-clouds --start-date-lat=2004:06:01:09:00:00 --disable-sound --on-ground --enable-freeze --airport=KSFO --runway=10L --altitude=0 --heading=113 --offset-distance=0 --offset-azimuth=0

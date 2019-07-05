# follow_track

Display gpx track and current position

- load gpx track from file
- use offline map tiles
- toggle display of current position
- track infos (distance, elevations)
- points info (distance and elevation between points)

Main page
- Display tracks which a available on device
- Button to select a track on device, which is not on list of tracks
- Find all tracks in a default directory (storage or sdcard)
- Options menu - track directory
- Save location of gpx files in ?

Track page

GPX Parser

FileIO

Models

iOS Build
Error Package directories not found: add profile.xcconfig
File: ios/Flutter/Release.xcconfig
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"

Delete Pod folder before Pod install


https://www.freecodecamp.org/news/flutter-platform-channels-with-protobuf-e895e533dfb7/

#######################################################
Get application's data container by running
xcrun simctl get_app_container <device> <bundle>

xcrun simctl get_app_container 29467DAB-79B6-4B8D-B8BA-5866C0D0AC0D com.devwolf.followTrack

Get device id by running xcrun simctl list

#######################################################

Update path_provider to 1.1.1
- flutter_maps: path_provider 0.5.0+1

#######################################################
Load gpx data

1. load from internal storage, directory Tracks

2. load from SD card (SDCard as external storage)
    - should be possible to choose directory

3. Offline map tiles are always on external SD card in directory OfflineMapTiles
    - map tiles can be used by different gpx tracks from different directories
    - different areas in one map tiles directory

    - for small areas it should be possible to store the map tiles on internal storage

SD card as internal storage?
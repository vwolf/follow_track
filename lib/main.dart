import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
//import 'package:path_provider/path_provider.dart';

import 'models/track.dart';
import 'map/map_page.dart';
import 'track/track_list.dart';
import 'track/track_service.dart';
import 'fileIO/local_file.dart';
import 'fileIO/permissions.dart';

import 'fileIO/settings.dart';

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Follow Track',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: MainPage(title: 'Follow Track'),
    );
  }
}

typedef LoadMap = void Function(TrackService trackService);

/// This is the start page.
/// Display list of all available gpx tracks in [TrackList].
/// SD card insert then option to search on card
class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  // test MethodeChannel
  static const platform = const MethodChannel('devwolf.track.dev/battery');

  bool _showHowTo = false;
  List<Track> _tracks = [];
  Directory _gpxFileDirectory;
  String _gpxFileDirectoryString = "?";
  String _sdCardGpxFileDirectory = "";

  Map<String, dynamic> trackSettings;

  LoadMap loadMap;

  /// Request permissions (storage)
  /// First get possible storage paths (internal and external)
  /// Read gpx track data from possible path's
  ///
  void initState() {
    super.initState();

    setDirectory();
    readSettings();

    loadMap = loadMapCallback;

  }

  /// Use [Path_Provider] to get path to external storage directory.
  /// Default directory is Tracks. This can be changed using settings.
  /// Here we only search in internal storage
  ///
  void setDirectory() async {

    var permission = await RequestPermissions().requestPermission(PermissionGroup.storage);
    if (permission) {
      await setStoragePath().then((result) {
        if (result) {
          // no directory at internal storage path then create empty directory
            _gpxFileDirectoryString = Settings.settings.pathTracksInternal;
            if (Directory(_gpxFileDirectoryString).existsSync() == false) {
              Directory(_gpxFileDirectoryString).create(recursive: true);
            }
            findTracks(_gpxFileDirectoryString);
        }
      }).then((_) {
        // tracks on sd card?
        print(Settings.settings.externalSDCard);
        print(Settings.settings.pathTracksInternal);
        if (Settings.settings.externalSDCard != null) {
          // build default path
          String trackDirectory = "${Settings.settings.externalSDCard}/${Settings.settings.defaultTrackDirectory}";
          print(trackDirectory);
          Settings.settings.pathToMapTiles = "${Settings.settings.externalSDCard}/${Settings.settings.pathToMapTiles}";
          searchSDCard().then((r) {
            if (r == true) {
              print("SEARCH SDCARD!!");
              findTracks(trackDirectory);
            } else {
              // r == null: click outside of dialog, r == false: cancel button in dialog
              print("Search SD card canceled");
            }
          });

        }
      });

    }
  }


  /// Permission to read/write to Storage
  ///
//  Future requestPermission() async {
//    var pStatus =  await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
//    if (pStatus == PermissionStatus.denied) {
//      var permissionStatus = await RequestPermissions().requestWritePermissions(PermissionGroup.storage);
//      if(permissionStatus == true) {
//        print("PERMISSION TO ACCESS STORAGE GRANDTED!");
//        print(permissionStatus);
//        return true;
//      } else {
//        print("NO PERMISSION TO ACCESS STORAGE!");
//      }
//    } else {
//      print("PERMISSION TO ACCESS STORAGE GRANDTED!");
//      return true;
//    }
//    return false;
//  }

  /// Set path to internal Storage and to external SDCard.
  /// Add to [Settings]
  /// Uses  path_provider_ex,
  ///
  Future<bool> setStoragePath() async {
    List<StorageInfo> storageInfo;

    // storage Android
    if (Platform.isAndroid) {
      // storage internal
      var dir = await getExternalStorageDirectory();
      Settings.settings.pathTracksInternal = "${dir.path}/${Settings.settings.defaultTrackDirectory}";

      // storage sd card (external)
      try {
        storageInfo = await PathProviderEx.getStorageInfo();

      } on PlatformException {}

      if (mounted) {
        if (storageInfo.length >= 1) {
          Settings.settings.externalSDCard = storageInfo[1].rootDir;
        }
      }

      return true;
    }
    return false;
  }



  /// ToDo Feature addTrack
  void addTrack() {}


  /// This is just for testing
  void writeSettings() async {
    //await LocalFile().writeContent("tracksSettings.txt", "Settings new");
    Map<String, String> settingsMap = { "trackname" : "path to Offline map tiles"};
    await LocalFile().writeMapToJson("tracksSettings.txt", settingsMap);
    readSettings();
  }


  /// Read settings from local file into [trackSettings].
  ///
  void readSettings() async {
    print("Read track settings from local file");
    trackSettings = await LocalFile().readJson("tracksSettings.txt");
    print("trackSettings: $trackSettings");
    Settings.settings.set(trackSettings);
  }


  /// Add all gpx files in [directoryPath] to [trackPath].
  /// Then call [loadTrackMetaData] to read gpx files.
  ///
  /// [directoryPath]
  void findTracks(String directoryPath) {
    List<String> trackPath = [];
    Directory(directoryPath).list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
          if (path.extension(entity.path) == ".gpx") {
            if (trackPath.contains(entity.path) == false) {
              trackPath.add(entity.path);
            }
          }
        })
        .onDone( () => {
          //trackPath.length == 0 ? searchSDCard() : this.loadTrackMetaData(trackPath)
          this.loadTrackMetaData(trackPath)
    });
  }

  /// Show [SimpleDialogOption] to search on SD card
  /// Return [Future] [bool]
  Future searchSDCard() async {
    print("searchSDCard");
    switch(
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Search on SD Card?'),
              children: <Widget>[
                SimpleDialogOption(
                  child: Text("Yes"),
                  onPressed: () {
                    Navigator.pop(context, "Yes");
                  } ),
                SimpleDialogOption(
                  child: Text("No"),
                  onPressed: () {
                    Navigator.pop(context, "No");
                  } ),
              ],
            );
          },
        )
    )  {
      case "Yes" :
        return true;
        break;

      case "No" :
        return false;
        break;
    }
  }


  /// Select directory with gpx files
  ///
  void setGpxFileDirectory() async {
    await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    Directory externalStorageDir = await getExternalStorageDirectory();
  //  Directory absolutExternal = externalStorageDir.absolute;
    externalStorageDir.list(recursive: true, followLinks: false)
    .listen((FileSystemEntity entity) {
      print(entity.path);
    });
    //var storageDir = Directory.systemTemp;
    try {
      String pathToTrack = await FilePicker.getFilePath(type: FileType.ANY);
      if (pathToTrack != "" && pathToTrack != null) {
        String dirPath = path.dirname(pathToTrack);
        List<String> dirPathSplit = path.dirname(pathToTrack).split('/');
        if (dirPathSplit.length > 0) {
          //String filePath = dirPathSplit.removeLast();
          //dirPath = dirPathSplit.join('/');
        }
        print (dirPath);
        setState(() {
          _gpxFileDirectoryString = dirPath;
          findTracks(_gpxFileDirectoryString);
          Navigator.pop(context);
        });
      }
    } on Platform catch(e) {
      print(e);
    }
  }



  void getSDCardFiles() {
    String path = Settings.settings.externalSDCard;

    String pathToTracks = path + "/Tracks/";
    Directory(pathToTracks).list(recursive: true, followLinks: false)
    .listen((FileSystemEntity entity) {
      print(entity.path);
    });
    setState(() {
      _sdCardGpxFileDirectory = pathToTracks;
      findTracks(_sdCardGpxFileDirectory);
      Navigator.pop(context);
    });


  }

  /// ToDo
  void getOfflineMapTilesDirectory() {}


  /// Set the distance offset from track when notification is triggered
  ///
  Future <String> editTrackOffsetDistance(BuildContext context) async {
    String distance = '';
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Set the distance when to get a notification"),
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Distance in meter',
                    ),
                    keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                    onChanged: (value) {
                      distance = value;
                    },
                  ),
                )
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(distance);
                },
              )
            ],
          );
        });
  }


  /// Load meta data from tracks in [_gpxFileDirectory] into [Track]
  ///
  /// [filePaths] list of gpx files in track directory
  /// Filter track files from waypoint files
  void loadTrackMetaData(List<String> filePaths) async {

    for (var path in filePaths) {
      print ("loadTrackMetaData from $path");
      Track oneTrack = await Utils().getTrackMetaData(path);
      if (oneTrack.name != "") {
        _tracks.add(oneTrack);
        // any settings for track?
        if (trackSettings.containsKey(oneTrack.name)) {
          oneTrack.offlineMapPath = trackSettings[oneTrack.name];
        }
      }

     // _tracks.add(oneTrack);
    }
    setState(() {});
  }


  /// Go to page with HowTo's or open modal or bottomsheet?
  ///
  void showHowTo() {
    if (!_showHowTo) {
      _showHowTo = true;
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: const Center(
                child: const Text("Settings"),
              ),
            ),
            ListTile(
              title: Text("Gpx file directory"),
              subtitle: Text(_gpxFileDirectoryString),
              trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setGpxFileDirectory();
                  }
              )
            ),
            ListTile(
              title: (Text("Gpx file on SD card")),
              subtitle: Settings.settings.externalSDCard != null ? Text("${Settings.settings.externalSDCard}/Tracks/") : Text("No SDCard"),
              trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    getSDCardFiles();
                  },
              ),
            ),
            ListTile(
              title: Text("Offline Map Tiles"),
              subtitle: Settings.settings.externalSDCard != null ? Text("${Settings.settings.externalSDCard}/OfflineMapTiles") : Text("No SDCard"),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  getOfflineMapTilesDirectory();
                },
              ),
            ),
            ListTile(
              title: Text("Track Offset Distance Notification"),
              subtitle: Text("${Settings.settings.distanceToTrackAlert} meter"),
              trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final String distance = await editTrackOffsetDistance(context);
                    ///print("offsetDistance $distance");

                    setState(() {
                      Settings.settings.distanceToTrackAlert = int.parse(distance);
                    });
                  }
              ),
            ),
            ListTile(
              title: Text("HowTo's"),
              trailing: Icon(Icons.open_in_new),
              onTap: showHowTo,
            )
          ],
        ),
      ),

    body: Container(
      child: _buildTrackList,
    ),
//    persistentFooterButtons: <Widget>[
//    FloatingActionButton.extended(
//      heroTag: "addTrack",
//      onPressed: addTrack,
//      icon: Icon(Icons.add),
//      label: Text("Add Track")),
//    FloatingActionButton.extended(
//      heroTag: "batterylevel",
//      onPressed: _getBatteryLevel,
//      label: Text("Battery Level"),
//        )
//    ],

    );
  }


  Widget get _buildTrackList {
    return ListView.builder(
      itemCount: _tracks.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          leading: Container(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(Icons.directions_walk, size: 40.0,
            ),
          ),
          title: Text(
            _tracks[index].name,
            style: Theme.of(context).textTheme.headline,
          ),
          //subtitle: Text(_tracks[index].location),
          subtitle: Row(
            //scrollDirection: Axis.horizontal,

            children: <Widget>[
              Text(_tracks[index].location),
              _offlineIcon(index),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right, size: 30.0,
          ),
          onTap: (() => { _handleTap(index)} ),
          dense: true,
        );
      },

    );
  }


  /// Show Offline icon if [offlineMapPath] is set
  ///
  /// [index]
  Widget _offlineIcon(int index) {
    if (_tracks[index].offlineMapPath != null) {
      return Icon(Icons.map);
    } else {
      return Container();
    }
  }




  /// After track and waypoints loaded display map with waypoints
  ///
  void loadMapCallback(TrackService trackService) {
    print("waypoints loaded");
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return MapPage(trackService);
        })
    );
  }


  /// Tap on track list entry
  ///
  /// [loadMapCallBack] returns after parsing of possible waypoints
  _handleTap(index) async {
    print("handleTap()");
    TrackService trackService = TrackService(_tracks[index]);

    await trackService.getTrack(_tracks[index].gpxFilePath, _gpxFileDirectoryString).then((r) {
      String wayPointsDirectory =  path.dirname(_tracks[index].gpxFilePath) + "/${trackService.gpxFileData.trackName}/";
      trackService.track.offlineMapPath = Settings.settings.pathToMapTiles;
      trackService.getTrackWayPoints(wayPointsDirectory, loadMapCallback).then((a) { print("getTrackPosints end");});
    }).whenComplete( () {
      print("complete");
    });
    //;
//    String wayPointsDirectory =  path.dirname(_tracks[index].gpxFilePath) + "/${trackService.gpxFileData.trackName}/";
//    trackService.track.offlineMapPath = Settings.settings.pathToMapTiles;
//    await trackService.getTrackWayPoints(wayPointsDirectory, loadMapCallback);
  }



  ///
  String _batteryLevel = "Unknown battery level";

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result %.';

    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: ${e.message}";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });

    print(batteryLevel);
  }


}

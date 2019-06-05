import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'models/track.dart';
import 'map/map_page.dart';
import 'track/track_list.dart';
import 'track/track_service.dart';
import 'fileIO/local_file.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: MainPage(title: 'Follow Track'),
    );
  }
}

/// This the start page. Display list of all available gpx tracks in [TrackList].
///
class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {

  static const platform = const MethodChannel('devwolf.track.dev/battery');

  bool _showHowTo = false;
  List<Track> _tracks = [];
  Directory _gpxFileDirectory;
  String _gpxFileDirectoryString = "?";
  Map<String, dynamic> trackSettings;

  /// Set the directory with gpx files
  void initState() {
    super.initState();
    setDirectory();
   // readSettings();
    writeSettings();
  }


  void setDirectory() async {
    await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    try {
      var dir = await getExternalStorageDirectory();
      setState(() {
        _gpxFileDirectoryString = "${dir.path}/Tracks";
      });
      Directory(_gpxFileDirectoryString).create(recursive: true);
      findTracks();
    } catch (e) {
      print("Error $e");
    }
  }


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
  }


  /// Add all gpx files in [_gpxFileDirectoryString] to [trackPath].
  /// Then call [loadTrackMetaData] to read gpx files.
  ///
  void findTracks() {
    List<String> trackPath = [];
    Directory(_gpxFileDirectoryString).list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
          if (path.extension(entity.path) == ".gpx") {
            trackPath.add(entity.path);
          }

        })
        .onDone( () => {
          this.loadTrackMetaData(trackPath)
    });
  }

  /// Select directory with gpx files
  ///
  void setGpxFileDirectory() async {
    await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    Directory externalStorageDir = await getExternalStorageDirectory();
    externalStorageDir.list(recursive: true, followLinks: false)
    .listen((FileSystemEntity entity) {
      print(entity.path);
    });
    //var storageDir = Directory.systemTemp;
    try {
      String pathToTrack = await FilePicker.getFilePath(type: FileType.ANY);
      if (pathToTrack != "" && pathToTrack != null) {
        String dirPath = path.dirname(pathToTrack);
        print (dirPath);
//        setState(() {
//          _gpxFileDirectory = dirPath;
//          Navigator.pop(context);
//        });
      }
    } on Platform catch(e) {

    }
  }

  /// Load meta data from tracks in [_gpxFileDirectory] into [Track]
  ///
  /// [filePaths] list of gpx files in track directory
  /// Filter track files from waypoint files
  void loadTrackMetaData(List<String> filePaths) async {

    for (var path in filePaths) {
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
              trailing: Icon(Icons.edit),
              onTap: setGpxFileDirectory,
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
      persistentFooterButtons: <Widget>[
        FloatingActionButton.extended(
          heroTag: "addTrack",
            onPressed: addTrack,
            icon: Icon(Icons.add),
            label: Text("Add Track")),
        FloatingActionButton.extended(
          heroTag: "batterylevel",
            onPressed: _getBatteryLevel,
            label: Text("Battery Level"),
        )
      ],


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


  Widget _offlineIcon(int index) {
    if (_tracks[index].offlineMapPath != null) {
      return Icon(Icons.map);
    } else {
      return Container();
    }
  }


  _handleTap(index) {
    print("handleTap()");
    TrackService trackService = TrackService(_tracks[index]);
    trackService.getTrack(_tracks[index].gpxFilePath, _gpxFileDirectoryString);

    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return MapPage(trackService);
        })
    );
  }


  Widget get _basicList {
    return ListView(
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.map),
          title: Text('Map'),
        ),
        ListTile(
          leading: Icon(Icons.photo_album),
          title: Text('Album'),
        ),
        ListTile(
          leading: Icon(Icons.phone),
          title: Text('Phone'),
        ),
      ],
    );
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

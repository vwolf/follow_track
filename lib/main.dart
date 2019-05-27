import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'models/track.dart';

//import 'gpx/gpx_tracks_page.dart';
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

  bool _showHowTo = false;
  List<Track> _tracks = [];
  Directory _gpxFileDirectory;
  String _gpxFileDirectoryString = "?";
  Map<String, dynamic> trackSettings;

  void initState() {
    super.initState();
    setDirectory();
    readSettings();
  }


  void setDirectory() async {
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



  void addTrack() {
//    Navigator.of(context).push(
//      MaterialPageRoute(builder: (context) {
//        return GpxTracksPage();
//      })
//    );
  }

  void writeSettings() async {
    //await LocalFile().writeContent("tracksSettings.txt", "Settings new");
    Map<String, String> settingsMap = { "trackname" : "path to Offline map tiles"};
    await LocalFile().writeMapToJson("tracksSettings.txt", settingsMap);
    readSettings();
  }



  void readSettings() async {
    print("Read track settings from local file");
    trackSettings = await LocalFile().readJson("tracksSettings.txt");
    print (trackSettings.length);

//    print(settings);
//    print(settings['trackname']);
//
//    // test add to file
//    await LocalFile().addToJson("tracksSettings.txt", "next track", "paht of next");
//    settings = await LocalFile().readJson("tracksSettings.txt");
//
//    print(settings);
//    if (settings.containsKey("next track")) {
//      print (settings["next track"]);
//    }
  }



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
  void loadTrackMetaData(List<String> filePaths) async {

    for (var path in filePaths) {
      Track oneTrack = await Utils().getTrackMetaData(path);
      if (trackSettings.containsKey(oneTrack.name)) {
        oneTrack.offlineMapPath = trackSettings[oneTrack.name];
      }
      _tracks.add(oneTrack);


    }
    // load each gpx file as Track
//    Track oneTrack = await Utils().getTrackMetaData(filePaths[0]);
//    print(oneTrack);
//
//    _tracks.add(oneTrack);
    setState(() {

    });
    // list of tracks

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
            onPressed: addTrack,
            icon: Icon(Icons.add),
            label: Text("Add Track"))
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
    trackService.getTrack(_tracks[index].gpxFilePath);

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
}

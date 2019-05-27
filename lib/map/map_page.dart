import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../track/track_service.dart';
import '../map/map_track.dart';
import '../fileIO/directory_list.dart';
import '../fileIO/local_file.dart';

typedef MapPath = void Function(String mapPath);

/// Page with map.Display selected track on map
class MapPage extends StatefulWidget {
  final TrackService trackService;

  MapPage(this.trackService);

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {

  /// communication with map via streams
  StreamController<TrackPageStreamMsg> _streamController = StreamController.broadcast();
  String _gpxFilePath;
  MapTrack get _mapTrack => MapTrack(widget.trackService, _streamController);

  bool _offlineMapDialog = false;
  String _mapPath;

  /// callback function used as a closure
  MapPath setMapPath;

  void initState() {
    super.initState();
    initStreamController();

    setMapPath = getMapPath;
  }

  /// Initialize _streamController subscription to listen for TrackPageStreamMsg
  initStreamController() {
    _streamController.stream.listen((TrackPageStreamMsg trackingPageStreamMsg) {
      onMapEvent(trackingPageStreamMsg);
    }, onDone: () {
      print('TrackingPageStreamMsg Done');
    }, onError: (error) {
      print('TrackingPage StreamContorller error $error');
    });
  }


  onMapEvent(TrackPageStreamMsg trackingPageStreamMsg) {
    print("TrackingPage.onMapEvent ${trackingPageStreamMsg.type}");
//    switch (trackingPageStreamMsg.type) {
//      case "mapStatusLayerAction" :
//        if ( trackingPageStreamMsg.msg == "offline_on__") {
//          if (_mapTrack.trackService.pathToOfflineMap == null ) {
//            _offlineMapDialog = true;
//            openFileIO();
//          } else {
//
//          }
//        };
//        break;
//    };
//
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Track Name"),
      ),
      body: Column(
        children: <Widget>[
          _mapTrack,
        ],
      ),
    );
  }


  /// Open a kind of directory browser to select the director which contains the map tiles
  ///
  /// ToDo Open in a new page?
  openFileIO() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return DirectoryList(setMapPath);
        })
    );
  }


  // callback offline map directory selection
  void getMapPath(String mapPath) {
    print("mapPath: $mapPath");
    _mapPath = mapPath;
    _mapTrack.trackService.pathToOfflineMap = _mapPath;
    _streamController.add(TrackPageStreamMsg("offline", true));

    // add the path to offline map tiles to settings file
    LocalFile().addToJson("tracksSettings.txt", _mapTrack.trackService.track.name, _mapPath);
  }


//  Future<void> _askedToLead() async {
//    switch (await showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return SimpleDialog(
//            title: const Text('Where is the offline map?'),
//            children: <Widget>[
//              SimpleDialogOption(
//                onPressed: () async {
//                  String pathToTrack = await FilePicker.getFilePath(type: FileType.ANY);
//                },
//                child: const Text('Choose'),
//              ),
//              SimpleDialogOption(
//                onPressed: () { Navigator.pop(context); },
//                child: const Text('Exit'),
//              ),
//            ],
//          );
//        }
//    )) {
//
//    }
//  }


}
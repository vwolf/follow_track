import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../track/track_service.dart';
import '../map/map_track.dart';
import '../fileIO/directory_list.dart';

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
    switch (trackingPageStreamMsg.type) {
      case "mapStatusLayerAction" :
        if ( trackingPageStreamMsg.msg == "offline_on") {
          _offlineMapDialog = true;
          //_askedToLead();
          openFileIO();
        };
        break;
    };

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


  /// Open kind of directory browser to select the director which contains the map tiles
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
  }


  Future<void> _askedToLead() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Where is the offline map?'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () async {
                  String pathToTrack = await FilePicker.getFilePath(type: FileType.ANY);
                },
                child: const Text('Choose'),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context); },
                child: const Text('Exit'),
              ),
            ],
          );
        }
    )) {

    }
  }


}
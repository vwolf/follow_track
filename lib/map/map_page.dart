import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:latlong/latlong.dart';

import '../track/track_service.dart';
import '../map/map_track.dart';
import '../fileIO/directory_list.dart';
import '../fileIO/local_file.dart';
import '../track/geoLocationService.dart';

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

  /// for persistent bottomsheet
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController _persistentBottomSheetController;

  double distanceToStart = 0.0;
  double distanceToEnd = 0.0;

  int openWayPoint;

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
       if(trackingPageStreamMsg.msg == "info_on") {
          print("toggle track info");
          openPersistentBottomSheet();
       }
       break;

      case "wayPointAction" :
        openWayPointBottomSheet(trackingPageStreamMsg.msg);
        break;
    }

  }


  openPersistentBottomSheet() {
    if (_persistentBottomSheetController == null ) {
      setState(() {
        getDistance();
      });
      _persistentBottomSheetController =
          _scaffoldKey.currentState.showBottomSheet((BuildContext context) {
            return _trackInfoSheet;
          });

    } else {
      _persistentBottomSheetController.close();
      _persistentBottomSheetController = null;
    }
  }



  openWayPointBottomSheet(wayPointIndex) {
    if (_persistentBottomSheetController == null) {
      openWayPoint = wayPointIndex;
      _persistentBottomSheetController = _scaffoldKey.currentState.showBottomSheet((BuildContext context) {
        return _wayPointSheet;
      });
    } else {
      _persistentBottomSheetController.close();
      _persistentBottomSheetController = null;
    }

  }


  Widget get _trackInfoSheet {
    return Container(
      color: Colors.blueGrey,
      width: double.infinity,
      padding: EdgeInsets.only(top: 0.0, bottom: 2.0),
      constraints: BoxConstraints.loose(Size(double.infinity, 240.0)),
          child: ListView(
            //padding: EdgeInsets.symmetric(vertical: 2.0,  horizontal: 0.0),
            //padding: EdgeInsets.all(0.0),
            children: <Widget>[
              ListTile(
                //contentPadding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                title: Text("Track length: ${_mapTrack.trackService.trackLength.truncate()} meter"),
              ),
              ListTile(
                //contentPadding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                title: Text("Distance to start point: $distanceToStart m"),   //${getDistanceTo().toString()}
              ),
              ListTile(
                title: Text("Distance to end point: $distanceToEnd m"),
              )
            ],
          ),



//      child: SingleChildScrollView(
//        child: ConstrainedBox(
//            constraints: BoxConstraints(),
//            child: Column(
//              children: <Widget>[
//                Padding(
//                  padding: EdgeInsets.only(left: 12.0),
//                  child: Text("Track length: ${_mapTrack.trackService.trackLength}"),
//                )
//              ],
//            ),
//        ),
//      ),
    );
  }


  Widget get _wayPointSheet {
    return Container(
      color: Colors.blueGrey,
      width: double.infinity,
      constraints: BoxConstraints.loose(Size(double.infinity, 240.0)),
      //alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          //mainAxisSize: MainAxisSize.min,

          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 12.0, top: 20.0),
              child: Text("${_mapTrack.trackService.gpxFileData.wayPoints[openWayPoint].name}", textAlign: TextAlign.left,),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 12.0, top: 10.0),
              child: Text("${_mapTrack.trackService.gpxFileData.wayPoints[openWayPoint].description}"),
            ),

          ],
        ),
    );
  }


  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("${_mapTrack.trackService.gpxFileData.trackName}"),
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


  /// Calculate the distance from current position to start and end of track
  ///
  getDistance() {
    LatLng startLatLng = _mapTrack.trackService.gpxFileData.gpxLatlng.first;
    LatLng endLatLng = _mapTrack.trackService.gpxFileData.gpxLatlng.last;
    LatLng currentPosition = _mapTrack.trackService.currentPosition;
    if (currentPosition != null) {
      GeoLocationService.gls.getDistanceBetweenCoords(startLatLng, currentPosition)
          .then((result) {
            distanceToStart = result.truncateToDouble();
      });

      GeoLocationService.gls.getDistanceBetweenCoords(endLatLng, currentPosition)
      .then((result) {
        distanceToEnd = result.truncateToDouble();
      });
    }
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
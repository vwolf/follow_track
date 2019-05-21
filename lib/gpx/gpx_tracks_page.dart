//import 'dart:async';
//
//import 'package:flutter/material.dart';
//import 'package:path/path.dart' as path;
//
//import 'read_file.dart';
//import '../track/track_service.dart';
//import '../map/map_track.dart';
//
//import 'gpx_parser.dart';
//
///// Select a track and display list of tracks (local storage).
///// Display selected track on a map
/////
//class GpxTracksPage extends StatefulWidget {
//  final TrackService trackService;
//
//  GpxTracksPage(this.trackService);
//
//  @override
//  GpxTracksPageState createState() => GpxTracksPageState();
//}
//
//
//class GpxTracksPageState extends State<GpxTracksPage> {
//
//  String _gpxFilePath;
//
//  MapTrack get _mapTrack => MapTrack(widget.trackService);
//
//  @override
//  void initState() {
//    super.initState();
//
//    // parse gpx file into new TrackService object
//
////    var filePath = getTrack();
////    if (filePath != null) {
////
////    }
//  }
//
//
//  /// Read track data from gpx file
//  ///
//  ///
//  Future getTrack() async {
//    final filePath = await ReadFile().getPath();
//    String fileType = path.extension(filePath);
//    if (fileType != '.gpx') {
//      //bottomSheet(fileType);
//      return null;
//    }
//
//    _gpxFilePath = filePath;
//
//    final fileContent = await ReadFile().readFile(_gpxFilePath);
//
//    return filePath;
//  }
//
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text("Select Track"),
//      ),
//      body: Column(
//        children: <Widget>[
//          _mapTrack,
//        ],
//      ),
//
////      persistentFooterButtons: <Widget>[
////        FloatingActionButton.extended(
////            onPressed: getTrack,
////            icon: Icon(Icons.add),
////            label: Text("Track"),
////        ),
////      ],
//    );
//
//  }
//
//
////  bottomSheet(String fileType) {
////    showModalBottomSheet(
////        context: context,
////        builder: (BuildContext context) {
////          return Column(
////            mainAxisSize: MainAxisSize.min,
////            children: <Widget>[
////              ListTile(
////                leading: Icon(Icons.error, color: Colors.redAccent,),
////                title: Text('Can\' read file of type $fileType. Choose a *.gpx file.'),
////              )
////            ],
////          );
////        });
////  }
//
//
//}
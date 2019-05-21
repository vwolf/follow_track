import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../track/track_service.dart';
import 'map_statusLayer.dart';

/// Provide a map view using flutter_map package
///
class MapTrack extends StatefulWidget {
  final StreamController<TrackPageStreamMsg> streamController;
  final TrackService trackService;

  MapTrack(this.trackService, this.streamController);

  @override
  MapTrackState createState() => MapTrackState(trackService, streamController);
}


class MapTrackState extends State<MapTrack> {

  TrackService trackService;
  StreamController streamController;

  MapTrackState(this.trackService, this.streamController);

  // MapController and plugin layer
  MapController _mapController;
  MapStatusLayer _mapStatusLayer = MapStatusLayer(false, false);

  LatLng get startPos => widget.trackService.getTrackStart();

  // status values
  bool _offline = false;
  bool _location = false;

  @override
  void initState() {
    super.initState();
    streamInit();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  streamInit() {
    streamController.stream.listen((event) {
      streamEvent(event);
    });
  }

  streamEvent(TrackPageStreamMsg event) {
    print("StreamEvent $event");
    switch(event.type) {
      case "mapStatusLayerAction" :

        switch (event.msg) {
          case "location_on" :
            setState(() {
              _location = !_location;
              _mapStatusLayer.statusNotification(event.msg, _location);
            });
            break;
          case "offline_on" :
            if(trackService.pathToOfflineMap == null) {

            }
            setState(() {
              _offline = !_offline;
              _mapStatusLayer.statusNotification(event.msg, _offline);
            });
            break;
        }
        break;

      case "callback" :
        String status = "";
        _location == true ? status += "Position On" : status += "Position Off";
        status += " / ";
        _offline == true ? status += "Offline Modus" : status += "Online Modus";

        event.msg(status);
        break;
    }
  }

  /// Switch between using online map and offline maps.
  /// Location to offline maps set?
  /// If not set, let the user set location of maps for this track
  switchOfflineModus() async {
    if (_offline == false) {
      // switch to offline modus
      if(trackService.pathToOfflineMap == null) {
        //

        String pathToTrack = await FilePicker.getFilePath(type: FileType.ANY);
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: startPos,
          zoom: 15,
          minZoom: 4,
          maxZoom: 18,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          plugins: [
            _mapStatusLayer,
          ]
        ),
        layers: [
          TileLayerOptions(
            offlineMode: _offline,
            fromAssets: false,
            urlTemplate: _offline ? "/storage/emulated/0/Tracks/map_tiles/gransee_zedenick/{z}/{x}/{y}.png" : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            //urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: _offline ? const <String>[] : ['a', 'b', 'c'],
          ),
          PolylineLayerOptions(
            polylines: [
              Polyline(
                points: widget.trackService.gpxFileData.gpxLatlng,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              )
            ]
          ),
          MarkerLayerOptions(

          ),
          MapStatusLayerOptions(
            streamController: streamController,
            //locationOn: false,
            //offline: false,
          ),
        ]
      ),
    );

  }


  void _handleTap(LatLng latlng) {
    print("_handleTap at $latlng");
  }

  void _handleLongPress(LatLng latlng) {
    print("_handleLongPress at $latlng");
  }

}
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';
//import 'package:path/path.dart' as path;
//import 'package:path_provider/path_provider.dart';

import '../fileIO/directory_list.dart';
import '../track/track_service.dart';
import 'map_statusLayer.dart';
import '../fileIO/local_file.dart';

import '../track/geoLocationService.dart';
import '../models/waypoint.dart';

typedef MapPathCallback = void Function(String mapPath);

/// Provide a map view using flutter_map package
///
class MapTrack extends StatefulWidget {
  final StreamController<TrackPageStreamMsg> streamController;
  final TrackService trackService;

  MapTrack(this.trackService, this.streamController);

  @override
  MapTrackState createState() => MapTrackState(trackService, streamController);
}

/// State for MapTrack page
///
///
class MapTrackState extends State<MapTrack> {

  TrackService trackService;
  StreamController streamController;

  StreamController geoLocationStreamController;

  MapTrackState(this.trackService, this.streamController);

  // MapController and plugin layer
  MapController _mapController = MapController();
  MapStatusLayer _mapStatusLayer = MapStatusLayer(false, false, "...");

  LatLng get startPos => widget.trackService.getTrackStart();

  // status values
  bool _offline = false;
  bool _location = false;

  LatLng _currentPosition;

  /// callback function used as a closure
  MapPathCallback setMapPath;

  void setOffline(bool value) {
    _offline = value;
  }

  @override
  void initState() {
    super.initState();
    streamInit();
    setMapPath = getMapPath;
    _mapStatusLayer.status = "Position Off / Online Map";
  }

  @override
  void dispose() {
    streamController.close();
    if (geoLocationStreamController != null) {
      geoLocationStreamController.close();
    }
    super.dispose();
  }


  streamInit() {
    streamController.stream.listen((event) {
      streamEvent(event);
    });
  }

  streamEvent(TrackPageStreamMsg event) {
    print("MapTrack StreamEvent ${event.type} : ${event.msg}");
    switch(event.type) {
      case "mapStatusLayerAction" :

        switch (event.msg) {
          case "location_on" :
            setState(() {
              _location = !_location;
              _mapStatusLayer.statusNotification(event.msg, _location);
              switchGeoLocation();
            });
            break;
          case "offline_on" :
            if (trackService.track.offlineMapPath == null) {
              // user must set path to offline map tiles
              openFileIO();
            } else {
              trackService.pathToOfflineMap = trackService.track.offlineMapPath;
              setState(() {
                _offline = !_offline;
                _mapStatusLayer.statusNotification(event.msg, _offline);
               // _mapStatusLayer.statusNotification(event, value)
                trackService.getTrackBoundingCoors();

              });
            }

            break;
        }
        break;

//      case "callback" :
//        String status = "";
//        _location == true ? status += "Position On" : status += "Position Off";
//        status += " / ";
//        _offline == true ? status += "Offline Modus" : status += "Online Modus";
//
//        event.msg(status);
//        break;
//
//      case "offline" :
//        _offline = event.msg;
//
//        break;
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


  /// Open a kind of directory browser to select the director which contains the map tiles
  ///
  /// ToDo Open in a new page?
  openFileIO() async {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return DirectoryList(setMapPath);
        })
    );
  }


  /// Callback offline map directory selection
  /// There was already a basic check if valid directory
  ///
  void getMapPath(String mapPath) {
    print("mapPath: $mapPath");
    setState(() {
      trackService.pathToOfflineMap = mapPath;
      _offline = !_offline;
      _mapStatusLayer.statusNotification("offline_on", _offline);

    });

    // add the path to offline map tiles to settings file
    LocalFile().addToJson("tracksSettings.txt", trackService.track.name, mapPath);
    // update track
    trackService.track.offlineMapPath = mapPath;
  }


  /// Subscribe / Unsubscribe to geoLocationStream in Geolocation
  /// Set to current state of _location
  ///
  switchGeoLocation() {
    if (_location) {
      geoLocationStreamController = StreamController();
      geoLocationStreamController.stream.listen((coords) {
        onGeoLocationEvent(coords);
      });
      GeoLocationService.gls.subscribeToPositionStream(geoLocationStreamController);
    } else {
      GeoLocationService.gls.unsubcribeToPositionStream();

    }
  }

  /// Current geo location from [GeoLocationService] as [Position].
  /// Update [gpsPositionList] and center map on [currentPosition].
  ///
  onGeoLocationEvent(Position coords) {
    if (_location) {
      _currentPosition = LatLng(coords.latitude, coords.longitude);
      setState(() {
        gpsPositionList;
        _mapController.move(_currentPosition, _mapController.zoom);
        trackService.currentPosition = _currentPosition;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: startPos,
          zoom: 13,
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
            urlTemplate: _offline ? "${trackService.pathToOfflineMap}/{z}/{x}/{y}.png" : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
            ],
            //onTap: (Polyline polyline, LatLng latlng, int polylineIdx ) => _onTap("track", polyline, latlng, polylineIdx)
          ),
          MarkerLayerOptions(
            markers: markerList,
          ),
          MarkerLayerOptions(
            markers: gpsPositionList,
          ),
          MarkerLayerOptions(
            markers: wayPointsList,
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


  List<Marker> get markerList => makeMarkerList();

  /// Maker for start and end point of track
  List<Marker> makeMarkerList() {
    List<Marker> ml = [];
    List<LatLng> markerPoints = [];

    if (trackService.gpxFileData.gpxLatlng.length > 0 ) {
      markerPoints.add(trackService.gpxFileData.gpxLatlng.first);
      markerPoints.add(trackService.gpxFileData.gpxLatlng.last);


      for (var i = 0; i < markerPoints.length; i++) {
        Marker newMarker = Marker(
            width: 40.0,
            height: 40.0,
            point: markerPoints[i],
            builder: (ctx) =>
                Container(
                  child: GestureDetector(
                    onTap: () {
                      _handleTapOnMarker(markerPoints[i], i);
                    },
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blueAccent,
                    ),
                  ),
                )
        );
        ml.add(newMarker);
      }
    }

    return ml;
  }

  /// Return current positon a marker
  ///
  List<Marker> get gpsPositionList => makeGpsPositionList();

  List<Marker> makeGpsPositionList() {
    List<Marker> ml = [];

    if (_location == true && _currentPosition != null) {
      Marker newMarker = Marker(
        width: 40.0,
        height: 40.0,
        point: _currentPosition,
        builder: (ctx) =>
            Container(
              child: Icon(
                Icons.location_on,
                color: Colors.orangeAccent,
              ),
            )

      );
      ml.add(newMarker);
    }
    return ml;
  }

  List<Marker> get wayPointsList => makeWayPointsList();

  List<Marker> makeWayPointsList() {
    List<Marker> ml = [];
    if(trackService.gpxFileData.wayPoints.length > 0) {
      for (var i = 0; i < trackService.gpxFileData.wayPoints.length; i++) {
        Waypoint waypoint = trackService.gpxFileData.wayPoints[i];

        Marker newMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: waypoint.location,
          builder: (ctx) =>
              Container(
                child: Icon(
                  Icons.home,
                  color: Colors.deepOrangeAccent,
                ),
              )
        );
        ml.add(newMarker);
      }
    }
    return ml;
  }
  void _handleTap(LatLng latlng) {
    print("_handleTap at $latlng");
  }

  void _handleLongPress(LatLng latlng) {
    print("_handleLongPress at $latlng");
  }

  void _onTap(String msg, Polyline polyline, LatLng latlng, int polylinePoint) {
    print("_onTap $msg + Polyline $polyline + LatLng $latlng + ploylintPoint $polylinePoint");
  }

  // Tap on marker on maps.
  /// Use coords to get in marker list (_tourGpxData.trackPoints).
  _handleTapOnMarker(LatLng latlng, int index) {
    print('Tap on marker at $latlng with index: $index');
  }


  /// get distance current position to start or end point of track
  double getDistanceTo() {

    //GeoLocationService.gls.getDistanceBetweenCoords(coord1, coord2)
    return 0.0;
  }

}
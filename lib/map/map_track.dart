import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';
//import 'package:path/path.dart' as path;
//import 'package:path_provider/path_provider.dart';

import '../fileIO/directory_list.dart';
import '../track/track_service.dart';
import 'map_statusLayer.dart';
import 'map_scaleElement.dart';
import 'map_infoElement.dart';
import 'map_pointInfo.dart';
import '../fileIO/local_file.dart';

import '../track/geoLocationService.dart';
import '../models/waypoint.dart';
import '../fileIO/settings.dart';

typedef MapPathCallback = void Function(String mapPath);

/// Provide a map view using flutter_map package
///
/// Own position: switch in [MapStatusLayer] and receive message in [streamEvent]
/// In [switchGeolocation] subscribe to [GeoLocationService]
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

  LatLng _circlePosition = LatLng(0.0, 0.0);

  // MapController and plugin layer
  MapController _mapController = MapController();
  MapStatusLayer _mapStatusLayer = MapStatusLayer(false, false, "...", false);
  MapScaleElement _mapScaleElement = MapScaleElement(100.0, "");
  MapInfoElement _mapInfoElement = MapInfoElement(
      point: LatLng(0.0, 0.0),
      color: Colors.blue.withOpacity(0.8),
      borderStrokeWidth: 1.0,
      useRadiusInMeter: true,
      size: Size(100.0, 50.0),
  );

  String _infoText = "_infoText";
  bool _infoTextDisplay = false;

  //MapInfoElement _mapInfoLayer = MapInfoElement("Content");
  //int scaleWidth;

  LatLng get startPos => widget.trackService.getTrackStart();

  // status values
  bool _offline = false;
  bool _location = false;

  LatLng _currentPosition;
  bool _lastPositions = false;

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
    _mapStatusLayer.status = "Position Off / Online Map / 13";
    //_mapScaleElement.scaleText = "new";
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdataWidget in MapTrack");
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

  ///
  /// lastPositions_on displays last recorded positions
  ///
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

          case "zoom_in" :
            _mapController.move(_mapController.center, _mapController.zoom + 1.0);
            _mapStatusLayer.zoomNotification(_mapController.zoom.toInt());
            setState(() {

            });
//            calculateScale();
            break;

          case "zoom_out" :
            _mapController.move(_mapController.center, _mapController.zoom - 1.0);
            setState(() {
              //calculateScale();
            });
            break;

          case "lastPositions_on" :
            if (_lastPositions) {
              _lastPositions = false;
            } else {
              //trackService.setLastLocations();
              if (trackService.lastPositions.length > 0 && !_lastPositions ){
                _lastPositions = true;
              }
            }

            _mapStatusLayer.statusNotification(event.msg, _lastPositions);
            setState(() {

            });
            break;
        }
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
      GeoLocationService.gls.unsubscribeToPositionStream();
      trackService.currentPosition = null;
    }
  }

  bool getGeoLocationStreamState() {
    return true;
  }

  /// Current geo location from [GeoLocationService] as [Position].
  /// Update [gpsPositionList] and center map on [currentPosition].
  /// Add [coords] to [lastPositions] in [trackService]
  onGeoLocationEvent(Position coords) {
    if (_location) {
      _currentPosition = LatLng(coords.latitude, coords.longitude);
      setState(() {
        gpsPositionList;
        _mapController.move(_currentPosition, _mapController.zoom);
        trackService.currentPosition = _currentPosition;
        trackService.addPosition(LatLng(coords.latitude, coords.longitude));
        checkDistanceToTrack(_currentPosition);
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
          minZoom: 7,
          maxZoom: 18,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onPositionChanged: _handlePositionChange,

          plugins: [
            _mapInfoElement,
            _mapStatusLayer,
            _mapScaleElement,
          ],
        ),
        layers: [
          TileLayerOptions(
            //offlineMode: _offline,
            tileProvider: _offline ? FileTileProvider() : CachedNetworkTileProvider(),
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
              ),
              Polyline(
                points: _lastPositions ? widget.trackService.lastPositions : [],
                strokeWidth: 4.0,
                color: Colors.green,
              )
            ],
            onTap: (Polyline polyline, LatLng latlng, int polylineIdx ) => _onTap("track", polyline, latlng, polylineIdx)
          ),
          MapInfoLayerOptions(
            mapInfoElements: mapInfoElements,
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
//          CircleLayerOptions(
//            circles: circleMarkers,
//          ),
//          MapPointInfoLayerOptions(
//            mapPointInfos: mapPointInfo,
//          ),
//          MapInfoLayerOptions(
//            mapInfoElements: _infoTextDisplay ? mapInfoElements : mapInfoElements,
//          ),

          MapStatusLayerOptions(
            streamController: streamController,
            //_mapStatusLayer.zoom["zoom"] = 12,
            //locationOn: false,
            //offline: false,
          ),
          MapScaleElementOptions(
            streamController: streamController,
            mapState: MapState(
                MapOptions(
                  zoom: _mapController.ready == false ? 13 : _mapController.zoom,
                  center: _mapController.ready == false ? startPos : _mapController.center,
                )
            )
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

  /// Return current positon as marker
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

  /// Waypoint marker
  List<Marker> get wayPointsList => makeWayPointsList();

  List<Marker> makeWayPointsList()  {
    List<Marker> ml = [];

    //trackService.getTrackWayPoints();
    if(trackService.gpxFileData.wayPoints.length > 0) {
      for (var i = 0; i < trackService.gpxFileData.wayPoints.length; i++) {
        Waypoint waypoint = trackService.gpxFileData.wayPoints[i];

        Marker newMarker = Marker(
          width: 80.0,
          height: 80.0,
          point: waypoint.location,
          builder: (ctx) =>
              Container(
                child: GestureDetector(
                  onTap: () {
                    _handleTapOnWayPoint(i);
                  },
                  child: Icon(
                    waypoint.type == null ? Icons.home : getTypeIcon(waypoint.type),
                    color: Colors.deepOrangeAccent,
                  ),
                )

              )
        );
        ml.add(newMarker);
      }
    }
    return ml;
  }

  List<CircleMarker> get circleMarkers => makeCircleMarkers();

  List<CircleMarker> makeCircleMarkers() {
    var circleMarkers = <CircleMarker>[
      CircleMarker(
        point: _circlePosition,
        color: Colors.blue.withOpacity(0.7),
        borderStrokeWidth: 2.0,
        useRadiusInMeter: true,
        radius: 100
      ),
    ];
    return circleMarkers;
  }

//  List<MapPointInfo> get mapPointInfo => makeMapPointInfo();
//
//  List<MapPointInfo> makeMapPointInfo() {
//    var mapPointInfo = <MapPointInfo>[
//      MapPointInfo(
//          point: _circlePosition,
//          color: Colors.blue.withOpacity(0.7),
//          borderStrokeWidth: 1.0,
//          useRadiusInMeter: true,
//          radius: 100
//      ),
//    ];
//    return mapPointInfo;
//  }

  List<MapInfoElement> get mapInfoElements => makeMapInfos();

  List<MapInfoElement> makeMapInfos() {
    var mapInfoElements = <MapInfoElement>[
      MapInfoElement(
          point: _circlePosition,
          color: Colors.white.withOpacity(0.8),
          borderStrokeWidth: 1.0,
          useRadiusInMeter: false,
          size: Size(200.0, 50.0),
          infoText: _infoText,
      ),
    ];
    return mapInfoElements;
  }


  IconData getTypeIcon(String type) {
    switch( type ) {
      case "Shop" :
        return  Icons.shopping_cart;
        break;
      case "Info" :
        return Icons.info;
        break;
      case "Food" :
        return Icons.local_dining;
        break;
      case "Swim" :
        return Icons.pool;
        break;
      case "Warning" :
        return Icons.warning;
        break;
      case "Train" :
        return Icons.train;
      default:
        return Icons.home;
    }

  }


  /// Tap on map (not on marker or polyline)
  ///
  void _handleTap(LatLng latlng) async {
    print("_handleTap at $latlng");

    await trackService.getClosestTrackPoint(latlng)
    .then((dist) {
      print("Index: ${dist[0]}, Distance in meter: ${dist[1]}");
    });

    if (_infoTextDisplay == true) {
      setState(() {
        _circlePosition = LatLng(0.0, 0.0);
        _infoTextDisplay = false;
      });

    }

    streamController.add(TrackPageStreamMsg("tapOnMap", latlng));

  }

  void _handleLongPress(LatLng latlng) {
    print("_handleLongPress at $latlng");
  }

  void _handlePositionChange(MapPosition mapPosition, bool hasGesture) {
    // , bool isUserGesture
//    print("_handlePositionChange");
//    print(_mapController.zoom);
    _mapStatusLayer.zoomNotification(_mapController.zoom.toInt());
  }

  /// Handle tap on track polyline
  ///
  void _onTap(String msg, Polyline polyline, LatLng latlng, int polylinePoint) async {
    print("_onTap $msg + Polyline $polyline + LatLng $latlng + ploylinePoint $polylinePoint");
    var distance = await trackService.getDistanceFromStart(polylinePoint);
    var distanceToEnd = trackService.trackLength - distance;

//    MapInfoElementState mapInfoElementState = MapInfoElementState(
//      point: _circlePosition,
//      color: Colors.white.withOpacity(0.8),
//      borderStrokeWidth: 1.0,
//      useRadiusInMeter: false,
//      size: Size(200.0, 50.0),
//      infoText: "Distance start: ${distance.toInt().toString()} meter.",
//    );
//
//    streamController.add(TrackPageStreamMsg("tapOnTrack", mapInfoElementState));


    //distance = distance.toInt();
    _infoTextDisplay = true;
    setState(() {
      _circlePosition = latlng;
      _infoText = "Distance start: ${distance.toInt().toString()} meter \nDistance end: ${distanceToEnd.toInt().toString()} meter";

    });

//    showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return SimpleDialog(
//            titlePadding: EdgeInsets.only(top: 12.0, bottom: 6.0, left: 12.0),
//            title: Text("Distance", textAlign: TextAlign.center,),
//            contentPadding: EdgeInsets.only(left: 12.0, bottom: 6.0),
//            children: <Widget>[
//
//              Text("${distance.toInt()} meter from start point."),
//              Text ("${(trackService.trackLength - distance).toInt()} meter to end point."),
//            ],
//          );
//    });
  }

//  Widget get distanceWidget {
//    return Container(
//      child: Text("distanceWidget"),
//    );
//  }

  // Tap on marker on maps.
  /// Use coords to get in marker list (_tourGpxData.trackPoints).
  _handleTapOnMarker(LatLng latlng, int index) {
    print('Tap on marker at $latlng with index: $index');
    setState(() {

    });
  }


  /// Tap on waypoint icon
  /// Message to [MapPage] and center map to waypoint position
  ///
  /// [index] positon in [TrackService.gpxFileData.wayPoints]
  _handleTapOnWayPoint(int index) {
    print ("Tap on waypoint with index $index");
    streamController.add(TrackPageStreamMsg("wayPointAction", index));
    _mapController.move(trackService.gpxFileData.wayPoints[index].location, _mapController.zoom);
  }


  /// get distance current position to start or end point of track
  double getDistanceTo() {

    //GeoLocationService.gls.getDistanceBetweenCoords(coord1, coord2)
    return 0.0;
  }

  checkDistanceToTrack(LatLng latlng) async {
    await trackService.getClosestTrackPoint(latlng)
        .then((dist) {
      print("Index: ${dist[0]}, Distance in meter: ${dist[1]}");
      if (dist[1] > Settings.settings.distanceToTrackAlert) {
        print("Alert distance!!!");
        SystemSound.play(SystemSoundType.click);
      }
    });
  }
}
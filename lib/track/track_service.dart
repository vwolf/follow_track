import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track.dart';
import '../models/track_coord.dart';
import '../gpx/gpx_parser.dart';
import '../gpx/read_file.dart';
import '../fileIO/local_file.dart';


/// Service used by [Map]
class TrackService {

  final Track track;
  TrackService(this.track);

  GpxFileData gpxFileData = GpxFileData();

  String pathToOfflineMap;

  // List of coord's
  List<TrackCoord> trackCoords = [];
  // List of LatLng
  List<LatLng> trackLatLngs = [];

  // track info's
  double trackLength = 0.0;

  /// Read file and parse into TourGpxData.
  ///
  /// Convert GpxCoords to [LatLng].
  /// [path] path to file.
  void getTrack(String path)  {
    // read file
    final fc =  ReadFile().readFile(path);
    fc.then((contents) {
      print("read setting: $fc ");
      gpxFileData = new GpxParser(contents).parseData();
      print(gpxFileData.gpxCoords.length);
      // create LatLng points for track
      gpxFileData.coordsToLatlng();
      getTrackDistance();
    });
    // parse file
    //var gpxFileDataRe =  new GpxParser(fc).parseData();
//    gpxFileData = new GpxParser(fc).parseData();
//
//    print(gpxFileData.gpxCoords.length);
//    // create LatLng points for track
//    gpxFileData.coordsToLatlng();
//    getTrackDistance();
  }

  /// Return first position of [Track]
  ///
  LatLng getStartCoord() {
    if (trackLatLngs.length > 0) {
      return trackLatLngs[0];
    }

    return LatLng(0.0, 0.0);
  }

  /// Return first position in parsed gpx file
  ///
  LatLng getTrackStart() {
    if (gpxFileData.gpxLatlng.length > 0 ) {
      return gpxFileData.gpxLatlng.first;
    } else {
      print("getTrackStart gpxFileData.gpxLatLng length = 0");
    }
  }

  /// Return the distance beteen two track points
  double getDistanceBetweenPoints(LatLng start, LatLng end) {
    double distance = 0.0;


    return distance;
  }

  /// Return length of whole track
  getTrackDistance() async {
    double totalDistance = 0;
    double totalDistanceGeo = 0;
    for (var i = 0; i < gpxFileData.gpxLatlng.length - 1; i++ ) {

      totalDistance += Distance().distance(gpxFileData.gpxLatlng[i], gpxFileData.gpxLatlng[i + 1]);
      totalDistanceGeo += await Geolocator().distanceBetween(gpxFileData.gpxLatlng[i].latitude, gpxFileData.gpxLatlng[i].longitude,
          gpxFileData.gpxLatlng[i + 1].latitude, gpxFileData.gpxLatlng[i + 1].longitude);


    }

    print ("totalDistance: $totalDistance");
    print ("totalDistance in meters: $totalDistanceGeo");
    trackLength = totalDistanceGeo;
  }


  /// Get the boundaries of track
  /// 1. Try gpx file ToDo
  /// 2. Calculate using parsed gpx file
  getTrackBoundingCoors() {
    double lat_min = double.infinity;
    double lat_max = 0.0;
    double lon_min = double.infinity;
    double lon_max = 0.0;

    for ( LatLng waypoints in gpxFileData.gpxLatlng) {
      lat_min = min(lat_min, waypoints.latitude);
      lat_max = max(lat_max, waypoints.latitude);
      lon_min = min(lon_min, waypoints.longitude);
      lon_max = max(lon_max, waypoints.longitude);
    }

    print("track ${track.name} boundaris are $lat_min, $lat_max, $lon_min, $lon_max");

    /// text latlon to tiles
    var n = pow(2, 13);
    var xTile = n * ((lon_min + 180.0) / 360);
    var lat_min_rad = lat_min / 180 * pi;
    var yTile = n * (1.0 - (log(tan(lat_min_rad) + (1 / cos(lat_min_rad))) / pi)) / 2;
    print(xTile.toInt());
    print(yTile.toInt());
  }

}


/// Stream messages
class TrackPageStreamMsg {
  String type;
  var msg;

  TrackPageStreamMsg(this.type, this.msg);
}


class Utils {

  /// Read gpx file and return [Track]
  ///
  Future<Track> getTrackMetaData(String gpxFilePath) async {
    var fc = await ReadFile().readFile(gpxFilePath);
    GpxFileData gpxFileData = new GpxParser(fc).parseData();

    Track aTrack = Track();
    aTrack.name = gpxFileData.trackName;
    aTrack.location = gpxFileData.trackSeqName == null ? "" : gpxFileData.trackSeqName;

    aTrack.coords = jsonEncode( {"lat": gpxFileData.defaultCoord.latitude, "lon": gpxFileData.defaultCoord.longitude} );
    aTrack.gpxFilePath = gpxFilePath;

    return aTrack;
  }

  readMetaData() {

  }
}
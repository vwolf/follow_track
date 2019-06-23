import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';
import '../models/track_coord.dart';
import '../models/waypoint.dart';
import '../gpx/gpx_parser.dart';
import '../gpx/gpxx_parser.dart';
import '../gpx/read_file.dart';
import 'geoLocationService.dart';

import '../fileIO/local_file.dart';

/// Service used by [Map]
class TrackService {
  final Track track;
  TrackService(this.track);

  GpxFileData gpxFileData = GpxFileData();

  String pathToOfflineMap;
  String pathToTracksDirectory;

  // List of coord's
  List<TrackCoord> trackCoords = [];
  // List of LatLng
  List<LatLng> trackLatLngs = [];

  // track info's
  double trackLength = 0.0;

  LatLng currentPosition;

  /// Read file and parse into TourGpxData.
  ///
  /// Convert GpxCoords to [LatLng].
  /// [path] path to file.
  Future<void> getTrack(String path, String tracksDirectoryPath) async {
    pathToTracksDirectory = tracksDirectoryPath;
    await ReadFile().readFile(path).then((contents) {
      print("read setting: $contents ");
      gpxFileData = new GpxParser(contents).parseData();
      print(gpxFileData.gpxCoords.length);
      // create LatLng points for track
      gpxFileData.coordsToLatlng();
      getTrackDistance();

      //getTrackWayPoints();
    }).whenComplete(() {
      return true;
    });

    // read file
//    final fc = await  ReadFile().readFile(path);
//    fc.then((contents) {
//      print("read setting: $fc ");
//      gpxFileData = new GpxParser(contents).parseData();
//      print(gpxFileData.gpxCoords.length);
//      // create LatLng points for track
//      gpxFileData.coordsToLatlng();
//      getTrackDistance();
//
//      getTrackWayPoints();
//    }).whenComplete(() {
//      return true;
//    });
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
    if (gpxFileData.gpxLatlng.length > 0) {
      return gpxFileData.gpxLatlng.first;
    } else {
      print("getTrackStart gpxFileData.gpxLatLng length = 0");
    }
  }

  /// Return the distance beteen two track points
  Future getDistanceBetweenPoints(LatLng start, LatLng end) async {
    double distance = 0.0;

    distance = await Geolocator().distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
    return distance;
  }

  /// Return length of whole track
  getTrackDistance() async {
    double totalDistance = 0;
    double totalDistanceGeo = 0;
    for (var i = 0; i < gpxFileData.gpxLatlng.length - 1; i++) {
      totalDistance += Distance()
          .distance(gpxFileData.gpxLatlng[i], gpxFileData.gpxLatlng[i + 1]);
      totalDistanceGeo += await Geolocator().distanceBetween(
          gpxFileData.gpxLatlng[i].latitude,
          gpxFileData.gpxLatlng[i].longitude,
          gpxFileData.gpxLatlng[i + 1].latitude,
          gpxFileData.gpxLatlng[i + 1].longitude);
    }

    print("totalDistance: $totalDistance");
    print("totalDistance in meters: $totalDistanceGeo");
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

    for (LatLng waypoints in gpxFileData.gpxLatlng) {
      lat_min = min(lat_min, waypoints.latitude);
      lat_max = max(lat_max, waypoints.latitude);
      lon_min = min(lon_min, waypoints.longitude);
      lon_max = max(lon_max, waypoints.longitude);
    }

    print(
        "track ${track.name} boundaris are $lat_min, $lat_max, $lon_min, $lon_max");

    /// text latlon to tiles
    var n = pow(2, 13);
    var xTile = n * ((lon_min + 180.0) / 360);
    var lat_min_rad = lat_min / 180 * pi;
    var yTile =
        n * (1.0 - (log(tan(lat_min_rad) + (1 / cos(lat_min_rad))) / pi)) / 2;
    print(xTile.toInt());
    print(yTile.toInt());
  }

  /// Find closest point on track
  /// Get distance between point on polyline and latlng
  ///
  /// Return List[index, distance]
  Future<List<num>> getClosestTrackPoint(LatLng latlng) async {
    double minDist = double.maxFinite;
    int pointIdx;

    for (var i = 0; i < gpxFileData.gpxLatlng.length; i++) {
      await GeoLocationService.gls.getDistanceBetweenCoords(latlng, gpxFileData.gpxLatlng[i])
          .then((result) {
        double dist = result.truncateToDouble();
        //print(dist);
        if (dist < minDist) {
          minDist = dist;
          pointIdx = i;
        }
      });
    }

    return Future.value([pointIdx, minDist]);
  }


  /// Read data with way point data
  /// Waypoint data in directory with track name
  /// 1. Get all gpx files
  /// 2. Send to parser => parseWpts()
  ///
  /// [wayPointDirectory]
  /// [callBack]
  Future getTrackWayPoints(String wayPointDirectory, callBack) async {
    List<String> wayPointsFiles = [];

    Directory(wayPointDirectory)
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
          if(path.extension(entity.path) == '.gpx') {
            wayPointsFiles.add(entity.path);
          }
        }).onDone(() {
          if (wayPointsFiles.length > 0) {
            parseWpts(wayPointsFiles, callBack);
          } else {
            callBack(this);
          }
        });
  }


  parseSingleWpts(String wayPointFilePath) async {
    await ReadFile().readFile(wayPointFilePath)
    .then((contents) {
      List<Waypoint> newWaypoints = new GpxxParser(contents).parseData();
      gpxFileData.addWaypoint(newWaypoints);
    });

  }

  Future parseWpts(List<String> wayPointsFiles, callback) async {
    if (wayPointsFiles.length > 0) {
      for (var i = 0; i < wayPointsFiles.length; i++) {
        await ReadFile().readFile(wayPointsFiles[i])
        .then((contents) {
          List<Waypoint> newWaypoints = new GpxxParser(contents).parseData();
          print(newWaypoints.length);
          gpxFileData.addWaypoint(newWaypoints);
        });
      }
      callback(this);
    }
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
    aTrack.location =
        gpxFileData.trackSeqName == null ? "" : gpxFileData.trackSeqName;

    aTrack.coords = jsonEncode({
      "lat": gpxFileData.defaultCoord.latitude,
      "lon": gpxFileData.defaultCoord.longitude
    });
    aTrack.gpxFilePath = gpxFilePath;

    return aTrack;
  }

  readMetaData() {}
}

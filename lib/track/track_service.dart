import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;

import '../models/track.dart';
import '../models/track_coord.dart';
import '../models/waypoint.dart';
import '../gpx/gpx_parser.dart';
import '../gpx/gpxx_parser.dart';
import '../gpx/read_file.dart';
import 'geoLocationService.dart';


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

  /// Save x locations in a list to display last steps
  List<LatLng> lastPositions = [];
  int positionsToSave = 24;

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
    return null;
  }

  /// Return the distance beteen two track points
  Future getDistanceBetweenPoints(LatLng start, LatLng end) async {
    double distance = 0.0;

    distance = await Geolocator().distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
    return distance;
  }

  /// Return length of whole track
  ///
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

  /// Return the distance from polyline point to start of track
  Future<double> getDistanceFromStart(int polylinePoint) async {
    double totalDistance = 0;

    for (var i = 0; i < polylinePoint -1; i++) {
      totalDistance += await Geolocator().distanceBetween(
          gpxFileData.gpxLatlng[i].latitude,
          gpxFileData.gpxLatlng[i].longitude,
          gpxFileData.gpxLatlng[i + 1].latitude,
          gpxFileData.gpxLatlng[i + 1].longitude);
    }

    print("Distance from track start to point $polylinePoint is $totalDistance");
    return totalDistance;
  }


  /// Get the boundaries of track
  /// 1. Try gpx file ToDo
  /// 2. Calculate using parsed gpx file
  getTrackBoundingCoors() {
    double latMin = double.infinity;
    double latMax = 0.0;
    double lonMin = double.infinity;
    double lonMax = 0.0;

    for (LatLng waypoints in gpxFileData.gpxLatlng) {
      latMin = min(latMin, waypoints.latitude);
      latMax = max(latMax, waypoints.latitude);
      lonMin = min(lonMin, waypoints.longitude);
      lonMax = max(lonMax, waypoints.longitude);
    }

    print(
        "track ${track.name} boundaris are $latMin, $latMax, $lonMin, $lonMax");

    /// text latlon to tiles
    var n = pow(2, 13);
    var xTile = n * ((lonMin + 180.0) / 360);
    var latMinRad = latMin / 180 * pi;
    var yTile =
        n * (1.0 - (log(tan(latMinRad) + (1 / cos(latMinRad))) / pi)) / 2;
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
    // does wayPointDirectory exist?
    if (Directory(wayPointDirectory).existsSync()) {
      Directory(wayPointDirectory)
          .list(recursive: false, followLinks: false)
          .listen((FileSystemEntity entity) {
        if(path.extension(entity.path) == '.gpx') {
          wayPointsFiles.add(entity.path);
        }
      }).onDone(() {
        if (wayPointsFiles.length > 0) {
          parseWpts(wayPointsFiles, callBack, wayPointDirectory).then((r) {
            callBack(this);
          });
        } else {
          callBack(this);
        }
      });
    } else {
      callBack(this);
    }
  }


  parseSingleWpt(String wayPointFilePath) async {
    await ReadFile().readFile(wayPointFilePath)
    .then((contents) {
      List<Waypoint> newWaypoints = new GpxxParser(contents).parseData();
      gpxFileData.addWaypoint(newWaypoints);
    });

  }

  /// Parse list of waypoint files
  ///
  /// [waypointFiles]
  Future parseWpts(List<String> wayPointsFiles, callback, waypointsDirectory) async {
    if (wayPointsFiles.length > 0) {
      for (var i = 0; i < wayPointsFiles.length; i++) {
        await ReadFile().readFile(wayPointsFiles[i])
        .then((contents) {
          List<Waypoint> newWaypoints = new GpxxParser(contents).parseData();
          print(newWaypoints.length);
          for (var i = 0; i < newWaypoints.length; i++) {
            newWaypoints[i].filePath = waypointsDirectory;
          }
          gpxFileData.addWaypoint(newWaypoints);
        });
      }
      //callback(this);
    }
  }

  /// Add current [LatLng] to [lastLocations] list
  addPosition(LatLng currentPosition) {
    lastPositions.add(currentPosition);

    if ( lastPositions.length > positionsToSave) {
      lastPositions.removeAt(0);
    }
  }

  // this is just for testing no-sf-s12-11
  setLastLocations() {
    lastPositions = [];
    lastPositions.add(LatLng(59.272603299, 14.80785219));
    lastPositions.add(LatLng(59.273079392, 14.807238886));
    lastPositions.add(LatLng(59.273290448, 14.805954695));
    lastPositions.add(LatLng(59.273043433, 14.804689363));
    lastPositions.add(LatLng(59.272715533, 14.804306058));
    lastPositions.add(LatLng(59.272913178, 14.803261422));
    lastPositions.add(LatLng(59.272688627, 14.801070141));
    lastPositions.add(LatLng(59.272221504, 14.799431395));
    lastPositions.add(LatLng(59.268772267, 14.796442743));
    lastPositions.add(LatLng(59.267294537, 14.79602105));
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

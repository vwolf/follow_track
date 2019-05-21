import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:latlong/latlong.dart';

import '../models/track.dart';
import '../models/track_coord.dart';
import '../gpx/gpx_parser.dart';
import '../gpx/read_file.dart';

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

  /// Read file and parse into TourGpxData.
  ///
  /// Convert GpxCoords to [LatLng].
  /// [path] path to file.
  void getTrack(String path) async {
    // read file
    final fc = await ReadFile().readFile(path);

    // parse file
    gpxFileData = await new GpxParser(fc).parseData();
    print(gpxFileData.gpxCoords.length);
    // create LatLng points for track
    gpxFileData.coordsToLatlng();
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

  /// Return length of track
  getTrackDistance() {}
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
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

/// Service to subscribe / unsubscribe to stream of positions
///
class GeoLocationService {

  GeolocationStatus status = GeolocationStatus.unknown;
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10,
  );

  LatLng location = new LatLng(0.00, 0.00);

  /// Save x locations in a list to display last steps
  List<Position> lastLocations = [];
  int positionToSave = 24;

  StreamSubscription<Position> _positionStream;
  StreamController trackerStream;

  GeoLocationService._();
  static final GeoLocationService gls = GeoLocationService._();

  //GeolocationStatus _geolocationStatus;

  cleanUp() {
    _positionStream.cancel();
    trackerStream.close();
  }

  /// Subscribe to position stream
  ///
  /// [streamToParent]
  subscribeToPositionStream( [StreamController streamToParent]) {
    trackerStream = streamToParent;
    _positionStream = geolocator.getPositionStream(locationOptions)
        .listen((Position _position) {
      print(_position == null ? 'Unknown' : _position.latitude.toString() + ', ' + _position.longitude.toString());
      if (_position != null) {
        if ( streamToParent != null ) {
          trackerStream.add(_position);
        }//

      }
    });
  }

  /// Unsubscribe from postion stream
  ///
  unsubscribeToPositionStream() {
    if (_positionStream != null ) {
      _positionStream.cancel();
    }
  }

  /// Get distance between coordinates
  ///
  /// [coord1] start position
  /// [coord2] end position
  Future<double> getDistanceBetweenCoords(LatLng coord1, LatLng coord2) async {
    var dist = await Geolocator().distanceBetween(coord1.latitude, coord1.longitude, coord2.latitude, coord2.longitude);
    return dist;
  }


}

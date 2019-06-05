import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

class GeoLocationService {

  GeolocationStatus status = GeolocationStatus.unknown;
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10,
  );

  LatLng location = new LatLng(0.00, 0.00);

  StreamSubscription<Position> _positionStream;
  StreamController trackerStream;

  GeoLocationService._();
  static final GeoLocationService gls = GeoLocationService._();

  GeolocationStatus _geolocationStatus;

  cleanUp() {
    _positionStream.cancel();
    trackerStream.close();
  }

  subscribeToPositionStream( [StreamController streamToParent]) {
    trackerStream = streamToParent;
    _positionStream = geolocator.getPositionStream(locationOptions)
        .listen((Position _position) {
      print(_position == null ? 'Unknown' : _position.latitude.toString() + ', ' + _position.longitude.toString());
      if (_position != null) {
        if ( streamToParent != null ) {
          trackerStream.add(_position);
        }
        //

      }
    });
  }

  unsubcribeToPositionStream() {
    if (_positionStream != null ) {
      _positionStream.cancel();
    }
  }

  /// Get distance between coordinates
  Future<double> getDistanceBetweenCoords(LatLng coord1, LatLng coord2) async {
    double distanceInMeters = 1.0;
    var dist = await Geolocator().distanceBetween(coord1.latitude, coord1.longitude, coord2.latitude, coord2.longitude);
    return dist;
    print("dist: $dist");
//    .then((result) {
//      distanceInMeters = result;
//      return distanceInMeters;
//    });

   // return distanceInMeters;
  }
}

import 'package:latlong/latlong.dart';

class Waypoint {

  String name;
  LatLng location;
  String type;
  String color;
  String description;

  Waypoint({
    this.name,
    this.location,
    this.type,
    this.color,
    this.description
  });

}
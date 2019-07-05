import 'package:latlong/latlong.dart';

class Waypoint {

  String filePath;
  String name;
  LatLng location;
  String type;
  String color;
  String description;
  List<String> image;

  Waypoint({
    this.filePath,
    this.name,
    this.location,
    this.type,
    this.color,
    this.description,
    this.image,
  });

}
import 'package:latlong/latlong.dart';

class Waypoint {

  /// [filePath] path waypoint file
  /// [name] name of waypoint
  /// [location] [LatLng] of waypoint
  /// [type] type of waypoint (Shop, Info, Food) default: Home
  /// Used for waypoint icon
  /// [color] icon color
  /// [description]
  /// [image] images for waypoint
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
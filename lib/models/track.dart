import 'dart:convert';

/// Track properties
///
class Track {

  int id;
  String name;
  String description;
  DateTime timestamp;
  bool open;
  String location;
  String tourImage;
  String gpxFilePath;
//  String options;
  String coords;
//  String track;
//  String items;
  String createdAt;

  Track({
    this.id,
    this.name,
    this.description,
    this.timestamp,
    this.open,
    this.location,
    this.tourImage,
    this.gpxFilePath,
//    this.options,
    this.coords,
//    this.track,
//    this.items,
    this.createdAt,
  });

}
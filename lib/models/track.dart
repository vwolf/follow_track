
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
  String offlineMapPath;
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
    this.offlineMapPath,
//    this.options,
    this.coords,
//    this.track,
//    this.items,
    this.createdAt,
  });

}
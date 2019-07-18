
/// Point on track
///
class TrackCoord {
  int id;
  double latitude;
  double longitude;
  double altitude;
  DateTime timestamp;
  double accuracy;
  double heading;
  double speed;
  double speedAccuracy;
  int item;

  TrackCoord({
    this.id,
    this.latitude,
    this.longitude,
    this.altitude,
    this.timestamp,
    this.accuracy,
    this.heading,
    this.speed,
    this.speedAccuracy,
    this.item,
  });
}
import 'package:path_provider/path_provider.dart';

class Settings {

  String pathToTracks = "/Tracks";
  int distanceToTrackAlert = 100;
  String pathToMapTiles = "";
  String externalSDCard;

  Settings._();
  static final Settings settings = Settings._();

  set(Map readSettings) {
    if (readSettings.containsKey("pathToTracks")) {
      pathToTracks = readSettings["pathToTracks"];
    }

    if (readSettings.containsKey("distanceToTrackAlert")) {
      distanceToTrackAlert = readSettings["distanceToTrackAlert"];
    }
  }
}
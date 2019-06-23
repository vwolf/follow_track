class Settings {

  String pathToTracks = "";
  int distanceToTrackAlert = 100;


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
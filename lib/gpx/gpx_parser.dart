import 'package:xml/xml.dart' as xml;
import 'package:latlong/latlong.dart';

/// Parser for *.gpx xml files
///
/// xml schemas
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
/// xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
/// points in <trk><trkseg><trkpt> section (trkseg is optional)
///
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3"
/// xmlns:rcxx="http://www.routeconverter.de/xmlschemas/RouteCatalogExtensions/1.0"
/// point in wpt items
///
class GpxParser {
  String gpxData;

  GpxParser(this.gpxData);

  GpxFileData gpxFileData = new GpxFileData();

  /// Start parsing [gpxData]
  GpxFileData parseData() {
    print('Start parsing into GpxFileData.');

    var document = xml.parse(gpxData);
    GpxDocumentType documentType = GpxDocumentType.xsi;

    // xml schema
    var root = document.findElements('gpx');
    root.forEach((xml.XmlElement f) {
      if (f.getAttribute("xmlns:gpxx") != null ) {
        documentType = GpxDocumentType.gpxx;
      }
    });

    // get track name, try <metadata><name>
    String trackName = "";
    Iterable<xml.XmlElement>metadataItems = document.findAllElements('metadata');
    metadataItems.map((xml.XmlElement metadataItem) {
      trackName = getValue(metadataItem.findElements('name'));
        if (trackName == null) {
          trackName = getValue(metadataItem.findElements('desc'));
        }
    }).toList(growable: true);

    // track segment name
    Iterable<xml.XmlElement> items = document.findAllElements('trk');
    items.map((xml.XmlElement item) {
      // no name tag in metadata try <trk><name>
      var name = getValue(item.findElements('name'));
      if (trackName == "" ) {
        trackName = name;
      }
      gpxFileData.trackSeqName = name;
    }).toList(growable: true);

    // gps coordinates
    List<GpxCoords> trkList = List();
    List<LatLng> pointsList = List();

    if (documentType == GpxDocumentType.gpxx) {
      Iterable<xml.XmlElement> wpt = document.findAllElements('wpt');
      trkList = parseGPXX(wpt);
    } else {
      Iterable<xml.XmlElement> trkseg = document.findAllElements('trkseg');
      trkList = parseGPX(trkseg);
    }

    gpxFileData.trackName = trackName != null ? trackName : "?";
    gpxFileData.gpxCoords = trkList;

    return gpxFileData;
  }


  List<GpxCoords> parseGPX(Iterable<xml.XmlElement> trkseq) {
    List<GpxCoords> trkList = List();
    trkseq.map((xml.XmlElement trkpt) {
      Iterable<xml.XmlElement> pts = trkpt.findElements('trkpt');
      pts.forEach((xml.XmlElement f) {
        var ele = getValue(f.findElements('ele'));
        ele = ele == null ? "0.0" : ele;
        trkList.add(GpxCoords(
            double.parse(f.getAttribute('lat')),
            double.parse(f.getAttribute('lon')),
            double.parse(ele)
        ));
      });
    }).toList(growable: true);

    return trkList;
  }

  List<GpxCoords> parseGPXX(Iterable<xml.XmlElement> wpt) {
    List<GpxCoords> wpttrkList = List();
    wpt.forEach((xml.XmlElement f) {
      var ele = getValue(f.findElements('ele'));
      ele = ele == null ? "0.0" : ele;
      wpttrkList.add(GpxCoords(
          double.parse(f.getAttribute('lat')),
          double.parse(f.getAttribute('lon')),
          double.parse(ele)
      ));
    });
    return wpttrkList;
  }

  /// extract node text
  String getValue(Iterable<xml.XmlElement> items) {
    var nodeText;
    items.map((xml.XmlElement node) {
      nodeText = node.text;
    }).toList(growable: true);

    return nodeText;
  }
}



/// Class GpxFileData holds the parsed data from a *.gpx file
class GpxFileData {
  String trackName = "";
  String trackSeqName = "";
  LatLng defaultCoord = LatLng(53.00, 13.10);
  List<GpxCoords> gpxCoords = [];
  List<LatLng> gpxLatlng = [];

  /// convert GpxCoords to LatLng
  coordsToLatlng() {
    gpxLatlng = [];
    gpxCoords.forEach((GpxCoords f) {
      gpxLatlng.add(new LatLng(f.lat, f.lon));
    });
  }
}

/// Class for one gpx point
class GpxCoords {
  double lat;
  double lon;
  double ele;

  GpxCoords(this.lat, this.lon, this.ele);
}


enum GpxDocumentType {
  xsi,
  gpxx
}
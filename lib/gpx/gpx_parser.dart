import 'package:xml/xml.dart' as xml;
import 'package:latlong/latlong.dart';

import '../models/waypoint.dart';

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
    /// parse metadata for common and special infos about track
    /// use: name (string), desc (string), keywords (xsd:string)
    /// author, copyright, link,
    String trackName = "";
    Iterable<xml.XmlElement>metadataItems = document.findAllElements('metadata');
//    if (metadataItems.length > 0) {
//      metadataItems.forEach((f) =>
//      {
//        print("metadata  ${f.name}"),
//        print("metadata.children: ${f.children.length}"),
//        for (var i = 0; i < f.children.length; i++) {
//          print(f.children[i].toString()),
//          print(f.children[i].nodeType.toString()),
//          print(getValue(f.findElements("name"))),
////          if (f.attributes.length > 0) {
////            f.attributes.forEach( (e) => {
////              print("attributs.name: ${e.name}")
////            })
////          }
////          print(f.attributes.forEach((e) => {
////            print("")
////          }))
//        }
//      }
//            //(())print("metadata.attribute: ${f.attributes}"));
//      );
//    }


    metadataItems.map((xml.XmlElement metadataItem) {
      trackName = getValue(metadataItem.findElements('name'));
        if (trackName == null) {
          trackName = getValue(metadataItem.findElements('desc'));
        }
        String description = getValue(metadataItem.findElements("description"));
        gpxFileData.trackDescriptions = description;
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
    //List<LatLng> pointsList = List();

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
  String trackDescriptions = "";
  String trackSeqName = "";
  LatLng defaultCoord = LatLng(53.00, 13.10);
  List<GpxCoords> gpxCoords = [];
  List<LatLng> gpxLatlng = [];
  List<Waypoint> wayPoints = [];

  /// convert GpxCoords to LatLng
  coordsToLatlng() {
    gpxLatlng = [];
    gpxCoords.forEach((GpxCoords f) {
      gpxLatlng.add(new LatLng(f.lat, f.lon));
    });
  }

  addWaypoint(List<Waypoint> newWaypoints) {
    wayPoints.addAll(newWaypoints);
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
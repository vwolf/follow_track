import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:latlong/latlong.dart';
import '../models/waypoint.dart';

class GpxxParser {
  String gpxxData;

  GpxxParser(this.gpxxData);
  String documentType;

  List<Waypoint> waypoints = [];

  /// Start parsing
  parseData() {
    var document = xml.parse(gpxxData);
    
    // get xml schema
    var root = document.findElements('gpx');
    root.forEach((xml.XmlElement f) {
      if (f.getAttribute("xmlns:gpxx") != null) {
        documentType = "gpxx";
      }
    });

    // only proceed if gpxx
    if (documentType == "gpxx") {
      Iterable<xml.XmlElement>items = document.findAllElements('wpt');
      items.map((xml.XmlElement item) {
        // get waypoint name
        var name = getValue(item.findElements('name'));
        if (name != null) {
          Waypoint newWaypoint = Waypoint(name: name);
          double lat = double.parse(item.getAttribute('lat'));
          double lng = double.parse(item.getAttribute('lon'));
//          var pos = {"lat": lat, "lon": lng};
//          String posJson = jsonEncode(pos);
          newWaypoint.location = LatLng(lat, lng);
          waypoints.add(newWaypoint);
        }
      }).toList(growable: true);

      
    } else {
      return null;
    }

    return waypoints;
  }

  /// extract node text
  String getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList(growable: true);
    return textValue;
  }
}
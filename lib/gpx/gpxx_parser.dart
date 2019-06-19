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
        Waypoint newWaypoint = Waypoint(description: "");
        // get waypoint name
        var name = getValue(item.findElements('name'));
        if (name != null) {
          newWaypoint.name = name;
          double lat = double.parse(item.getAttribute('lat'));
          double lng = double.parse(item.getAttribute('lon'));
          newWaypoint.location = LatLng(lat, lng);
          //waypoints.add(newWaypoint);
        }
        // extensions
        //var extension = getValue(item.findElements('extensions'));
        Iterable<xml.XmlElement> extensions = item.findElements('extensions');
        if (extensions != null) {
          //print(extensions);
          extensions.forEach((xml.XmlElement f) {
            print(f.name);

            Iterable<xml.XmlElement> w = f.findElements("gpxx:WaypointExtension");
            if (w != null) {
              w.forEach((xml.XmlElement wf) {
                print(wf.name);
                Iterable<xml.XmlElement> colorNode = wf.findElements("gpxx:DisplayColor");
                colorNode.forEach((xml.XmlElement color) {
                  print(color.name);
                  print(getValue(colorNode));
                  newWaypoint.color = getValue(colorNode);
                });
                Iterable<xml.XmlElement> extensionNode = wf.findElements("gpxx:Extensions");
                extensionNode.forEach((xml.XmlElement extension) {
                  print(extension);
                  print(extension.getAttribute("Description"));
                  newWaypoint.description = extension.getAttribute("Description");
                });
              });
            }

          });
        }
        waypoints.add(newWaypoint);
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
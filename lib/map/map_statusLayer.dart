import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../track/track_service.dart';

typedef SetStatusText = void Function(String status);

class MapStatusLayerOptions extends LayerOptions {
  final StreamController streamController;
//  final bool locationOn;
//  final offline;

  MapStatusLayerOptions({this.streamController});
  //MapStatusLayerOptions({this.streamController, this.locationOn, this.offline});
}

/// Display map status on a map layer and trigger events.
///
/// Offline maps
/// Current position
class MapStatusLayer implements MapPlugin {
  bool locationOn = false;
  bool offline = false;
  String status = "";

  Map<String, int> zoom = { "zoom_min": 1, "zoom_max": 1, "zoom": 1};

  MapStatusLayer(this.locationOn, this.offline, this.status);


  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is MapStatusLayerOptions) {
      return MapStatus(
          streamCtrl: options.streamController,
          locationOn: locationOn,
          offline: offline,
          status: status,
          zoom: {
            "zoom_min": mapState.options.minZoom,
            "zoom_max": mapState.options.maxZoom,
            "zoom": mapState.options.zoom
          }
      );
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapStatusLayerOptions;
  }

  statusNotification(String event, bool value) {
    print("MapStatusLayer statusNotification $event : $value");

    switch(event) {
      case "location_on":
        this.locationOn = value;
        break;
      case "offline_on" :
        this.offline = value;
        break;
      case "zoom_in" :
        //this.zoom["zoom"] = value;
    }

    updateStatusText();
  }

  zoomNotification(int zoomValue) {
    this.zoom['zoom'] = zoomValue;

    updateStatusText();

  }

  updateStatusText() {
    status = "";
    locationOn == true ? status += "Position On" : status += "Position Off";
    status += " / ";
    offline == true ? status +=  "Offline Map" : status += "Online Map";
    status += " / ${zoom['zoom']}";
  }

}


class MapStatus extends StatefulWidget {
  final streamCtrl;
  final locationOn;
  final offline;
  final status;
  final zoom;

  MapStatus({this.streamCtrl, this.locationOn, this.offline, this.status, this.zoom});

  @override
  MapStatusState createState() => MapStatusState();
}


class MapStatusState extends State<MapStatus> {

//  bool get _offline => widget.offline;
//  bool get _position => widget.locationOn;

  String statusText = "Position Off / Online Moduus";
  /// callback function used as a closure
  SetStatusText setStatusText;

  @override
  void initState() {
    super.initState();

    setStatusText = updateStatusText;

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                //statusText,
                widget.status,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12.0),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: Colors.orange,
                  size: 36.0,
                ),
                onPressed: () => iconAction('zoom_in'),
              ),
              IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: Colors.orange,
                  size: 36.0,
                ),
                onPressed: () => iconAction('zoom_out'),
              ),
              IconButton(
                icon: Icon(
                  Icons.offline_pin,
                  color: widget.offline ? Colors.orangeAccent : Colors.black26,
                  size: 36.0,
                ),
                onPressed: () => iconAction('offline_on'),
              ),
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  color: widget.locationOn ? Colors.orangeAccent: Colors.black26,
                  size: 36.0,
                ),
                onPressed: () => iconAction('location_on'),
              ),
              IconButton(
                icon: Icon(
                  Icons.info,
                  color: Colors.orangeAccent,
                  size: 36.0,
                ),
                onPressed: () => iconAction('info_on'),
              ),
            ],
          )
        ],
      ),
    );
  }

  iconAction(String action) {
    widget.streamCtrl.add(TrackPageStreamMsg("mapStatusLayerAction", action));

//    setStatusText = updateStatusText;
//    widget.streamCtrl.add(TrackPageStreamMsg("callback", setStatusText));
  }


  updateStatusText(String newText) {
    print("change the text");
    //widget.status = newText;
    statusText = newText;
    //callback(newText);
  }
}


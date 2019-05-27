import 'dart:async';

import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackList extends StatefulWidget {
  final List<Track> tracks;

  TrackList(this.tracks);

  @override
  TrackListState createState() => TrackListState();
}


class TrackListState extends State<TrackList> {

  List<Track> _tracks = [];

  Future<List<Track>> getTracks() async {
    return widget.tracks;
  }


  Widget build(BuildContext context) {
    return _buildTrackList(context);
  }


  _buildTrackList(context) {
    return ListView.builder(
      itemCount: widget.tracks.length,
      itemBuilder: (BuildContext context, int index) {
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          leading: Container(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(Icons.directions_walk, size: 40.0,
            ),
          ),
          title: Text(
            widget.tracks[index].name,
            style: Theme.of(context).textTheme.headline,
          ),
          subtitle: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  //Text(widget.tracks[index].location),
                  Icon(Icons.map),
                ],
              )
            ],
          ),
//          subtitle: ListView(
//            scrollDirection: Axis.horizontal,
//            children: <Widget>[
//              Text(widget.tracks[index].location),
//              Text("offline"),
//            ],
//          ),
          trailing: Icon(Icons.keyboard_arrow_right, size: 30.0,
          ),
        );
      },

    );
  }
}


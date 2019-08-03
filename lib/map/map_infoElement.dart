import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong/latlong.dart';

class MapInfoElementWidget extends StatelessWidget {
  final MapInfoElementState mapInfoElementState;
  final Stream<Null> stream;

  MapInfoElementWidget(this.mapInfoElementState, this.stream);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (BuildContext context, _) {
        return CustomPaint(
          painter: MapInfoElementPainter(mapInfoElementState),
          size: size,
        );
      },
    );
  }
}

class MapInfoElementPainter extends CustomPainter {
  final MapInfoElementState mapInfoElementState;

  MapInfoElementPainter(this.mapInfoElementState);

  @override
  void paint(Canvas canvas, Size size) {

  }

  @override
  bool shouldRepaint(MapInfoElementPainter other) => false;
}



class MapInfoElementState {

  final LatLng point;
  final Size size;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;
  final String infoText;

  MapInfoElementState({
    this.point,
    this.size,
    this.useRadiusInMeter,
    this.color = const Color(0xFF00FF00),
    this.borderColor = const Color(0x00FF000000),
    this.borderStrokeWidth = 0.0,
    this.infoText = "InfoText",
  });
}
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart' hide Path;


class MapInfoLayerOptions extends LayerOptions {
  final List<MapInfoElement> mapInfoElements;
  final MapState mapState;

  MapInfoLayerOptions({this.mapInfoElements, this.mapState, rebuild})
  : super(rebuild: rebuild);
}


class MapInfoElement implements MapPlugin {

  final LatLng point;
  final Size size;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;
  final String infoText;
  Offset offset = Offset.zero;
  num realRadius = 0;
  MapInfoElement({
    this.point,
    this.size,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFF000000),
    this.infoText = "InfoText",
  });

  @override
  Widget createLayer(LayerOptions options, MapState state, Stream<Null> stream) {
    if (options is MapInfoLayerOptions) {
      return MapInfoLayer(options, state, stream);
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapInfoLayerOptions;
  }
}


class MapInfoLayer extends StatelessWidget {
  final MapInfoLayerOptions mapInfoLayerOptions;
  final MapState map;
  final Stream<Null> stream;
  //final String content;

  MapInfoLayer(this.mapInfoLayerOptions, this.map, this.stream);

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
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, _) {

        var mapInfosWidgets = <Widget>[];
        for (var mapInfoElement in mapInfoLayerOptions.mapInfoElements) {
          var pos = map.project(mapInfoElement.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();
          mapInfoElement.offset = Offset(pos.x.toDouble(), pos.y.toDouble());

//          if (mapInfoElement.useRadiusInMeter) {
//            var r = Distance().offset(mapInfoElement.point, mapInfoElement.radius, 180);
//            var rpos = map.project(r);
//            rpos = rpos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
//                map.getPixelOrigin();
//
//            mapInfoElement.realRadius = rpos.y - pos.y;
//          }

          mapInfosWidgets.add(
            CustomPaint(
             painter: MapInfoPainter(mapInfoElement),
              size: size,
            ),
          );
        }

//        return Container(
//          child: Material(
//            elevation: 1.0,
//            child: Stack(
//              children: mapInfosWidgets,
//            ),
//          ),
//        );

//      return Material(
//        elevation: 12.0,
//        child: Container(
//          child: Stack(
//            children: mapInfosWidgets,
//          ),
//        ),
//      );

        return Container(
          child: Stack(
           children: mapInfosWidgets,
          ),
        );
      },
    );
  }
}


class MapInfoPainter extends CustomPainter {
  final MapInfoElement mapInfoElement;

  MapInfoPainter(this.mapInfoElement);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = mapInfoElement.color;

//    _paintCircle(canvas, mapInfoElement.offset,
//        mapInfoElement.useRadiusInMeter ? mapInfoElement.realRadius : mapInfoElement.radius, paint);

    _paintRect(canvas, mapInfoElement.offset, mapInfoElement.size, paint);

    if (mapInfoElement.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = mapInfoElement.borderColor
        ..strokeWidth = mapInfoElement.borderStrokeWidth;

//      _paintCircle(canvas, mapInfoElement.offset,
//          mapInfoElement.useRadiusInMeter ? mapInfoElement.realRadius : mapInfoElement.radius, paint);

      _paintRect(canvas, mapInfoElement.offset, mapInfoElement.size, paint);
    }

    paint.color = Colors.red;
    _paintCircle(canvas, mapInfoElement.offset, 4.0, paint);


    //_paintParagraph(canvas, mapInfoElement.offset, "Hallo");
    _paintText(canvas, mapInfoElement.offset, mapInfoElement.infoText);
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  void _paintRect(Canvas canvas, Offset offset, Size size, Paint paint) {
    var rect = offset & size;
    //canvas.drawRect(rect, paint);
    var rrect = RRect.fromRectAndRadius(rect, Radius.circular(6.0));
    canvas.drawRRect(rrect, paint);
  }

  void _paintParagraph(Canvas canvas, Offset offset, String text) {
    ParagraphBuilder paragraphBuilder = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.left, textDirection: TextDirection.ltr))
    ..addText(text);

    Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ParagraphConstraints(width: 200.0));
    Offset nullOffset = Offset(0.0, 0.0);
    canvas.drawParagraph(paragraph, offset);
  }

  void _paintText(Canvas canvas, Offset offset, String text) {

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: Colors.black, fontSize: 12.0)),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr
    )..layout(maxWidth: 200.0 - 24.0);

    offset = offset + Offset(12.0, 12.0);
    textPainter.paint(canvas, offset);
  }


  @override
  bool shouldRepaint(MapInfoPainter other) => false;
}

class MapPointInfo {}
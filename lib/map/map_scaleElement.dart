import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

class MapScaleElementOptions extends LayerOptions {
  final StreamController streamController;

  MapScaleElementOptions({this.streamController});
}

class MapScaleElement implements MapPlugin {

  MapScaleElement();

  @override
  Widget createLayer(LayerOptions options, MapState state, Stream<Null> stream) {
    if (options is MapScaleElementOptions) {
      return MapScale(

      );
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapScaleElementOptions;
  }

}


class MapScale extends StatefulWidget {
  final streamCtrl;

  MapScale({this.streamCtrl});

  @override
  MapScaleState createState() => MapScaleState();
}



class MapScaleState extends State<MapScale> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(padding: EdgeInsets.only(left: 6.0, bottom: 4.0),
        child: _customPainter,
      )
      //child: _customPainter
//      child: Container(
//        alignment: Alignment.center,
//        color: Colors.lightBlue,
//        height: 30.0,
//        width: 100.0,
//
//      ),
    );
  }

  Widget get _customPainter {
    return CustomPaint(

        child: Container(
          alignment: Alignment.center,
          child: Text("100 meter", style: TextStyle(fontWeight: FontWeight.bold),),
          height: 30.0,
          width: 200.0,
        ),

      painter: ScaleElementPainter(),
    );
  }
}


class ScaleElementPainter extends CustomPainter {



  @override
  void paint(Canvas canvas, Size size) {

    Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.4);
    //path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);
    path.close();

    final Paint paint = Paint();


    var center = Offset(size.width / 2, size.height / 2);
    paint.color = Colors.lightBlue;
    canvas.drawRect(Rect.fromPoints(Offset(0.0, 0.0), Offset(size.width, size.height)), paint);

    paint.color = Colors.deepOrange;
    canvas.drawCircle(center, size.height / 2, paint);

    paint.color = Colors.black;
    paint.strokeWidth = 2;
    //canvas.drawPath(path, paint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), paint);

    canvas.drawLine(Offset(paint.strokeWidth/2, size.height * 0.2), Offset(paint.strokeWidth/2, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width - paint.strokeWidth/2, size.height * 0.2), Offset(size.width - paint.strokeWidth/2, size.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

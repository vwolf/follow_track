import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

class MapScaleElementOptions extends LayerOptions {
  final StreamController streamController;
  final MapState mapState;

  MapScaleElementOptions({this.streamController, this.mapState});
}
/// Scale element for map layer
class MapScaleElement implements MapPlugin {

  double scaleWidth = 100;
  String scaleText = "";

  MapScaleElement(this.scaleWidth, this.scaleText);

  @override
  Widget createLayer(LayerOptions options, MapState state, Stream<Null> stream) {
    if (options is MapScaleElementOptions) {
      return MapScale(
        streamCtrl: options.streamController,
        scaleWidth: scaleWidth,
        scaleText: scaleText,
        mapState: state,
      );
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapScaleElementOptions;
  }

}

/// Scale widget using [CustomPaint]
///
class MapScale extends StatefulWidget {
  final streamCtrl;
  final mapState;
  final scaleWidth;
  final scaleText;

  MapScale({this.streamCtrl, this.mapState, this.scaleWidth, this.scaleText});

  @override
  MapScaleState createState() => MapScaleState();
}


/// MapScale widget state
/// ToDo No update when first loading
///
class MapScaleState extends State<MapScale> {

  //MediaQueryData _mediaQueryData;

  String _scaleText = "?";
  double _scaleWidth = 222;

  @override
  void initState() {
    super.initState();
    //calculateScale();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    calculateScale();
  }


  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(padding: EdgeInsets.only(left: 6.0, bottom: 4.0),
        child: _scaleElement,
      )
    );
  }


  Widget get _scaleElement {
//    _mediaQueryData = MediaQuery.of(context);
//    print("_mediaQueryData: ${_mediaQueryData.size.width} / ${_mediaQueryData.size.height}");
    return CustomPaint(

        child: Container(
          alignment: Alignment.topCenter,
          child: _scaleTextWidget,
          height: 30.0,
          //width: widget.scaleWidth,
          width:  _scaleWidth,
        ),

      painter: ScaleElementPainter(),
    );
  }

  Widget get _scaleTextWidget {
    return Text(
      _scaleText,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  /// Calculate size of scale element
  /// 1. calculate resolution and scale
  /// 2. pixel pro meter [pixelProMeter] and meter pro pixel [meterProPixel]
  /// 3. find scale size depending on scale
  ///
  double calculateScale() {
      double ret = 222;

      var dpr = MediaQuery.of(context).devicePixelRatio;
      var screenDpi = dpr * 160;
      var mediaWidth = MediaQuery.of(context).size.width;
      var scaleValues = [20000, 10000, 2000, 1000, 500, 200, 100, 50, 10];

      var resolution = 156543.03  * cos(widget.mapState.center.latitude * pi / 180) / ( pow(2,  widget.mapState.zoom ));
      var scale = screenDpi * 1 / 0.0254 * resolution;
      //print("resolution: $resolution, scale: $scale, in meter: ${scale / 100} at zoom: ${widget.mapState.zoom}");

      // how many pixel, pro meter, how many meter pro pixel
      var pixels = (scale / 100) / resolution;
      // 1 meter = x pixel
      var pixelProMeter = (pixels/ (scale / 100));
      var meterProPixel = 1 / pixelProMeter;
      //print("pixels: $pixels, pixelProMeter: $pixelProMeter, meterProPixel: $meterProPixel");

      // this is the distance for 50% of screen width
      var maxScaleWidth = meterProPixel * (mediaWidth * 0.5);
      for (var i = 0; i < scaleValues.length; i++) {
        // find value between larger then 33% of screen width

        if (maxScaleWidth > scaleValues[i]) {
          var eWidth = scaleValues[i] * pixelProMeter;
          String aText = "";
          //_mapScaleElement.scaleWidth = eWidth;
          if (scaleValues[i] < 1000) {
            aText = "${scaleValues[i].toString()} m";
          } else {
            aText = "${(scaleValues[i] / 1000).toString() } km";
          }
          setState(() {
            _scaleText = aText;
            _scaleWidth = eWidth;
            //_scaleElement;
          });

//          print("scaleText: $_scaleText, scaleWidth: $_scaleWidth");
          return eWidth;
        }
      }

      return ret;
      //_mapScaleElement.scaleWidth = (pixelProMeter * 100);

    }
  }



/// Draw scale element
class ScaleElementPainter extends CustomPainter {



  @override
  void paint(Canvas canvas, Size size) {

    Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.4);
    //path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);
    path.close();

    final Paint paint = Paint();


    //var center = Offset(size.width / 2, size.height / 2);
    paint.color = Colors.lightBlue;
    canvas.drawRect(Rect.fromPoints(Offset(0.0, 0.0), Offset(size.width, size.height)), paint);

//    paint.color = Colors.deepOrange;
//    canvas.drawCircle(center, size.height / 2, paint);

    paint.color = Colors.black;
    paint.strokeWidth = 2;
    //canvas.drawPath(path, paint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), paint);

    canvas.drawLine(Offset(paint.strokeWidth/2, size.height * 0.2), Offset(paint.strokeWidth/2, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width - paint.strokeWidth/2, size.height * 0.2), Offset(size.width - paint.strokeWidth/2, size.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

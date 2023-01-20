import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'coordinates_translator.dart';

class MyObject {
  late double right;
  late double left;
  late double top;
  late double bottom;
  MyObject(this.left, this.top, this.right, this.bottom);
}

class MyCentral {
  late double right;
  late double left;
  late double top;
  late double bottom;
  late double width;
  late double height;
  MyCentral(this.left, this.top, this.right, this.bottom, this.width, this.height);
}

MyCentral myCentral = MyCentral(0, 0, 0, 0, 0, 0);

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(this.objects, this.rotation, this.absoluteSize);

  var many_objects = <MyObject>[];
  final List<DetectedObject> objects;
  final Size absoluteSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    var width = size.width;
    var height = size.height;
    myCentral.width = width;
    myCentral.height = height;
    //print("width $width height $height");
    final Paint paintgreen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;
    final Paint paintred = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent;

    final Paint background = Paint()..color = Color(0x99000000);
    int isCentralPosition = -1;
    for (final DetectedObject detectedObject in objects) {

      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
          ui.TextStyle(color: Colors.lightGreenAccent, background: background));

      for (final Label label in detectedObject.labels) {
        builder.addText('${label.text} ${label.confidence}\n');
      }

      builder.pop();

      final left = translateX(
          detectedObject.boundingBox.left, rotation, size, absoluteSize);
      final top = translateY(
          detectedObject.boundingBox.top, rotation, size, absoluteSize);
      final right = translateX(
          detectedObject.boundingBox.right, rotation, size, absoluteSize);
      final bottom = translateY(
          detectedObject.boundingBox.bottom, rotation, size, absoluteSize);



        many_objects.add(MyObject(left, top, right, bottom));


      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(
            width: right - left,
          )),
        Offset(left, top),
      );
    }
    if(many_objects.length == 0){
      myCentral.left = 0;
      myCentral.top = 0;
      myCentral.right = 0;
      myCentral.bottom = 0;
    }
    for (int i = 0; i <many_objects.length; i++){

      if (many_objects[i].left < width/2 && many_objects[i].right > width/2 && many_objects[i].top < height/2 && many_objects[i].bottom > height/2){
        isCentralPosition = i;
        myCentral.left = many_objects[i].left;
        myCentral.top = many_objects[i].top;
        myCentral.right = many_objects[i].right;
        myCentral.bottom = many_objects[i].bottom;
        canvas.drawRect(
          Rect.fromLTRB(many_objects[i].left, many_objects[i].top, many_objects[i].right, many_objects[i].bottom),
          paintred,
        );
      }
      else{
        canvas.drawRect(
          Rect.fromLTRB(many_objects[i].left, many_objects[i].top, many_objects[i].right, many_objects[i].bottom),
          paintgreen,
        );
      }
    }
    many_objects.clear();
  }
  getCoordinates(){
    return myCentral;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

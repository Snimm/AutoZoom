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
  var central_value_list = <double>[];
  int indexOfLargest(List<double> list) {
    double largest = list[0];
    int index = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > largest) {
        largest = list[i];
        index = i;
      }
    }
    return index;
  }
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

    double findCentralValue(double left, double top, double right, double bottom){
      double central_value = 0;
      //Central value is the value that indicates how close the object is to the center of the screen
      //Central value is calculated by taking the distance between the center of the screen and the center of the object
      //and then dividing it by the sum of the width and height of the screen
      //The larger the value, the closer the object is to the center of the screen.
      //we multiply by scaling factor so larger object have bigger value
      var scale_factor = .1;
      central_value = ((((width/2) - ((right + left)/2)).abs() + ((height/2) - ((top + bottom)/2)).abs()) / (width + height)) + scale_factor*((right - left) + (bottom - top));
      return central_value;
    }

    for (int i = 0; i <many_objects.length; i++){
      central_value_list.add(findCentralValue(many_objects[i].left, many_objects[i].top, many_objects[i].right, many_objects[i].bottom));
    }
    if (central_value_list.length != 0){
      isCentralPosition = indexOfLargest(central_value_list);
    }
   //print("cnetral value list $central_value_list");
    for (int i = 0; i <many_objects.length; i++){
      //print("central value $i ${central_value_list[i]}");
      //print(' largest index = $isCentralPosition');
      if (i == isCentralPosition){
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
    central_value_list.clear();
    many_objects.clear();
  }
  getCoordinates(){
    return myCentral;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

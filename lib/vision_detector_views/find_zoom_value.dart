import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'object_detector_view.dart';
import 'painters/object_detector_painter.dart';

import 'painters/coordinates_translator.dart';
import '../main.dart';



List centralCoordinates(List<Rect> coordinates) {
  List centralCoordinates = [];
  for (int i = 0; i < coordinates.length; i++) {
    centralCoordinates.add([
      coordinates[i].center.dx,
      coordinates[i].center.dy,
    ]);
  }
  return centralCoordinates;
}

double findZoomValue(List<DetectedObject> objects, InputImageRotation rotation, Size size,) {
  ///Todo : Find the zoom value for given coordinates
  double ZoomValue = 1.0;
  return ZoomValue;
}


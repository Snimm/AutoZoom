
import 'dart:io' as io;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'camera_view.dart';
import 'painters/object_detector_painter.dart';
class zoomValueClass {
   late var ZoomValue;
   zoomValueClass(this.ZoomValue);
}

var ZoomValueInstance = zoomValueClass(1.0);

class ObjectDetectorView extends StatefulWidget {
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  late ObjectDetector _objectDetector;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;


  @override
  void initState() {
    super.initState();

    _initializeDetector(DetectionMode.stream);
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Object Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.back,
      //Zoom: _zoomValue,
    );
  }

  void _initializeDetector(DetectionMode mode) async {
    print('Set detector in mode: $mode');

    // uncomment next lines if you want to use the default model
    // final options = ObjectDetectorOptions(
    //     mode: mode,
    //     classifyObjects: true,
    //     multipleObjects: true);
    // _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    final path = 'assets/ml/object_labeler.tflite';
    final modelPath = await _getModel(path);
    final options = LocalObjectDetectorOptions(
      mode: mode,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = ObjectDetectorPainter(
          objects,
          inputImage.inputImageData!.imageRotation,
          inputImage.inputImageData!.size);
      final Quad = painter.getCoordinates();
      //print('Quad: ${Quad.right} ');
      double zoomValue = FindZoomValue(Quad);
      //print('ZoomValue: $zoomValue');
      ZoomValueInstance.ZoomValue = zoomValue;
      _customPaint = CustomPaint(painter: painter);
    }
    else {
      String text = 'Objects found: ${objects.length}\n\n';
      for (final object in objects) {
        text +=
            'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  double FindZoomValue(Quad){
    Quad.left;
    Quad.right;
    Quad.top;
    Quad.bottom;
    Quad.width;
    Quad.height;
    //scale = (w/2)/(w/2-x) for near origin
    //scale = (w/2)/(x-w/2) for further origin
    //repeated zoom does not work as zoom function does not take into account the current zoom value
    double scale_function(value, direction){
      if(value>direction/2){
        return (direction/2)/(value-direction/2);
      }
      else{
        return (direction/2)/(direction/2 - value);
      }
    }
    var scale_width_left = scale_function(Quad.left, Quad.width);
    var scale_width_right = scale_function(Quad.right, Quad.width);
    var scale_height_top = scale_function(Quad.top, Quad.height);
    var scale_height_bottom = scale_function(Quad.bottom, Quad.height);
    var scale_width = min<double>(scale_width_left, scale_width_right);
    var scale_height = min<double>(scale_height_top, scale_height_bottom);
    var zoomValue = min<double>(scale_width, scale_height);
    //print('QuadRight: ${Quad.right}. QuadLeft: ${Quad.left}. QuadTop: ${Quad.top}. QuadBottom: ${Quad.bottom}. QuadWidth: ${Quad.width}. QuadHeight: ${Quad.height}.');
    //print('ZoomValue: $zoomValue,  scale_width_left: $scale_width_left, scale_width_right: $scale_width_right, scale_height_top: $scale_height_top, scale_height_bottom: $scale_height_bottom scale_width: $scale_width, scale_height: $scale_height,');

    return zoomValue;
  }
}

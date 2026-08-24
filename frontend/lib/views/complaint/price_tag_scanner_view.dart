import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'ocr_result_confirmation_view.dart';

class PriceTagScannerView extends StatefulWidget {
  final double scale;
  const PriceTagScannerView({super.key, required this.scale});

  @override
  State<PriceTagScannerView> createState() => _PriceTagScannerViewState();
}

class _PriceTagScannerViewState extends State<PriceTagScannerView> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _frameKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing)
      return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Find the actual rendered dimensions and position of UI elements
      final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? frameBox = _frameKey.currentContext?.findRenderObject() as RenderBox?;

      if (stackBox == null || frameBox == null) {
        debugPrint("Could not find RenderBoxes");
        setState(() => _isProcessing = false);
        return;
      }

      final Size bodySize = stackBox.size;
      // Get frame position relative to the stack (the body area)
      final Offset frameOffsetInBody = frameBox.localToGlobal(Offset.zero, ancestor: stackBox);
      
      final double leftUI = frameOffsetInBody.dx;
      final double topUI = frameOffsetInBody.dy;
      final double frameW_UI = frameBox.size.width;
      final double frameH_UI = frameBox.size.height;

      final XFile image = await _controller!.takePicture();

      // Load the image
      final bytes = await File(image.path).readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        // Handle orientation to ensure we work with upright coordinates
        capturedImage = img.bakeOrientation(capturedImage);

        // Camera Preview characteristics (hardware level)
        final previewSize = _controller!.value.previewSize!;
        // previewSize width/height are swapped in portrait mode for Android
        final double previewW = previewSize.height; 
        final double previewH = previewSize.width;
        final double previewRatio = previewW / previewH;

        // Captured Image dimensions
        final double imageW = capturedImage.width.toDouble();
        final double imageH = capturedImage.height.toDouble();
        final double imageRatio = imageW / imageH;

        // STEP 1: Map the Preview sensor area to the full sensor image
        // Usually, the preview is a center-cropped version of the full sensor output.
        double previewWidthOnImage, previewHeightOnImage, previewXOffsetOnImage = 0, previewYOffsetOnImage = 0;

        if (imageRatio > previewRatio) {
          // Image is wider than preview - preview is a side-crop of the sensor
          previewWidthOnImage = imageH * previewRatio;
          previewHeightOnImage = imageH;
          previewXOffsetOnImage = (imageW - previewWidthOnImage) / 2;
        } else {
          // Image is taller than preview - preview is a top/bottom crop of the sensor
          previewWidthOnImage = imageW;
          previewHeightOnImage = imageW / previewRatio;
          previewYOffsetOnImage = (imageH - previewHeightOnImage) / 2;
        }

        // STEP 2: Map the Screen (body) coordinates to the Preview area (handling BoxFit.cover)
        final double screenRatio = bodySize.width / bodySize.height;
        double mappingScale, viewOffsetX = 0, viewOffsetY = 0;

        if (previewRatio > screenRatio) {
          // Preview area is wider than screen - screen is a side-crop of the preview
          mappingScale = previewHeightOnImage / bodySize.height;
          viewOffsetX = (previewWidthOnImage - bodySize.width * mappingScale) / 2;
        } else {
          // Preview area is taller than screen - screen is a top/bottom crop of the preview
          mappingScale = previewWidthOnImage / bodySize.width;
          viewOffsetY = (previewHeightOnImage - bodySize.height * mappingScale) / 2;
        }

        // COORDINATE MAPPING (Center-Relative)
        // We find the center of the frame in UI and map it to the center of the image area.
        final double centerX_UI = leftUI + frameW_UI / 2;
        final double centerY_UI = topUI + frameH_UI / 2;

        final double imageCenterX = previewWidthOnImage / 2 + previewXOffsetOnImage;
        final double imageCenterY = previewHeightOnImage / 2 + previewYOffsetOnImage;

        final double dx_Sensor = (centerX_UI - bodySize.width / 2) * mappingScale;
        final double dy_Sensor = (centerY_UI - bodySize.height / 2) * mappingScale;

        final double finalCenterX = imageCenterX + dx_Sensor;
        final double finalCenterY = imageCenterY + dy_Sensor;

        final int cropWidth = (frameW_UI * mappingScale).toInt();
        final int cropHeight = (frameH_UI * mappingScale).toInt();

        final int cropX = (finalCenterX - cropWidth / 2).toInt();
        final int cropY = (finalCenterY - cropHeight / 2).toInt();

        // Perform the crop
        final croppedImage = img.copyCrop(
          capturedImage,
          x: cropX.clamp(0, capturedImage.width - 1),
          y: cropY.clamp(0, capturedImage.height - 1),
          width: cropWidth.clamp(1, capturedImage.width - cropX),
          height: cropHeight.clamp(1, capturedImage.height - cropY),
        );

        img.Image processedImage = croppedImage;

        // Enhance for OCR
        processedImage = img.grayscale(processedImage);
        processedImage = img.adjustColor(processedImage, contrast: 1.5);
        processedImage = img.convolution(
          processedImage,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
          div: 1,
          offset: 0,
        );

        if (processedImage.width < 600) {
          processedImage = img.copyResize(processedImage, width: 600);
        }

        // Save processed image
        final croppedPath = '${image.path}_cropped.jpg';
        await File(croppedPath).writeAsBytes(img.encodeJpg(processedImage, quality: 100));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OCRResultConfirmationView(
                imagePath: croppedPath,
                scale: widget.scale,
              ),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error taking or cropping picture: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF1A1D1F),
            size: 20 * widget.scale,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1 * widget.scale),
          child: Divider(
            height: 1 * widget.scale,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Stack(
        key: _stackKey,
        children: [
          // Camera Preview
          Positioned.fill(
            child: ClipRRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            top: 40 * widget.scale,
            left: 20 * widget.scale,
            right: 20 * widget.scale,
            child: Container(
              padding: EdgeInsets.all(12 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8 * widget.scale),
              ),
              child: Text(
                "Take a photo of the price tag.\nEnsure good lighting for better accuracy.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Scanning Frame Overlay
          Center(
              child: SizedBox(
                key: _frameKey,
                width: 300 * widget.scale,
                height: 200 * widget.scale,
                child: CustomPaint(
                  painter: CornerFramePainter(scale: widget.scale),
                ),
              ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Capture Button
          if (!_isProcessing)
            Positioned(
              bottom: 50 * widget.scale,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70 * widget.scale,
                    height: 70 * widget.scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4 * widget.scale,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 55 * widget.scale,
                        height: 55 * widget.scale,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CornerFramePainter extends CustomPainter {
  final double scale;
  CornerFramePainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke;

    final cornerLength = 24.0 * scale;
    final r = Radius.circular(4 * scale);

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, 0)
      ..lineTo(cornerLength, 0), paint);

    // Top-right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height)
      ..lineTo(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  bool _isFlashOn = false;

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

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
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

      // Turn off flash if it was on
      if (_isFlashOn) {
        try {
          await _controller!.setFlashMode(FlashMode.off);
          if (mounted) setState(() => _isFlashOn = false);
        } catch (e) {
          debugPrint("Error turning off flash after capture");
        }
      }

      // Load the image
      final bytes = await File(image.path).readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        // Handle orientation to ensure we work with upright coordinates
        capturedImage = img.bakeOrientation(capturedImage);

        final double imageW = capturedImage.width.toDouble();
        final double imageH = capturedImage.height.toDouble();

        // Single step: map screen (body) coordinates directly to image
        // using BoxFit.cover logic
        final double screenRatio = bodySize.width / bodySize.height;
        final double imageRatio = imageW / imageH;

        double mappingScale, offsetX = 0, offsetY = 0;

        if (imageRatio > screenRatio) {
          // Image is wider than screen — cropped left/right by BoxFit.cover
          mappingScale = imageH / bodySize.height;
          offsetX = (imageW - bodySize.width * mappingScale) / 2;
        } else {
          // Image is taller than screen — cropped top/bottom by BoxFit.cover
          mappingScale = imageW / bodySize.width;
          offsetY = (imageH - bodySize.height * mappingScale) / 2;
        }

        final double cropX = leftUI * mappingScale + offsetX;
        final double cropY = topUI * mappingScale + offsetY;
        final double cropW = frameW_UI * mappingScale;
        final double cropH = frameH_UI * mappingScale;

        // Perform the crop
        final croppedImage = img.copyCrop(
          capturedImage,
          x: cropX.toInt().clamp(0, capturedImage.width - 1),
          y: cropY.toInt().clamp(0, capturedImage.height - 1),
          width: cropW.toInt().clamp(1, capturedImage.width - cropX.toInt()),
          height: cropH.toInt().clamp(1, capturedImage.height - cropY.toInt()),
        );

        final colorCropPath = '${image.path}_display.jpg';
        await File(colorCropPath).writeAsBytes(
          img.encodeJpg(croppedImage, quality: 100),
        );

        img.Image processedImage = croppedImage;

        // Enhance for OCR
        processedImage = img.grayscale(processedImage);
        processedImage = img.adjustColor(processedImage, contrast: 1.3);
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
                imagePath: colorCropPath,
                ocrPath: croppedPath,
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
        backgroundColor: const Color(0xFFFFFAF3),
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

          // Bottom Controls (Capture and Flash)
          if (!_isProcessing)
            Positioned(
              bottom: 50 * widget.scale,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Capture Button
                  GestureDetector(
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

                  // Flash Toggle Button
                  Positioned(
                    right: 40 * widget.scale,
                    child: IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: Colors.white,
                        size: 28 * widget.scale,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
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

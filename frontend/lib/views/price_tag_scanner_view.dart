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
      final XFile image = await _controller!.takePicture();

      // Load the image
      final bytes = await File(image.path).readAsBytes();
      img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        // Handle orientation if necessary
        capturedImage = img.bakeOrientation(capturedImage);

        // Calculate crop area
        // The frame in UI is 300x200 scaled.
        // We need to find the relative position of this frame on the screen.
        final screenSize = MediaQuery.of(context).size;
        final frameWidth = 300 * widget.scale;
        final frameHeight = 200 * widget.scale;

        // Coordinates of the frame in UI pixels
        final leftUI = (screenSize.width - frameWidth) / 2;
        final topUI = (screenSize.height - frameHeight) / 2;

        // Map UI coordinates to image coordinates
        // This assumes the CameraPreview fills the screen or is proportional.
        // Most cameras are 4:3 or 16:9.
        final double scaleX = capturedImage.width / screenSize.width;
        final double scaleY = capturedImage.height / screenSize.height;

        final cropX = (leftUI * scaleX).toInt();
        final cropY = (topUI * scaleY).toInt();
        final cropWidth = (frameWidth * scaleX).toInt();
        final cropHeight = (frameHeight * scaleY).toInt();

        // Perform crop
        final croppedImage = img.copyCrop(
          capturedImage,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        // Save cropped image to a new file
        final croppedPath = '${image.path}_cropped.jpg';
        await File(croppedPath).writeAsBytes(img.encodeJpg(croppedImage));

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
        children: [
          // Camera Preview
          Positioned.fill(
            child: ClipRRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover, // Crops slightly to cover the entire screen area
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
            top: 50 * widget.scale,
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
            child: Container(
              width: 300 * widget.scale,
              height: 200 * widget.scale,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFFDFD),
                  width: 2 * widget.scale,
                ),
                borderRadius: BorderRadius.circular(12 * widget.scale),
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

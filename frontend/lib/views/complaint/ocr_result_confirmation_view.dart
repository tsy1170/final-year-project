import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/ocr_service.dart';
import '../../viewmodels/complaint_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';

class OCRResultConfirmationView extends StatefulWidget {
  final String imagePath;  // for display
  final String ocrPath;  // for ocr processing
  final double scale;

  const OCRResultConfirmationView({
    super.key,
    required this.imagePath,
    required this.ocrPath,
    required this.scale,
  });

  @override
  State<OCRResultConfirmationView> createState() =>
      _OCRResultConfirmationViewState();
}

class _OCRResultConfirmationViewState extends State<OCRResultConfirmationView> {
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _ocrService = OCRService();
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final results = await _ocrService.processPriceTag(widget.ocrPath);
      setState(() {
        _itemNameController.text = results['itemName'] ?? '';
        _priceController.text = results['price'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showTopNotification(
          context,
          "Failed to recognize text",
          false,
          widget.scale,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _confirmSelection() async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    final viewModel = Provider.of<ComplaintViewModel>(context, listen: false);
    final locationViewModel = Provider.of<LocationViewModel>(context, listen: false);
    
    // 1. Fill product info into the form controllers
    viewModel.productNameController.text = _itemNameController.text;
    viewModel.productPriceController.text = _priceController.text;

    // 2. Try to auto-fill premise info based on current location
    try {
      // Ensure we have current coordinates
      if (locationViewModel.currentPosition == null) {
        await locationViewModel.initLocation();
      }

      if (locationViewModel.currentPosition != null) {
        // Fetch nearby premises
        await viewModel.fetchNearbyPremises(
          locationViewModel.currentPosition!.latitude,
          locationViewModel.currentPosition!.longitude,
        );
        
        if (viewModel.nearbyPremises.isNotEmpty) {
          // Automatically select the closest premise (the first item)
          viewModel.selectPremise(viewModel.nearbyPremises.first);
          
          if (mounted) {
            showTopNotification(
              context, 
              "Information and closest premise filled",
              true, 
              widget.scale
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Auto-filling premise information failed: $e");
      // We don't block the confirmation flow if location/nearby fetch fails
    }

    if (mounted) {
      Navigator.of(context).pop(); // Pop confirmation
      Navigator.of(context).pop(); // Pop scanner
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'CONFIRM INFORMATION',
          style: TextStyle(
            color: const Color(0xFF325E6A),
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF1A1D1F),
            size: 20 * widget.scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: (_isLoading || _isConfirming)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1A1D1F)),
                  if (_isConfirming) ...[
                    SizedBox(height: 20 * widget.scale),
                    Text(
                      "Finding nearby premises...",
                      style: TextStyle(
                        fontSize: 14 * widget.scale,
                        color: const Color(0xFF1A1D1F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20 * widget.scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8 * widget.scale),
                    child: Image.file(
                      File(widget.imagePath),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  SizedBox(height: 30 * widget.scale),
                  Text(
                    "Extracted details from tag. Please verify and edit if necessary.",
                    style: TextStyle(
                      fontSize: 14 * widget.scale,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                  SizedBox(height: 20 * widget.scale),
                  _buildEditField("Item Name", _itemNameController),
                  _buildEditField(
                    "Price (RM)",
                    _priceController,
                    isNumeric: true,
                  ),
                  SizedBox(height: 30 * widget.scale),
                  CustomButton(
                    label: "CONFIRM",
                    onTap: _confirmSelection,
                    bg: const Color(0xFF1A1D1F),
                    text: Colors.white,
                    scale: widget.scale,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12 * widget.scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        SizedBox(height: 8 * widget.scale),
        Container(
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // Shadow color
                  spreadRadius: -6,                     // How far the shadow extends
                  blurRadius: 6,                      // Softness of the shadow
                  offset: const Offset(4, 5),        // Offset of the shadow, 2),
                )
              ]
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isNumeric
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ]
                : null,
            style: TextStyle(
              fontSize: 13 * widget.scale,
              color: const Color(0xFF1A1D1F),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1 * widget.scale,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide(color: const Color(0xFF325E6A), width: 1 * widget.scale),
              ),
              contentPadding: EdgeInsets.all(15 * widget.scale),
            ),
          ),
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }
}

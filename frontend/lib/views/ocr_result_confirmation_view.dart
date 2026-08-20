import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ocr_service.dart';
import '../viewmodels/complaint_view_model.dart';
import 'widgets/common/animated_notification.dart';

class OCRResultConfirmationView extends StatefulWidget {
  final String imagePath;
  final double scale;

  const OCRResultConfirmationView({
    super.key,
    required this.imagePath,
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

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final results = await _ocrService.processPriceTag(widget.imagePath);
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

  void _confirmSelection() {
    final viewModel = Provider.of<ComplaintViewModel>(context, listen: false);
    viewModel.productNameController.text = _itemNameController.text;
    viewModel.productPriceController.text = _priceController.text;

    Navigator.of(context).pop(); // Pop confirmation
    Navigator.of(context).pop(); // Pop scanner
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'CONFIRM INFORMATION',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1 * widget.scale),
          child: Divider(
            height: 1 * widget.scale,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1D1F)),
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
                      height: 200 * widget.scale,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                  SizedBox(
                    width: double.infinity,
                    height: 50 * widget.scale,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1D1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1 * widget.scale),
                        ),
                      ),
                      child: Text(
                        "CONFIRM",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * widget.scale,
                        ),
                      ),
                    ),
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
        TextField(
          controller: controller,
          keyboardType: isNumeric
              ? const TextInputType.numberWithOptions(decimal: false)
              : TextInputType.text,
          inputFormatters: isNumeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: TextStyle(
            fontSize: 13 * widget.scale,
            color: const Color(0xFF1A1D1F),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1 * widget.scale),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(15 * widget.scale),
          ),
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }
}

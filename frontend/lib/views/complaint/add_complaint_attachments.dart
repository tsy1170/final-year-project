import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/complaint_view_model.dart';
import 'complaint_summary_view.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';
import '../../services/ocr_service.dart';

class ComplaintAddAttachmentsView extends StatefulWidget {
  final double scale;

  const ComplaintAddAttachmentsView({super.key, required this.scale});

  @override
  State<ComplaintAddAttachmentsView> createState() => _ComplaintAddAttachmentsViewState();
}

class _ComplaintAddAttachmentsViewState extends State<ComplaintAddAttachmentsView> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _takePicture(ComplaintViewModel viewModel) async {
    if (viewModel.attachments.length >= 4) {
      showTopNotification(context, "Maximum 4 images allowed", false, widget.scale);
      return;
    }

    // CRITICAL FIX: Limit dimensions to 1024px. 
    // This allows the native layer to resize the image before it reaches Dart,
    // preventing "Signal 3" (ANR) and memory exhaustion on devices like Vivo.
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      _processAndCheckSimilarity(image, viewModel);
    }
  }

  Future<void> _processAndCheckSimilarity(XFile image, ComplaintViewModel viewModel) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20 * widget.scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10 * widget.scale),
          ),
          child: CircularProgressIndicator(
            color: const Color(0xFF1A1D1F),
            strokeWidth: 3 * widget.scale,
          ),
        ),
      ),
    );

    try {
      // 1. Pre-process the image (This runs in a background isolate in OCRService)
      final processedPath = await _ocrService.preprocessImage(image.path);

      // 2. Run OCR text recognition on the enhanced image
      final ocrText = await _ocrService.recognizeFullText(processedPath);
      
      // Cleanup temporary processed file if created
      if (processedPath != image.path) {
        try { File(processedPath).delete(); } catch (_) {}
      }

      // 3. Get target keywords from ViewModel (Product Name and Price)
      final targetText = "${viewModel.productNameController.text} ${viewModel.productPriceController.text}";
      
      // 4. Calculate similarity using TF-IDF + Cosine Similarity
      final similarity = _ocrService.calculateSimilarity(targetText, ocrText);

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      // 5. Check against threshold (70%)
      if (similarity < 0.7) {
        _showSimilarityWarning(image, viewModel, similarity);
      } else {
        viewModel.addAttachment(image);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("OCR verification failed: $e");
      // Fallback: attach the original image if OCR process fails
      viewModel.addAttachment(image);
    }
  }

  void _showSimilarityWarning(XFile image, ComplaintViewModel viewModel, double score) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDFD),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        title: Text(
          "WARNING",
          style: TextStyle(
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        content: Text(
          "This photo only has a ${(score * 100).toStringAsFixed(1)}% relevance with your product details. Do you still want to attach it?",
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14 * widget.scale,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: const Color(0xFF9A9FA5),
                fontWeight: FontWeight.w700,
                fontSize: 14 * widget.scale,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.addAttachment(image);
              Navigator.pop(context);
            },
            child: Text(
              "ATTACH ANYWAY",
              style: TextStyle(
                color: const Color(0xFFED1A4B),
                fontWeight: FontWeight.w700,
                fontSize: 14 * widget.scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFAF3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFAF3),
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'ATTACHMENTS',
              style: TextStyle(
                color: const Color(0xFF325E6A),
                fontSize: 16 * widget.scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20 * widget.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upload pictures or proof of your complaint (Max 4).",
                  style: TextStyle(
                    fontSize: 14 * widget.scale,
                    color: const Color(0xFF1A1D1F),
                  ),
                ),
                SizedBox(height: 30 * widget.scale),
                
                // Camera Button Container
                GestureDetector(
                  onTap: () => _takePicture(viewModel),
                  child: Container(
                    width: double.infinity,
                    height: 150 * widget.scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1 * widget.scale),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1 * widget.scale,
                      ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2), // Shadow color
                            spreadRadius: -6,                     // How far the shadow extends
                            blurRadius: 6,                      // Softness of the shadow
                            offset: const Offset(4, 5),        // Offset of the shadow, 2),
                          )
                        ]
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 35 * widget.scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                        SizedBox(height: 10 * widget.scale),
                        Text(
                          "Take a Picture",
                          style: TextStyle(
                            fontSize: 14 * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 30 * widget.scale),
                
                // Image Preview List
                if (viewModel.attachments.isNotEmpty) ...[
                  Text(
                    "ATTACHED PICTURES (${viewModel.attachments.length}/4)",
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                  SizedBox(height: 15 * widget.scale),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10 * widget.scale,
                      mainAxisSpacing: 10 * widget.scale,
                      childAspectRatio: 1,
                    ),
                    itemCount: viewModel.attachments.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1 * widget.scale),
                              border: Border.all(
                                color: const Color(0xFF1A1D1F).withValues(alpha: 0.1),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.file(
                              File(viewModel.attachments[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 5 * widget.scale,
                            right: 5 * widget.scale,
                            child: GestureDetector(
                              onTap: () => viewModel.removeAttachment(index),
                              child: Container(
                                padding: EdgeInsets.all(4 * widget.scale),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16 * widget.scale,
                                  color: const Color(0xFFED1A4B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                
                SizedBox(height: 40 * widget.scale),
                
                // Next Button
                CustomButton(
                  label: "NEXT",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintSummaryView(scale: widget.scale),
                      ),
                    );
                  },
                  bg: const Color(0xFF1A1D1F),
                  text: Colors.white,
                  scale: widget.scale,
                ),
                SizedBox(height: 20 * widget.scale),
              ],
            ),
          ),
        );
      }
    );
  }
}

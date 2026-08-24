import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/complaint_view_model.dart';
import 'complaint_summary_view.dart';
import '../widgets/common/animated_notification.dart';

class ComplaintAddAttachmentsView extends StatefulWidget {
  final double scale;

  const ComplaintAddAttachmentsView({super.key, required this.scale});

  @override
  State<ComplaintAddAttachmentsView> createState() => _ComplaintAddAttachmentsViewState();
}

class _ComplaintAddAttachmentsViewState extends State<ComplaintAddAttachmentsView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture(ComplaintViewModel viewModel) async {
    if (viewModel.attachments.length >= 4) {
      showTopNotification(context, "Maximum 4 images allowed", false, widget.scale);
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      viewModel.addAttachment(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFDFD),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFDFD),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'ATTACHMENTS',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 16 * widget.scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1 * widget.scale),
              child: Divider(height: 1 * widget.scale, color: Colors.grey.withValues(alpha: 0.2)),
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
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(1 * widget.scale),
                      border: Border.all(
                        color: const Color(0xFF1A1D1F).withValues(alpha: 0.1),
                        width: 1 * widget.scale,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 40 * widget.scale,
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
                SizedBox(
                  width: double.infinity,
                  height: 50 * widget.scale,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintSummaryView(scale: widget.scale),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1D1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1 * widget.scale),
                      ),
                    ),
                    child: Text(
                      "NEXT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * widget.scale,
                      ),
                    ),
                  ),
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

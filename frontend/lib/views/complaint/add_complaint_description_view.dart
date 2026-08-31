import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/complaint_view_model.dart';
import 'complaint_premise_coordinates.dart';
import 'add_complaint_attachments.dart';
import '../widgets/common/custom_button.dart';

class AddComplaintDescriptionView extends StatefulWidget {
  final double scale;

  const AddComplaintDescriptionView({super.key, required this.scale});

  @override
  State<AddComplaintDescriptionView> createState() => _AddComplaintDescriptionViewState();
}

class _AddComplaintDescriptionViewState extends State<AddComplaintDescriptionView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ComplaintViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        title: Text(
          'ADD DESCRIPTIONS',
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
              "We value your feedback. Please describe the issue you encountered.",
              style: TextStyle(
                fontSize: 14 * widget.scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 20 * widget.scale),
            _buildLabel("Descriptions"),
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
                controller: viewModel.descriptionController,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration("Provide more details..."),
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
            ),
            SizedBox(height: 10 * widget.scale),
            Text(
              "For example: On January 10, 2026, I shopping at a supermarket in Pulau Pinang and found that the prices of goods did not match the prices in advertisement",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14 * widget.scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 40 * widget.scale),
            CustomButton(
              label: "NEXT",
              onTap: () {
                if (viewModel.latitudeController.text.isNotEmpty && viewModel.longitudeController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintAddAttachmentsView(scale: widget.scale),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintPremiseCoordinatesView(scale: widget.scale),
                    ),
                  );
                }
              },
              bg: const Color(0xFF1A1D1F),
              text: Colors.white,
              scale: widget.scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12 * widget.scale,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1D1F),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF9A9FA5),
        fontSize: 13 * widget.scale,
      ),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * widget.scale),
        borderSide: BorderSide(color: const Color(0xFF325E6A), width: 1 * widget.scale),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * widget.scale),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * widget.scale),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1 * widget.scale,
        ),
      ),
      contentPadding: EdgeInsets.all(15 * widget.scale),
    );
  }
}

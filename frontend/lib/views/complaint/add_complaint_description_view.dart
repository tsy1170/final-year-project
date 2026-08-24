import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/complaint_view_model.dart';
import 'complaint_premise_coordinates.dart';

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
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        elevation: 0,
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
              "We value your feedback. Please describe the issue you encountered.",
              style: TextStyle(
                fontSize: 14 * widget.scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 20 * widget.scale),
            _buildLabel("Descriptions"),
            SizedBox(height: 8 * widget.scale),
            TextField(
              controller: viewModel.descriptionController,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration("Provide more details..."),
              style: TextStyle(
                fontSize: 12 * widget.scale,
                color: const Color(0xFF1A1D1F),
                fontWeight: FontWeight.w500
              ),
            ),
            SizedBox(height: 8 * widget.scale),
            Text(
              "For example: On January 10, 2026, I shopping at a supermarket in Pulau Pinang and found that the prices of goods did not match the prices in advertisement",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14 * widget.scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            SizedBox(height: 40 * widget.scale),
            SizedBox(
              width: double.infinity,
              height: 50 * widget.scale,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintPremiseCoordinatesView(scale: widget.scale),
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
      fillColor: const Color(0xFFF4F4F4),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(1 * widget.scale),
        borderSide: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(1 * widget.scale),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.all(15 * widget.scale),
    );
  }
}

import 'package:flutter/material.dart';

class AddComplaintDescriptionView extends StatefulWidget {
  final double scale;

  const AddComplaintDescriptionView({super.key, required this.scale});

  @override
  State<AddComplaintDescriptionView> createState() => _AddComplaintViewState();
}

class _AddComplaintViewState extends State<AddComplaintDescriptionView> {
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _descriptionController,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration("Provide more details..."),
              style: TextStyle(
                fontSize: 12 * widget.scale,
                color: const Color(0xFF1A1D1F),
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
                  // Functionality coming soon
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1 * widget.scale),
                  ),
                ),
                child: Text(
                  "SUBMIT",
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(1 * widget.scale),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.all(15 * widget.scale),
    );
  }
}

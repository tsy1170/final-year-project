import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: const Color(0xFFFBF8F5),
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
            color: const Color(0xFF1A1D1F),
            fontSize: 14 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0
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
            SizedBox(height: 30 * widget.scale),
            
            Padding(
              padding: EdgeInsets.only(left: 5 * widget.scale),
              child: Text(
                "DESCRIPTIONS",
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1D1F),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 12 * widget.scale),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16 * widget.scale),
              ),
              child: TextField(
                controller: viewModel.descriptionController,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration("Provide more details..."),
                style: TextStyle(
                  fontSize: 13 * widget.scale,
                  color: const Color(0xFF1A1D1F),
                  height: 1.5,
                ),
              ),
            ),
            
            SizedBox(height: 20 * widget.scale),
            _buildExamplePill(),
            
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
            SizedBox(height: 50 * widget.scale),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplePill() {
    return Container(
      padding: EdgeInsets.all(15 * widget.scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6F3),
        borderRadius: BorderRadius.circular(12 * widget.scale),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 20 * widget.scale,
            color: const Color(0xFFB85A3A),
          ),
          SizedBox(width: 12 * widget.scale),
          Expanded(
            child: Text(
              "On January 10, 2026, I was shopping at a supermarket in Pulau Pinang and found that the price of goods did not match the price in the advertisement.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 11 * widget.scale,
                color: const Color(0xFFB85A3A),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF9A9FA5),
        fontSize: 12 * widget.scale,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16 * widget.scale),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16 * widget.scale),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16 * widget.scale),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.all(20 * widget.scale),
    );
  }
}

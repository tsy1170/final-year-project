import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_complaint_description_view.dart';

class AddComplaintView extends StatefulWidget {
  final double scale;

  const AddComplaintView({super.key, required this.scale});

  @override
  State<AddComplaintView> createState() => _AddComplaintViewState();
}

class _AddComplaintViewState extends State<AddComplaintView> {
  // Complaint Category Controllers
  final _categoryController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _lossAmountController = TextEditingController();
  final _dateIssueController = TextEditingController();

  // Premise Information Controllers
  final _premiseTypeController = TextEditingController();
  final _premiseNameController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _categoryController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _lossAmountController.dispose();
    _dateIssueController.dispose();
    _premiseTypeController.dispose();
    _premiseNameController.dispose();
    _phoneNoController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SUBMIT COMPLAINT',
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
            _buildSectionTitle("COMPLAINT CATEGORY"),
            SizedBox(height: 15 * widget.scale),
            _buildTextField("Category", _categoryController),
            _buildTextField("Product Name", _productNameController),
            _buildTextField("Product Price", _productPriceController, isPrice: true),
            _buildTextField("Loss Amount", _lossAmountController, isPrice: true),
            _buildTextField("Date Issue", _dateIssueController, isDate: true),

            SizedBox(height: 40 * widget.scale),
            _buildSectionTitle("PREMISE INFORMATION"),
            SizedBox(height: 15 * widget.scale),
            _buildTextField("Premise Type", _premiseTypeController),
            _buildTextField("Premise Name", _premiseNameController),
            _buildTextField("Phone No", _phoneNoController),
            _buildTextField("Email", _emailController),
            _buildTextField("Premise Address", _addressController),
            _buildTextField("Postal Code", _postalCodeController),
            _buildTextField("District", _districtController),
            _buildTextField("State", _stateController),

            SizedBox(height: 30 * widget.scale),
            SizedBox(
              width: double.infinity,
              height: 50 * widget.scale,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddComplaintDescriptionView(scale: widget.scale),
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
            SizedBox(height: 50 * widget.scale),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D1F),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5 * widget.scale, horizontal: 10 * widget.scale),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * widget.scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFFDFD),
              ),
            ),
          ),
        );

  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isDate = false, bool isPrice = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPrice ? label + " (RM)" : label,
          style: TextStyle(
            fontSize: 12 * widget.scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        SizedBox(height: 8 * widget.scale),
        TextField(
          controller: controller,
          readOnly: isDate,
          keyboardType: isPrice
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: isPrice
              ? [
            // 1. Instantly reject any characters that aren't digits or dots
            FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),

            // 2. Validate the structure (Only allows 1 dot and max 2 decimal places)
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ]
              : null,
          onTap: isDate ? () => _selectDate(context, controller) : null,
          style: TextStyle(fontSize: 13 * widget.scale),
          decoration: InputDecoration(
            hintText: "Enter $label",
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
            suffixIcon: isDate ? Icon(Icons.calendar_today, size: 18 * widget.scale) : null,
          ),
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1 * widget.scale),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: Colors.grey.withValues(alpha: 0.3),
              thickness: 1 * widget.scale,
            ),
            dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFFFFDFD)),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1D1F),    // Header bg & selected day circle
              onPrimary: Color(0xFFFFFDFD),       // Header text & selected day text
              onSurface: Color(0xFF1A1D1F),     // Default calendar text days
            ),
          ),
          child: child!,
        );

      }
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}

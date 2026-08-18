import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/complaint_view_model.dart';
import 'add_complaint_description_view.dart';
import 'widgets/common/animated_notification.dart';

class AddComplaintView extends StatefulWidget {
  final double scale;

  const AddComplaintView({super.key, required this.scale});

  @override
  State<AddComplaintView> createState() => _AddComplaintViewState();
}

class _AddComplaintViewState extends State<AddComplaintView> {
  final List<String> _categories = [
    "Expensive",
    "Misleading price",
    "No price tag",
    "Not using price tag",
    "Selling Exceeding Maximum Price (Festive Season)",
  ];

  final List<String> _premiseTypes = [
    "Pasar Basah",
    "Restoran Cina",
    "Hypermarket",
    "Pasar Mini",
    "Borong",
    "Restoran India Muslim",
    "Pasar Raya / Supermarket",
    "Kedai Serbaneka",
    "Foodcourt",
    "Medan Selera",
    "Restoran Melayu",
    "Kedai Runcit",
  ];

  @override
  void initState() {
    super.initState();
    // Reset the viewmodel state when entering the flow from the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComplaintViewModel>(context, listen: false).reset();
    });
  }

  void _handleNext(ComplaintViewModel viewModel) {
    if (viewModel.selectedCategory == null ||
        viewModel.productNameController.text.isEmpty ||
        viewModel.productPriceController.text.isEmpty ||
        viewModel.lossAmountController.text.isEmpty ||
        viewModel.dateIssueController.text.isEmpty ||
        viewModel.selectedPremiseType == null ||
        viewModel.premiseNameController.text.isEmpty ||
        viewModel.addressController.text.isEmpty) {
      showTopNotification(context, "Please fill in all required fields", false, widget.scale);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComplaintDescriptionView(scale: widget.scale),
      ),
    );
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
                SizedBox(height: 20 * widget.scale),
                _buildDropdownField("Category", viewModel.selectedCategory, _categories, (val) => viewModel.setCategory(val), isRequired: true),
                _buildTextField("Product Name", viewModel.productNameController, isRequired: true),
                _buildTextField("Product Price", viewModel.productPriceController, isPrice: true, isRequired: true),
                _buildTextField("Loss Amount", viewModel.lossAmountController, isPrice: true, isRequired: true),
                _buildTextField("Date Issue", viewModel.dateIssueController, isDate: true, isRequired: true),

                SizedBox(height: 40 * widget.scale),
                _buildSectionTitle("YOUR INFORMATION"),
                SizedBox(height: 20 * widget.scale),
                _buildTextField("Phone No", viewModel.phoneNoController),
                _buildTextField("Email", viewModel.emailController),

                SizedBox(height: 40 * widget.scale),
                _buildSectionTitle("PREMISE INFORMATION"),
                SizedBox(height: 20 * widget.scale),
                _buildDropdownField("Premise Type", viewModel.selectedPremiseType, _premiseTypes, (val) => viewModel.setPremiseType(val), isRequired: true),
                _buildTextField("Premise Name", viewModel.premiseNameController, isRequired: true),
                _buildTextField("Premise Address", viewModel.addressController, isRequired: true),
                _buildTextField("Postal Code", viewModel.postalCodeController),
                _buildTextField("District", viewModel.districtController),
                _buildTextField("State", viewModel.stateController),

                SizedBox(height: 30 * widget.scale),
                SizedBox(
                  width: double.infinity,
                  height: 50 * widget.scale,
                  child: ElevatedButton(
                    onPressed: () => _handleNext(viewModel),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D1F),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isDate = false, bool isPrice = false, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isPrice ? label + " (RM)" : label,
              style: TextStyle(
                fontSize: 12 * widget.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFED1A4B),
                ),
              ),
          ],
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
                  FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ]
              : null,
          onTap: isDate ? () => _selectDate(context) : null,
          style: TextStyle(fontSize: 12 * widget.scale, color: const Color(0xFF1A1D1F)),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: TextStyle(
              color: const Color(0xFF9A9FA5),
              fontSize: 12 * widget.scale,
            ),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1 * widget.scale),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(15 * widget.scale),
            suffixIcon: isDate ? Icon(Icons.calendar_today, size: 18 * widget.scale, color: const Color(0xFF1A1D1F)) : null,
          ),
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * widget.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            if (isRequired)
              Text(
                " *",
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFED1A4B),
                ),
              ),
          ],
        ),
        SizedBox(height: 8 * widget.scale),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<String>(
              width: constraints.maxWidth,
              initialSelection: selectedValue,
              onSelected: onChanged,
              hintText: "Select $label",
              requestFocusOnTap: false,
              enableSearch: false,
              trailingIcon: SizedBox(
                width: 20,
                height: 20,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              ),
              selectedTrailingIcon: SizedBox(
                width: 20,
                height: 20,
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              ),
              textStyle: TextStyle(
                fontSize: 12 * widget.scale,
                color: const Color(0xFF1A1D1F),
                fontFamily: "Montserrat",
              ),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                constraints: BoxConstraints(
                  maxHeight: 50.0 * widget.scale,
                  minHeight: 50.0 * widget.scale,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1 * widget.scale),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 15 * widget.scale),
                hintStyle: TextStyle(
                  color: const Color(0xFF9A9FA5),
                  fontSize: 12 * widget.scale,
                ),
              ),
              menuStyle: MenuStyle(
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor:
                    WidgetStateProperty.all(const Color(0xFF1A1D1F)),
                surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1 * widget.scale),
                  ),
                ),
              ),
              dropdownMenuEntries: options.map((String value) {
                return DropdownMenuEntry<String>(
                  value: value,
                  label: value,
                  labelWidget: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      color: const Color(0xFFFFFDFD),
                      fontFamily: "Montserrat",
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final viewModel = Provider.of<ComplaintViewModel>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
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
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFFFFDFD)),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1D1F),
              onPrimary: Color(0xFFFFFDFD),
              onSurface: Color(0xFF1A1D1F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.updateDate(picked);
    }
  }
}

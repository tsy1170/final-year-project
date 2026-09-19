import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/complaint_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import 'add_complaint_description_view.dart';
import 'price_tag_scanner_view.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';

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

  final List<String> _states = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Melaka",
    "Negeri Sembilan",
    "Pahang",
    "Perak",
    "Perlis",
    "Pulau Pinang",
    "Sabah",
    "Sarawak",
    "Selangor",
    "Terengganu",
    "W.P. Kuala Lumpur",
    "W.P. Labuan",
    "W.P. Putrajaya",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final complaintViewModel = Provider.of<ComplaintViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final locationViewModel = Provider.of<LocationViewModel>(context, listen: false);

      complaintViewModel.reset();
      locationViewModel.initLocation();

      if (authViewModel.userNric != null) {
        complaintViewModel.nricController.text = authViewModel.userNric!;
      }
      if (authViewModel.userName != null) {
        complaintViewModel.fullNameController.text = authViewModel.userName!;
      }
      if (authViewModel.userPhoneNumber != null) {
        complaintViewModel.phoneNoController.text = authViewModel.userPhoneNumber!;
      }
      if (authViewModel.userEmail != null) {
        complaintViewModel.emailController.text = authViewModel.userEmail!;
      }
    });
  }

  void _formatPrice(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      final double? val = double.tryParse(controller.text);
      if (val != null) {
        controller.text = val.toStringAsFixed(2);
      }
    }
  }

  void _handleNext(ComplaintViewModel viewModel) {
    if (viewModel.selectedCategory == null ||
        viewModel.productNameController.text.isEmpty ||
        viewModel.productPriceController.text.isEmpty ||
        viewModel.lossAmountController.text.isEmpty ||
        viewModel.dateIssueController.text.isEmpty ||
        viewModel.fullNameController.text.isEmpty ||
        viewModel.nricController.text.isEmpty ||
        viewModel.selectedPremiseType == null ||
        viewModel.premiseNameController.text.isEmpty ||
        viewModel.addressController.text.isEmpty) {
      showTopNotification(context, "Please fill in all required fields", false, widget.scale);
      return;
    }

    _formatPrice(viewModel.productPriceController);
    _formatPrice(viewModel.lossAmountController);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComplaintDescriptionView(scale: widget.scale),
      ),
    );
  }

  Future<void> _showNearbyPremises(BuildContext context) async {
    final complaintViewModel = Provider.of<ComplaintViewModel>(context, listen: false);
    final locationViewModel = Provider.of<LocationViewModel>(context, listen: false);

    if (locationViewModel.currentPosition == null) {
      await locationViewModel.initLocation();
    }

    if (locationViewModel.currentPosition == null) {
      if (mounted) showTopNotification(context, "Location not available", false, widget.scale);
      return;
    }

    complaintViewModel.fetchNearbyPremises(
      locationViewModel.currentPosition!.latitude,
      locationViewModel.currentPosition!.longitude,
    ).catchError((e) {
      if (mounted) showTopNotification(context, e.toString(), false, widget.scale);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDFD),
      builder: (context) {
        return Consumer<ComplaintViewModel>(
          builder: (context, viewModel, child) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1 * widget.scale
                        )
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15 * widget.scale)),
                      color: const Color(0xFF1A1D1F),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              150 * widget.scale,
                              11 * widget.scale,
                              150 * widget.scale,
                              0,
                            ),
                            child: Container(
                              height: 4 * widget.scale,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFFDFD),
                                  borderRadius: BorderRadius.circular(15 * widget.scale)
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 25 * widget.scale,
                              horizontal: 20 * widget.scale
                          ),
                          child: Text(
                            "NEARBY PREMISES",
                            style: TextStyle(
                              fontSize: 16 * widget.scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFFDFD),
                            ),
                          ),

                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: viewModel.isFetchingNearby
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
                        : viewModel.nearbyPremises.isEmpty
                            ? const Center(child: Text("No premises found nearby"))
                            : ListView.builder(
                                  itemCount: viewModel.nearbyPremises.length,
                                  itemBuilder: (context, index) {
                                    final premise = viewModel.nearbyPremises[index];
                                    return
                                      ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12 * widget.scale,
                                          horizontal: 20 * widget.scale,
                                        ),
                                        title: Text(
                                          premise['premise_name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14 * widget.scale,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1D1F),
                                          ),
                                        ),
                                        subtitle: Text(
                                          premise['address'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12 * widget.scale,
                                            color: const Color(0xFF9A9FA5),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          "${(premise['road_distance_km'] as double).toStringAsFixed(2)} km",
                                          style: TextStyle(fontSize: 12 * widget.scale),
                                        ),
                                        onTap: () {
                                          viewModel.selectPremise(premise);
                                          Navigator.pop(context);
                                        },
                                    );
                                  },
                                ),
                            ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF8F5),
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'SUBMIT COMPLAINT',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 15 * widget.scale,
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
                _buildOCRScannerContainer(),
                SizedBox(height: 25 * widget.scale),
                
                _buildSectionCard(
                  title: "Complaint Category",
                  children: [
                    _buildDropdownField("Category", viewModel.selectedCategory, _categories, (val) => viewModel.setCategory(val), isRequired: true),
                    _buildTextField("Product Name", viewModel.productNameController, isRequired: true),
                    _buildTextField("Product Price", viewModel.productPriceController, isPrice: true, isRequired: true),
                    _buildTextField("Loss Amount", viewModel.lossAmountController, isPrice: true, isRequired: true),
                    _buildTextField("Date Issue", viewModel.dateIssueController, isDate: true, isRequired: true),
                  ],
                ),

                _buildSectionCard(
                  title: "Your Information",
                  children: [
                    _buildTextField("Full Name", viewModel.fullNameController, isRequired: true),
                    _buildTextField("NRIC", viewModel.nricController, isNumeric: true, isRequired: true),
                    _buildTextField("Phone No", viewModel.phoneNoController, isNumeric: true, isRequired: true),
                    _buildTextField("Email", viewModel.emailController, isRequired: true),
                  ],
                ),

                _buildSectionCard(
                  title: "Premise Information",
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            "Premise Type",
                            viewModel.selectedPremiseType,
                            _premiseTypes,
                            (val) => viewModel.setPremiseType(val),
                            isRequired: true,
                            noBottomPadding: true
                          ),
                        ),
                        SizedBox(width: 10 * widget.scale),
                        GestureDetector(
                          onTap: () => _showNearbyPremises(context),
                          child: Container(
                            width: 50 * widget.scale,
                            height: 50 * widget.scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5F0),
                              borderRadius: BorderRadius.circular(12 * widget.scale),
                            ),
                            child: Icon(Icons.location_on, color: const Color(0xFF1A1D1F), size: 27 * widget.scale),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20 * widget.scale),
                    _buildTextField("Premise Name", viewModel.premiseNameController, isRequired: true),
                    _buildTextField("Premise Address", viewModel.addressController, isRequired: true),
                    _buildTextField("Postal Code", viewModel.postalCodeController, isNumeric: true),
                    _buildDropdownField("State", viewModel.selectedState, _states, (val) => viewModel.setSelectedState(val)),
                    _buildTextField("District", viewModel.districtController),
                    _buildTextField("Latitude", viewModel.latitudeController, isCoordinate: true),
                    _buildTextField("Longitude", viewModel.longitudeController, isCoordinate: true),
                  ],
                ),

                SizedBox(height: 10 * widget.scale),
                CustomButton(
                  label: "NEXT",
                  onTap: () => _handleNext(viewModel),
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
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 30 * widget.scale),
      padding: EdgeInsets.all(20 * widget.scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * widget.scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: 25 * widget.scale),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOCRScannerContainer() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PriceTagScannerView(scale: widget.scale),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16 * widget.scale, horizontal: 20 * widget.scale),
        decoration: BoxDecoration(
          color: const Color(0xFFB85A3A),
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        child: Row(
          children: [
            Icon(
              Icons.camera_alt_rounded,
              size: 28 * widget.scale,
              color: Colors.white,
            ),
            SizedBox(width: 15 * widget.scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SCAN PRICE TAG",
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Auto-extract item name and price from a photo",
                    style: TextStyle(
                      fontSize: 10 * widget.scale,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10 * widget.scale),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16 * widget.scale,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 14 * widget.scale,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFB85A3A),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isDate = false, bool isPrice = false, bool isRequired = false, bool isNumeric = false, bool isCoordinate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 5 * widget.scale),
          child: Row(
            children: [
              Text(
                isPrice ? label + " (RM)" : label,
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w600,
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
        ),
        SizedBox(height: 8 * widget.scale),
        SizedBox(
          height: 50 * widget.scale,
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            readOnly: isDate,
            keyboardType: (isPrice || isCoordinate)
                ? const TextInputType.numberWithOptions(decimal: true)
                : (isNumeric ? const TextInputType.numberWithOptions(decimal: false) : TextInputType.text),
            inputFormatters: isPrice
                ? [
                    FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ]
                : isCoordinate 
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,10}'))]
                  : (isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null),
            onTap: isDate ? () => _selectDate(context) : null,
            onEditingComplete: isPrice ? () {
              _formatPrice(controller);
              FocusScope.of(context).unfocus();
            } : null,
            onTapOutside: (event) {
              if (isPrice) _formatPrice(controller);
              FocusScope.of(context).unfocus();
            },
            style: TextStyle(fontSize: 12 * widget.scale, color: const Color(0xFF1A1D1F)),
            decoration: InputDecoration(
              hintText: "Enter $label",
              hintStyle: TextStyle(
                color: const Color(0xFF9A9FA5),
                fontSize: 11 * widget.scale,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F5F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide.none
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widget.scale),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 15 * widget.scale),
              suffixIcon: isDate ? Icon(Icons.calendar_today, size: 18 * widget.scale, color: const Color(0xFF1A1D1F)) : null,
            ),
          ),
        ),
        SizedBox(height: 20 * widget.scale),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged, {bool isRequired = false, bool noBottomPadding = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 5 * widget.scale),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  fontWeight: FontWeight.w600,
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
        ),
        SizedBox(height: 8 * widget.scale),
        LayoutBuilder(
          builder: (context, constraints) {
            return Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(const Color(0xFF1A1D1F))
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: ButtonStyle(
                    maximumSize: WidgetStateProperty.all(Size(32 * widget.scale, 32 * widget.scale)),
                    minimumSize: WidgetStateProperty.all(Size(24 * widget.scale, 24 * widget.scale)),
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    splashFactory: NoSplash.splashFactory,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              ),
              child: DropdownMenu<String>(
                menuHeight: 300 * widget.scale,
                width: constraints.maxWidth,
                initialSelection: selectedValue,
                onSelected: onChanged,
                hintText: "Select $label",
                requestFocusOnTap: false,
                enableSearch: false,
                trailingIcon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
                selectedTrailingIcon: Icon(Icons.keyboard_arrow_up_rounded,
                      color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
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
                  fillColor: const Color(0xFFF7F5F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.scale),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.scale),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.scale),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: TextStyle(
                    color: const Color(0xFF9A9FA5),
                    fontSize: 12 * widget.scale,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15 * widget.scale,
                  ),
                ),
                menuStyle: MenuStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStateProperty.all(const Color(0xFF1A1D1F)),
                  surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * widget.scale),
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
              )
            );
          },
        ),
        if (!noBottomPadding) SizedBox(height: 20 * widget.scale),
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
                borderRadius: BorderRadius.circular(12 * widget.scale),
              ),
              dividerColor: Colors.grey.withValues(alpha: 0.3)
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

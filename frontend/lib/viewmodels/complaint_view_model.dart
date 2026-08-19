import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

class ComplaintViewModel extends ChangeNotifier {
  final ComplaintService _complaintService;

  // Idempotency
  String? idempotencyKey;
  bool _isAlreadySubmitted = false;
  bool get isAlreadySubmitted => _isAlreadySubmitted;

  // Complaint List
  List<Complaint> _userComplaints = [];
  List<Complaint> get userComplaints => _userComplaints;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Complaint Category Controllers & State
  String? selectedCategory;
  final productNameController = TextEditingController();
  final productPriceController = TextEditingController();
  final lossAmountController = TextEditingController();
  final dateIssueController = TextEditingController();

  // Your Information Controllers
  final phoneNoController = TextEditingController();
  final emailController = TextEditingController();

  // Premise Information Controllers & State
  String? selectedPremiseType;
  final premiseNameController = TextEditingController();
  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();

  // Descriptions
  final descriptionController = TextEditingController();

  // Premise Location
  double? latitude;
  double? longitude;

  // Attachments
  List<XFile> attachments = [];
  List<String> attachmentUrls = [];

  DateTime selectedDate = DateTime.now();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isSaved = false;
  bool get isSaved => _isSaved;

  // Flag to indicate if we are viewing an existing complaint from the list
  bool _isViewingExisting = false;
  bool get isViewingExisting => _isViewingExisting;

  ComplaintViewModel(this._complaintService);

  Future<void> fetchUserComplaints(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _complaintService.getComplaints(token);
      _userComplaints = data.map((json) {
        return Complaint(
          complaintId: json['complaint_id'],
          category: json['category'],
          productName: json['product_name'],
          productPrice: json['product_price'].toString(),
          lossAmount: json['loss_amount'].toString(),
          dateIssue: DateTime.parse(json['date_issue']),
          phoneNo: json['phone_no'],
          email: json['email'],
          premiseType: json['premise_type'],
          premiseName: json['premise_name'],
          premiseAddress: json['premise_address'],
          postalCode: json['postal_code'],
          district: json['district'],
          state: json['state'],
          description: json['description'],
          latitude: json['latitude'],
          longitude: json['longitude'],
          attachmentUrls: (json['attachments'] as List)
              .map((a) => a['file_url'] as String)
              .toList(),
          idempotencyKey: '', // Not needed for viewing existing
        );
      }).toList();
    } catch (e) {
      _userComplaints = [];
      // Silent error or handle appropriately
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadExistingComplaint(Complaint complaint) {
    reset();
    _isViewingExisting = true;
    
    selectedCategory = complaint.category;
    productNameController.text = complaint.productName;
    productPriceController.text = complaint.productPrice;
    lossAmountController.text = complaint.lossAmount;
    selectedDate = complaint.dateIssue;
    dateIssueController.text = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    
    phoneNoController.text = complaint.phoneNo ?? '';
    emailController.text = complaint.email ?? '';
    
    selectedPremiseType = complaint.premiseType;
    premiseNameController.text = complaint.premiseName;
    addressController.text = complaint.premiseAddress;
    postalCodeController.text = complaint.postalCode;
    districtController.text = complaint.district ?? '';
    stateController.text = complaint.state ?? '';
    
    descriptionController.text = complaint.description ?? '';
    latitude = complaint.latitude;
    longitude = complaint.longitude;
    attachmentUrls = complaint.attachmentUrls;
    
    _isSaved = true;
    notifyListeners();
  }

  void startNewComplaint() {
    reset();
    _isViewingExisting = false;
    idempotencyKey = const Uuid().v4();
    notifyListeners();
  }

  void updateDate(DateTime date) {
    selectedDate = date;
    dateIssueController.text = "${date.day}/${date.month}/${date.year}";
    notifyListeners();
  }

  void setCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setPremiseType(String? type) {
    selectedPremiseType = type;
    notifyListeners();
  }

  void setLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  void addAttachment(XFile image) {
    if (attachments.length < 4) {
      attachments.add(image);
      notifyListeners();
    }
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    notifyListeners();
  }

  Complaint get complaint {
    idempotencyKey ??= const Uuid().v4();
    
    return Complaint(
      category: selectedCategory ?? '',
      productName: productNameController.text,
      productPrice: productPriceController.text,
      lossAmount: lossAmountController.text,
      dateIssue: selectedDate,
      phoneNo: phoneNoController.text.isEmpty ? null : phoneNoController.text,
      email: emailController.text.isEmpty ? null : emailController.text,
      premiseType: selectedPremiseType ?? '',
      premiseName: premiseNameController.text,
      premiseAddress: addressController.text,
      postalCode: postalCodeController.text,
      district: districtController.text.isEmpty ? null : districtController.text,
      state: stateController.text.isEmpty ? null : stateController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      latitude: latitude,
      longitude: longitude,
      attachments: attachments,
      attachmentUrls: attachmentUrls,
      idempotencyKey: idempotencyKey!,
    );
  }

  Future<void> saveCurrentComplaint(String token) async {
    _isSaving = true;
    _isAlreadySubmitted = false;
    notifyListeners();

    try {
      final response = await _complaintService.createComplaint(token, complaint);
      _isSaved = true;
      if (response['already_submitted'] == true) {
        _isAlreadySubmitted = true;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    productNameController.clear();
    productPriceController.clear();
    lossAmountController.clear();
    dateIssueController.clear();
    phoneNoController.clear();
    emailController.clear();
    premiseNameController.clear();
    addressController.clear();
    postalCodeController.clear();
    districtController.clear();
    stateController.clear();
    descriptionController.clear();

    selectedCategory = null;
    selectedPremiseType = null;
    selectedDate = DateTime.now();
    latitude = null;
    longitude = null;
    attachments = [];
    attachmentUrls = [];

    idempotencyKey = null;
    _isAlreadySubmitted = false;
    _isSaved = false;
    _isSaving = false;
    _isViewingExisting = false;
    notifyListeners();
  }

  void resetSavedStatus() {
    _isSaved = false;
    _isAlreadySubmitted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    productNameController.dispose();
    productPriceController.dispose();
    lossAmountController.dispose();
    dateIssueController.dispose();
    phoneNoController.dispose();
    emailController.dispose();
    premiseNameController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    districtController.dispose();
    stateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

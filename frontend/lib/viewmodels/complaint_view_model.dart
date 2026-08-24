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

  // Selection Mode
  bool _isSelectMode = false;
  bool get isSelectMode => _isSelectMode;
  
  final Set<int> _selectedComplaintIds = {};
  Set<int> get selectedComplaintIds => _selectedComplaintIds;

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
  String? selectedState;
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

  // Nearby Premises
  List<Map<String, dynamic>> _nearbyPremises = [];
  List<Map<String, dynamic>> get nearbyPremises => _nearbyPremises;
  bool _isFetchingNearby = false;
  bool get isFetchingNearby => _isFetchingNearby;

  // Flag to indicate if we are viewing an existing complaint from the list
  bool _isViewingExisting = false;
  bool get isViewingExisting => _isViewingExisting;

  ComplaintViewModel(this._complaintService);

  // Getter for grouped complaints
  Map<DateTime, List<Complaint>> get groupedComplaints {
    final grouped = <DateTime, List<Complaint>>{};
    for (final complaint in _userComplaints) {
      final date = DateTime(
        complaint.dateIssue.year,
        complaint.dateIssue.month,
        complaint.dateIssue.day,
      );
      grouped.putIfAbsent(date, () => []).add(complaint);
    }
    return grouped;
  }

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
          premiseType: json['premise_type'].trim(), // Trimmed here
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyPremises(double lat, double lng) async {
    _isFetchingNearby = true;
    notifyListeners();
    try {
      _nearbyPremises = await _complaintService.getNearbyPremises(lat, lng);
    } catch (e) {
      _nearbyPremises = [];
      rethrow;
    } finally {
      _isFetchingNearby = false;
      notifyListeners();
    }
  }

  void selectPremise(Map<String, dynamic> premise) {
    premiseNameController.text = premise['premise_name'] ?? '';
    addressController.text = premise['address'] ?? '';
    districtController.text = premise['district'] ?? '';
    stateController.text = premise['state'] ?? '';
    selectedState = premise['state'];
    selectedPremiseType = premise['premise_type'].trim(); // Trimmed here

    latitude = premise['latitude'];
    longitude = premise['longitude'];
    notifyListeners();
  }

  void toggleSelectMode() {
    _isSelectMode = !_isSelectMode;
    if (!_isSelectMode) {
      _selectedComplaintIds.clear();
    }
    notifyListeners();
  }

  void toggleComplaintSelection(int complaintId) {
    if (_selectedComplaintIds.contains(complaintId)) {
      _selectedComplaintIds.remove(complaintId);
      if (_selectedComplaintIds.isEmpty) {
        _isSelectMode = false;
      }
    } else {
      _selectedComplaintIds.add(complaintId);
      _isSelectMode = true;
    }
    notifyListeners();
  }

  Future<void> deleteSelectedComplaints(String token) async {
    if (_selectedComplaintIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _complaintService.deleteComplaints(token, _selectedComplaintIds.toList());
      final List<int> deletedIds = (response['deleted_complaint_ids'] as List).cast<int>();
      
      _userComplaints.removeWhere((c) => deletedIds.contains(c.complaintId));
      _selectedComplaintIds.clear();
      _isSelectMode = false;
    } catch (e) {
      rethrow;
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
    selectedState = complaint.state;
    premiseNameController.text = complaint.premiseName;
    addressController.text = complaint.premiseAddress;
    postalCodeController.text = complaint.postalCode ?? '';
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

  void setSelectedState(String? state) {
    selectedState = state;
    stateController.text = state ?? '';
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
      state: selectedState ?? stateController.text,
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
    selectedState = null;
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
    _isSelectMode = false;
    _selectedComplaintIds.clear();
    _nearbyPremises = [];
    _isFetchingNearby = false;
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

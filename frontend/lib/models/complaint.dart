import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Complaint {
  final int? complaintId;
  final String category;
  final String productName;
  final String productPrice;
  final String lossAmount;
  final DateTime dateIssue;
  final String? fullName;
  final String? nric;
  final String? phoneNo;
  final String? email;
  final String premiseType;
  final String premiseName;
  final String premiseAddress;
  final String? postalCode;
  final String? district;
  final String? state;
  String? description;
  double? latitude;
  double? longitude;
  List<XFile> attachments;
  List<String> attachmentUrls;
  final String idempotencyKey;

  Complaint({
    this.complaintId,
    required this.category,
    required this.productName,
    required this.productPrice,
    required this.lossAmount,
    required this.dateIssue,
    this.fullName,
    this.nric,
    this.phoneNo,
    this.email,
    required this.premiseType,
    required this.premiseName,
    required this.premiseAddress,
    this.postalCode,
    this.district,
    this.state,
    this.description,
    this.latitude,
    this.longitude,
    this.attachments = const [],
    this.attachmentUrls = const [],
    required this.idempotencyKey,
  });

  Map<String, dynamic> toFormFields() {
    return {
      'category': category,
      'product_name': productName,
      'product_price': num.tryParse(productPrice),
      'loss_amount': num.tryParse(lossAmount),
      'date_issue': DateFormat('yyyy-MM-dd').format(dateIssue),
      'full_name': (fullName == null || fullName!.isEmpty) ? null : fullName,
      'nric': (nric == null || nric!.isEmpty) ? null : nric,
      'phone_no': (phoneNo == null || phoneNo!.isEmpty) ? null : phoneNo,
      'email': (email == null || email!.isEmpty) ? null : email,
      'premise_type': premiseType,
      'premise_name': premiseName,
      'premise_address': premiseAddress,
      'postal_code': postalCode,
      'district': district,
      'state': state,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'idempotency_key': idempotencyKey,
    };
  }
}

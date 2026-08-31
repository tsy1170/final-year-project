import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/complaint_view_model.dart';
import '../../models/complaint.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';

class ComplaintSummaryView extends StatelessWidget {
  final double scale;

  const ComplaintSummaryView({
    super.key,
    required this.scale,
  });

  String _formatPrice(String price) {
    final double? value = double.tryParse(price);
    return value?.toStringAsFixed(2) ?? price;
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDFD),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          title: Text(
            "CONFIRM SAVE",
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          content: Text(
            textAlign: TextAlign.justify,
            "Are you sure you want to save? Once saved, all the information cannot be changed anymore.",
            style: TextStyle(
              fontSize: 14 * scale,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "CANCEL",
                style: TextStyle(
                  color: const Color(0xFF9A9FA5),
                  fontWeight: FontWeight.w700,
                  fontSize: 14 * scale,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleSave(context);
              },
              child: Text(
                "SAVE",
                style: TextStyle(
                  color: const Color(0xFFED1A4B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final complaintVM = Provider.of<ComplaintViewModel>(context, listen: false);

    if (authVM.accessToken == null) {
      showTopNotification(
        context,
        "Session expired. Please login again.",
        false,
        scale,
      );
      return;
    }

    try {
      await complaintVM.saveCurrentComplaint(authVM.accessToken!);
      if (context.mounted) {
        if (complaintVM.isAlreadySubmitted) {
          showTopNotification(
            context,
            "Complaint already submitted",
            false,
            scale,
          );
        } else {
          showTopNotification(
            context,
            "Complaint saved successfully",
            true,
            scale,
          );
          // Refresh list after saving
          complaintVM.fetchUserComplaints(authVM.accessToken!);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showTopNotification(
          context,
          e.toString().replaceAll("Exception: ", ""),
          false,
          scale,
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, Complaint complaint) async {
    final complaintVM = Provider.of<ComplaintViewModel>(context, listen: false);
    final String subject = 'ADUAN: ${complaint.category} - ${complaint.premiseName} - ${complaint.state ?? "-"}';

    showTopNotification(context, "Preparing attachments...", true, scale);

    // Get local paths — works for both local files and downloaded URLs
    final List<String> attachmentPaths = await complaintVM.getLocalAttachmentPaths();
    
    final StringBuffer body = StringBuffer();
    body.writeln('Notes');
    body.writeln(complaint.description?.isEmpty ?? true ? "No description provided." : complaint.description);

    body.writeln('COMPLAINT CATEGORY');
    body.writeln('Category: ${complaint.category}');
    body.writeln('Product Name: ${complaint.productName}');
    body.writeln('Product Price: RM ${_formatPrice(complaint.productPrice)}');
    body.writeln('Loss Amount: RM ${_formatPrice(complaint.lossAmount)}');
    body.writeln('Date Issue: ${DateFormat('dd/MM/yyyy').format(complaint.dateIssue)}');
    body.writeln();
    
    body.writeln('PERSONAL INFORMATION');
    body.writeln('Full Name: ${complaint.fullName ?? "-"}');
    body.writeln('NRIC: ${complaint.nric ?? "-"}');
    body.writeln('Phone No: ${complaint.phoneNo ?? "-"}');
    body.writeln('Email: ${complaint.email ?? "-"}');
    body.writeln();
    
    body.writeln('PREMISE INFORMATION');
    body.writeln('Premise Type: ${complaint.premiseType}');
    body.writeln('Premise Name: ${complaint.premiseName}');
    body.writeln('Address: ${complaint.premiseAddress}');
    body.writeln('Postal Code: ${complaint.postalCode ?? "-"}');
    body.writeln('District: ${complaint.district ?? "-"}');
    body.writeln('State: ${complaint.state ?? "-"}');
    body.writeln();
    
    if (complaint.latitude != null && complaint.longitude != null) {
      body.writeln('LOCATION');
      body.writeln('Latitude: ${complaint.latitude}');
      body.writeln('Longitude: ${complaint.longitude}');
      body.writeln('Map Link: https://www.google.com/maps/search/?api=1&query=${complaint.latitude},${complaint.longitude}');
      body.writeln();
    }

    final Email email = Email(
      body: body.toString(),
      subject: subject,
      recipients: ['e-aduan@kpdn.gov.my'],
      attachmentPaths: attachmentPaths,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (context.mounted) {
        showTopNotification(context, "Error opening email app: $e", false, scale);
      }
    }
  }

  Future<void> _sendWhatsApp(BuildContext context, Complaint complaint) async {
    final complaintVM = Provider.of<ComplaintViewModel>(context, listen: false);
    
    // Save images to gallery so user can see them in their phone's Gallery
    if (complaint.attachments.isNotEmpty || complaint.attachmentUrls.isNotEmpty) {
      try {
        showTopNotification(context, "Saving images to Gallery...", true, scale);
        await complaintVM.saveAttachmentsToGallery();
      } catch (e) {
        debugPrint("Gallery save error: $e");
        // We continue even if gallery save fails, as the user still wants to send the message
      }
    }

    final StringBuffer text = StringBuffer();
    text.writeln('*Notes*');
    text.writeln(complaint.description?.isEmpty ?? true ? "No description provided." : complaint.description);

    text.writeln('*COMPLAINT CATEGORY*');
    text.writeln('Category: ${complaint.category}');
    text.writeln('Product Name: ${complaint.productName}');
    text.writeln('Product Price: RM ${_formatPrice(complaint.productPrice)}');
    text.writeln('Loss Amount: RM ${_formatPrice(complaint.lossAmount)}');
    text.writeln('Date Issue: ${DateFormat('dd/MM/yyyy').format(complaint.dateIssue)}');
    text.writeln();
    
    text.writeln('*PERSONAL INFORMATION*');
    text.writeln('Full Name: ${complaint.fullName ?? "-"}');
    text.writeln('NRIC: ${complaint.nric ?? "-"}');
    text.writeln('Phone No: ${complaint.phoneNo ?? "-"}');
    text.writeln('Email: ${complaint.email ?? "-"}');
    text.writeln();
    
    text.writeln('*PREMISE INFORMATION*');
    text.writeln('Premise Type: ${complaint.premiseType}');
    text.writeln('Premise Name: ${complaint.premiseName}');
    text.writeln('Address: ${complaint.premiseAddress}');
    text.writeln('Postal Code: ${complaint.postalCode ?? "-"}');
    text.writeln('District: ${complaint.district ?? "-"}');
    text.writeln('State: ${complaint.state ?? "-"}');
    text.writeln();
    
    if (complaint.latitude != null && complaint.longitude != null) {
      text.writeln('*LOCATION*');
      text.writeln('Latitude: ${complaint.latitude}');
      text.writeln('Longitude: ${complaint.longitude}');
      text.writeln('Map Link: https://www.google.com/maps/search/?api=1&query=${complaint.latitude},${complaint.longitude}');
      text.writeln();
    }

    final String textContent = text.toString();
    final uri = Uri.parse(
      'https://wa.me/60198488000?text=${Uri.encodeComponent(textContent)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showTopNotification(context, "WhatsApp is not installed.", false, scale);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showTopNotification(context, "Error opening WhatsApp: $e", false, scale);
      }
    }
  }

  void _showSendOptions(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15 * scale)),
      ),
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SEND COMPLAINT VIA",
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
              SizedBox(height: 20 * scale),
              ListTile(
                leading: Icon(
                  Icons.email_outlined,
                  color: const Color(0xFF1A1D1F),
                  size: 24 * scale,
                ),
                title: Text("Email", style: TextStyle(fontSize: 14 * scale)),
                onTap: () {
                  Navigator.pop(modalContext);
                  _sendEmail(context, complaint);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.chat_outlined,
                  color: const Color(0xFF1A1D1F),
                  size: 24 * scale,
                ),
                title: Text("WhatsApp", style: TextStyle(fontSize: 14 * scale)),
                onTap: () {
                  Navigator.pop(modalContext);
                  _sendWhatsApp(context, complaint);
                },
              ),
              SizedBox(height: 20 * scale),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, complaintVM, child) {
        final complaint = complaintVM.complaint;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFAF3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFAF3),
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: const Color(0xFF1A1D1F),
                size: 20 * scale,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'SUMMARY',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (complaintVM.isSaving)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                  child: SizedBox(
                    width: 15 * scale,
                    height: 15 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                )
              else if (complaintVM.isSaved && !complaintVM.isViewingExisting)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: const Color(0xFF1A1D1F),
                    size: 23 * scale,
                  ),
                )
              else if (!complaintVM.isViewingExisting)
                IconButton(
                  onPressed: () => _showConfirmationDialog(context),
                  icon: Icon(
                    Icons.save,
                    color: const Color(0xFF1A1D1F),
                    size: 23 * scale,
                  ),
                ),
              SizedBox(width: 10 * scale),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("COMPLAINT CATEGORY", [
                  _buildInfoRow("Category", complaint.category),
                  _buildInfoRow("Product Name", complaint.productName),
                  _buildInfoRow(
                    "Product Price",
                    "RM ${_formatPrice(complaint.productPrice)}",
                  ),
                  _buildInfoRow("Loss Amount", "RM ${_formatPrice(complaint.lossAmount)}"),
                  _buildInfoRow(
                    "Date Issue",
                    DateFormat('dd/MM/yyyy').format(complaint.dateIssue),
                  ),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("YOUR INFORMATION", [
                  _buildInfoRow("Full Name", complaint.fullName ?? "-"),
                  _buildInfoRow("NRIC", complaint.nric ?? "-"),
                  _buildInfoRow("Phone No", complaint.phoneNo ?? "-"),
                  _buildInfoRow("Email", complaint.email ?? "-"),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("PREMISE INFORMATION", [
                  _buildInfoRow("Premise Type", complaint.premiseType),
                  _buildInfoRow("Premise Name", complaint.premiseName),
                  _buildInfoRow("Address", complaint.premiseAddress),
                  _buildInfoRow("Postal Code", complaint.postalCode ?? "-"),
                  _buildInfoRow("District", complaint.district ?? "-"),
                  _buildInfoRow("State", complaint.state ?? "-"),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("PREMISE LOCATION", [
                  if (complaint.latitude != null &&
                      complaint.longitude != null) ...[
                    Container(
                      height: 150 * scale,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1 * scale),
                        border: Border.all(
                          color: const Color(0xFF1A1D1F).withValues(alpha: 0.1),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            complaint.latitude!,
                            complaint.longitude!,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("premise_loc"),
                            position: LatLng(
                              complaint.latitude!,
                              complaint.longitude!,
                            ),
                          ),
                        },
                        liteModeEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    _buildInfoRow(
                      "Latitude",
                      complaint.latitude!.toStringAsFixed(8),
                    ),
                    _buildInfoRow(
                      "Longitude",
                      complaint.longitude!.toStringAsFixed(8),
                    ),
                  ] else
                    Text(
                      "No coordinates selected.",
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("DESCRIPTIONS", [
                  Text(
                    complaint.description == null ||
                            complaint.description!.isEmpty
                        ? "No description provided."
                        : complaint.description!,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("ATTACHMENTS", [
                  if (complaint.attachments.isEmpty && complaint.attachmentUrls.isEmpty)
                    Text(
                      "No attachments provided.",
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20 * scale,
                        mainAxisSpacing: 20 * scale,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: complaint.attachments.isNotEmpty 
                          ? complaint.attachments.length 
                          : complaint.attachmentUrls.length,
                      itemBuilder: (context, index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1 * scale),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    width: 1 * scale,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: complaint.attachments.isNotEmpty
                                    ? Image.file(
                                        File(complaint.attachments[index].path),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        complaint.attachmentUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                      ),
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              (index + 1).toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1D1F),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ]),
                SizedBox(height: 30 * scale),
                CustomButton(
                  label: "SUBMIT",
                  onTap: () => _showSendOptions(context, complaint),
                  bg: const Color(0xFF1A1D1F),
                  text: Colors.white,
                  scale: scale,
                ),
                SizedBox(height: 20 * scale + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 3 * scale,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1 * scale),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF325E6A),
            ),
          ),
        ),
        SizedBox(height: 20 * scale),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120 * scale,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

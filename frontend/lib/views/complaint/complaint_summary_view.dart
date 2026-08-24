import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/complaint_view_model.dart';
import '../widgets/common/animated_notification.dart';

class ComplaintSummaryView extends StatelessWidget {
  final double scale;

  const ComplaintSummaryView({
    super.key,
    required this.scale,
  });

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDFD),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, complaintVM, child) {
        final complaint = complaintVM.complaint;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFDFD),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFDFD),
            elevation: 0,
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
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1 * scale),
              child: Divider(
                height: 1 * scale,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
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
                    "RM ${complaint.productPrice}",
                  ),
                  _buildInfoRow("Loss Amount", "RM ${complaint.lossAmount}"),
                  _buildInfoRow(
                    "Date Issue",
                    DateFormat('dd/MM/yyyy').format(complaint.dateIssue),
                  ),
                ]),
                SizedBox(height: 45 * scale),
                _buildSection("YOUR INFORMATION", [
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
                        fontWeight: FontWeight.w500
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
                SizedBox(
                  width: double.infinity,
                  child: _buildButton(
                    "SUBMIT",
                    const Color(0xFF1A1D1F),
                    Colors.white,
                    () => _showSendOptions(context),
                  ),
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
              color: const Color(0xFF1A1D1F),
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

  Widget _buildButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 50 * scale,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
            side: bgColor == const Color(0xFFF4F4F4)
                ? BorderSide(
                    color: const Color(0xFF1A1D1F).withValues(alpha: 0.1),
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scale),
        ),
      ),
    );
  }

  void _showSendOptions(BuildContext context) {
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
                  showTopNotification(
                    context,
                    "Sending via Email...",
                    true,
                    scale,
                  );
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
                  showTopNotification(
                    context,
                    "Sending via WhatsApp...",
                    true,
                    scale,
                  );
                },
              ),
              SizedBox(height: 20 * scale),
            ],
          ),
        );
      },
    );
  }
}

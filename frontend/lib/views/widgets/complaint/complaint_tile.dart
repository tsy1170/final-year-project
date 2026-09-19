import 'package:flutter/material.dart';
import '../../../models/complaint.dart';
import '../../../viewmodels/complaint_view_model.dart';
import '../../complaint/complaint_summary_view.dart';

class ComplaintTile extends StatelessWidget {
  final Complaint complaint;
  final ComplaintViewModel viewModel;
  final double scale;

  const ComplaintTile({
    super.key,
    required this.complaint,
    required this.viewModel,
    required this.scale,
  });

  String _formatPrice(String price) {
    final double? value = double.tryParse(price);
    return value?.toStringAsFixed(2) ?? price;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedComplaintIds.contains(
      complaint.complaintId,
    );
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8 * scale),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFB85A3A).withValues(alpha: 0.05)
            : const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFB85A3A)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1.5 * scale,
        ),
        boxShadow: isSelected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16 * scale),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (viewModel.isSelectMode) {
              viewModel.toggleComplaintSelection(complaint.complaintId!);
            } else {
              viewModel.loadExistingComplaint(complaint);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplaintSummaryView(scale: scale),
                ),
              );
            }
          },
          onLongPress: () {
            viewModel.toggleComplaintSelection(complaint.complaintId!);
          },
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pill Tag for Complaint Type
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF6F3),
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Text(
                        complaint.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB85A3A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    // Premise Name as Title
                    Text(
                      complaint.premiseName,
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    SizedBox(height: 7 * scale),
                    // Details formatted naturally
                    Text(
                      "${complaint.premiseType}",
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1D1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 7 * scale),
                    Text(
                      "${complaint.productName} • RM ${_formatPrice(complaint.lossAmount)} loss",
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9A9FA5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 20 * scale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "View Details",
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D1F).withValues(alpha: 0.4),
                          ),
                        ),
                        SizedBox(width: 4 * scale),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10 * scale,
                          color: const Color(0xFF1A1D1F).withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (viewModel.isSelectMode)
                Positioned(
                  top: 15 * scale,
                  right: 15 * scale,
                  child: Container(
                    width: 22 * scale,
                    height: 22 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFB85A3A)
                            : const Color(0xFF1A1D1F).withValues(alpha: 0.2),
                        width: 2 * scale,
                      ),
                      color: isSelected
                          ? const Color(0xFFB85A3A)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14 * scale,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

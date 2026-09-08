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

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.selectedComplaintIds.contains(
      complaint.complaintId,
    );
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border(
          bottom: BorderSide(
            color: isSelected
                ? const Color(0xFF325E6A)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
          top: BorderSide(
            color: isSelected
                ? const Color(0xFF325E6A)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
          right: BorderSide(
            color: isSelected
                ? const Color(0xFF325E6A)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1 * scale,
          ),
          left: BorderSide(
            color: isSelected
                ? const Color(0xFF325E6A)
                : Colors.grey.withValues(alpha: 0.3),
            width: 4 * scale,
          ),
        ),
        boxShadow: isSelected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: -6,
                  blurRadius: 10,
                  offset: const Offset(4, 8),
                ),
              ],
      ),
      child: Material(
        color: isSelected
            ? const Color(0xFF325E6A).withValues(alpha: 0.05)
            : const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(12 * scale),
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
                padding: EdgeInsets.all(16 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    SizedBox(height: 15 * scale),
                    _buildInfoRow("Product", complaint.productName),
                    SizedBox(height: 5 * scale),
                    _buildInfoRow("Premise", complaint.premiseName),
                    SizedBox(height: 5 * scale),
                    _buildInfoRow("Type", complaint.premiseType),
                    SizedBox(height: 5 * scale),
                    _buildInfoRow(
                      "Loss Amount",
                      complaint.lossAmount,
                      isPrice: true,
                    ),
                    SizedBox(height: 10 * scale),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "view details",
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(
                                0xFF1A1D1F,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10 * scale,
                            color: const Color(
                              0xFF1A1D1F,
                            ).withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (viewModel.isSelectMode)
                Positioned(
                  top: 12 * scale,
                  right: 12 * scale,
                  child: Container(
                    width: 20 * scale,
                    height: 20 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A1D1F)
                            : const Color(0xFF1A1D1F).withValues(alpha: 0.3),
                        width: 1 * scale,
                      ),
                      color: isSelected
                          ? const Color(0xFF325E6A)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14 * scale,
                            color: const Color(0xFFFFFDFD),
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

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110 * scale,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9A9FA5),
            ),
          ),
        ),
        Expanded(
          child: isPrice
              ? Text(
                  'RM $value',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: const Color(0xFF1A1D1F),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: const Color(0xFF1A1D1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

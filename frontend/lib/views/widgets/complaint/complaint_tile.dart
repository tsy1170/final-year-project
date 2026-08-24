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
    final isSelected = viewModel.selectedComplaintIds.contains(complaint.complaintId);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1 * scale),
        border: Border(
          bottom: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * scale,
          ),
          top: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * scale,
          ),
          right: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * scale,
          ),
          left: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 4 * scale,
          ),
        ),
      ),
      child: Material(
        color: isSelected ? const Color(0xFFED1A4B).withValues(alpha: 0.05) : const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(1 * scale),
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
                padding: EdgeInsets.all(12 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.category.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    const Spacer(),
                    _buildGridInfoRow("Item", complaint.productName),
                    SizedBox(height: 10 * scale),
                    _buildGridInfoRow("Premise", complaint.premiseName),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12 * scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (viewModel.isSelectMode)
                Positioned(
                  top: 8 * scale,
                  right: 8 * scale,
                  child: Container(
                    width: 18 * scale,
                    height: 18 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F).withValues(alpha: 0.3),
                        width: 1.5 * scale,
                      ),
                      color: isSelected ? const Color(0xFFED1A4B) : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 12 * scale,
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

  Widget _buildGridInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9 * scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF9A9FA5),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11 * scale,
            color: const Color(0xFF1A1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

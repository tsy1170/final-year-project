import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/complaint_view_model.dart';
import '../models/complaint.dart';
import 'widgets/complaint/complaint_header.dart';
import 'widgets/complaint/complaint_empty_state.dart';
import 'widgets/complaint/complaint_logged_out.dart';
import 'widgets/complaint/complaint_delete_button.dart';
import 'add_complaint_view.dart';
import 'complaint_summary_view.dart';
import 'widgets/common/animated_notification.dart';

class ComplaintView extends StatefulWidget {
  final double scale;

  const ComplaintView({super.key, required this.scale});

  @override
  State<ComplaintView> createState() => _ComplaintViewState();
}

class _ComplaintViewState extends State<ComplaintView> {
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authViewModel = Provider.of<AuthViewModel>(context);
    if (authViewModel.isLoggedIn && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ComplaintViewModel>().fetchUserComplaints(authViewModel.accessToken!);
      });
    } else if (!authViewModel.isLoggedIn) {
      _hasFetched = false;
    }
  }

  Map<DateTime, List<Complaint>> _groupComplaintsByDate(List<Complaint> complaints) {
    final grouped = <DateTime, List<Complaint>>{};
    for (final complaint in complaints) {
      final date = DateTime(
        complaint.dateIssue.year,
        complaint.dateIssue.month,
        complaint.dateIssue.day,
      );
      grouped.putIfAbsent(date, () => []).add(complaint);
    }
    return grouped;
  }

  void _showDeleteConfirmationDialog(ComplaintViewModel viewModel, String token) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDFD),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * widget.scale),
          ),
          title: Text(
            "CONFIRM DELETE",
            style: TextStyle(
              fontSize: 16 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
            ),
          ),
          content: Text(
            "Are you sure you want to delete ${viewModel.selectedComplaintIds.length} selected complaint(s)? This action cannot be undone.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 14 * widget.scale,
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
                  fontSize: 14 * widget.scale,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleDelete(viewModel, token);
              },
              child: Text(
                "DELETE",
                style: TextStyle(
                  color: const Color(0xFFED1A4B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14 * widget.scale,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelete(ComplaintViewModel viewModel, String token) async {
    try {
      await viewModel.deleteSelectedComplaints(token);
      if (mounted) {
        showTopNotification(context, "Complaints deleted successfully", true, widget.scale);
      }
    } catch (e) {
      if (mounted) {
        showTopNotification(context, e.toString().replaceAll("Exception: ", ""), false, widget.scale);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final complaintViewModel = context.watch<ComplaintViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Stack(
        children: [
          Column(
            children: [
              ComplaintHeader(
                scale: widget.scale,
                isLoggedIn: authViewModel.isLoggedIn,
                isSelectMode: complaintViewModel.isSelectMode,
                onAddPressed: () {
                  complaintViewModel.startNewComplaint();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddComplaintView(scale: widget.scale),
                    ),
                  );
                },
                onClosePressed: () {
                  complaintViewModel.toggleSelectMode();
                },
              ),
              Expanded(
                child: !authViewModel.isLoggedIn
                    ? ComplaintLoggedOutState(scale: widget.scale)
                    : complaintViewModel.isLoading && complaintViewModel.userComplaints.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1A1D1F),
                            ),
                          )
                        : complaintViewModel.userComplaints.isEmpty
                            ? ComplaintEmptyState(scale: widget.scale)
                            : RefreshIndicator(
                                onRefresh: () => complaintViewModel.fetchUserComplaints(authViewModel.accessToken!),
                                color: const Color(0xFFFFFDFD),
                                backgroundColor: const Color(0xFF1A1D1F),
                                child: _buildGroupedComplaintList(complaintViewModel),
                              ),
              ),
            ],
          ),
          if (complaintViewModel.isSelectMode && complaintViewModel.selectedComplaintIds.isNotEmpty)
            ComplaintDeleteButton(
              scale: widget.scale,
              itemCount: complaintViewModel.selectedComplaintIds.length,
              onDeletePressed: () => _showDeleteConfirmationDialog(complaintViewModel, authViewModel.accessToken!),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedComplaintList(ComplaintViewModel viewModel) {
    final groupedComplaints = _groupComplaintsByDate(viewModel.userComplaints);
    final sortedDates = groupedComplaints.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20 * widget.scale,
        20 * widget.scale,
        20 * widget.scale,
        180 * widget.scale,
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final complaints = groupedComplaints[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 10 * widget.scale),
              child: Text(
                DateFormat('dd MMMM yyyy').format(date).toUpperCase(),
                style: TextStyle(
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                  letterSpacing: 1 * widget.scale,
                ),
              ),
            ),
            GridView.builder(
              padding: EdgeInsets.only(top: 25 * widget.scale),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8 * widget.scale,
                mainAxisSpacing: 8 * widget.scale,
                mainAxisExtent: 180 * widget.scale,
              ),
              itemCount: complaints.length,
              itemBuilder: (context, i) {
                return _buildComplaintTile(complaints[i], viewModel);
              },
            ),
            SizedBox(height: 30 * widget.scale),
          ],
        );
      },
    );
  }

  Widget _buildComplaintTile(Complaint complaint, ComplaintViewModel viewModel) {
    final isSelected = viewModel.selectedComplaintIds.contains(complaint.complaintId);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1 * widget.scale),
        border: Border(
          bottom: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * widget.scale,
          ),
          top: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * widget.scale,
          ),
          right: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 1 * widget.scale,
          ),
          left: BorderSide(
            color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
            width: 4 * widget.scale,
          ),
        ),
      ),
      child: Material(
        color: isSelected ? const Color(0xFFED1A4B).withValues(alpha: 0.05) : const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(1 * widget.scale),
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
                  builder: (context) => ComplaintSummaryView(scale: widget.scale),
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
                padding: EdgeInsets.all(12 * widget.scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.category.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * widget.scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    const Spacer(),
                    _buildGridInfoRow("Item", complaint.productName),
                    SizedBox(height: 10 * widget.scale),
                    _buildGridInfoRow("Premise", complaint.premiseName),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12 * widget.scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (viewModel.isSelectMode)
                Positioned(
                  top: 8 * widget.scale,
                  right: 8 * widget.scale,
                  child: Container(
                    width: 18 * widget.scale,
                    height: 18 * widget.scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F).withValues(alpha: 0.3),
                        width: 1.5 * widget.scale,
                      ),
                      color: isSelected ? const Color(0xFFED1A4B) : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 12 * widget.scale,
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
            fontSize: 9 * widget.scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF9A9FA5),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11 * widget.scale,
            color: const Color(0xFF1A1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

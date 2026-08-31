import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/complaint_view_model.dart';
import '../widgets/complaint/complaint_empty_state.dart';
import '../widgets/complaint/complaint_logged_out.dart';
import '../widgets/complaint/complaint_delete_button.dart';
import '../widgets/complaint/complaint_tile.dart';
import 'add_complaint_view.dart';
import '../widgets/common/animated_notification.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          complaintViewModel.isSelectMode ? 'SELECT ITEMS' : 'COMPLAINTS',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (authViewModel.isLoggedIn)
            IconButton(
              onPressed: complaintViewModel.isSelectMode
                  ? () => complaintViewModel.toggleSelectMode()
                  : () {
                      complaintViewModel.startNewComplaint();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddComplaintView(scale: widget.scale),
                        ),
                      );
                    },
              icon: Icon(
                complaintViewModel.isSelectMode ? Icons.close_rounded : Icons.add_circle_outline_rounded,
                size: 26 * widget.scale,
                color: const Color(0xFF325E6A),
              ),
            ),
          SizedBox(width: 10 * widget.scale),
        ],
      ),
      body: Stack(
        children: [
          !authViewModel.isLoggedIn
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
    final groupedComplaints = viewModel.groupedComplaints;
    final sortedDates = groupedComplaints.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20 * widget.scale,
        10 * widget.scale,
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
              padding: EdgeInsets.only(top: index == 0 ? 0 : 5 * widget.scale, left: 10 * widget.scale),
              child: Text(
                DateFormat('dd MMMM yyyy').format(date).toUpperCase(),
                style: TextStyle(
                  fontSize: 14 * widget.scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF325E6A),
                  letterSpacing: 1 * widget.scale,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 15 * widget.scale),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: complaints.length,
                separatorBuilder: (context, i) => SizedBox(),
                itemBuilder: (context, i) {
                  return ComplaintTile(
                    complaint: complaints[i],
                    viewModel: viewModel,
                    scale: widget.scale,
                  );
                },
              ),
            ),
            SizedBox(height: 25 * widget.scale),
          ],
        );
      },
    );
  }
}

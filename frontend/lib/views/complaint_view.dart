import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/complaint_view_model.dart';
import '../models/complaint.dart';
import 'widgets/complaint/complaint_header.dart';
import 'widgets/complaint/complaint_empty_state.dart';
import 'widgets/complaint/complaint_logged_out.dart';
import 'add_complaint_view.dart';
import 'complaint_summary_view.dart';

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

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final complaintViewModel = context.watch<ComplaintViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Column(
        children: [
          ComplaintHeader(
            scale: widget.scale,
            isLoggedIn: authViewModel.isLoggedIn,
            onAddPressed: () {
              complaintViewModel.startNewComplaint();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddComplaintView(scale: widget.scale),
                ),
              );
            },
          ),
          Expanded(
            child: !authViewModel.isLoggedIn
                ? ComplaintLoggedOutState(scale: widget.scale)
                : complaintViewModel.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1D1F),
                        ),
                      )
                    : complaintViewModel.userComplaints.isEmpty
                        ? ComplaintEmptyState(scale: widget.scale)
                        : RefreshIndicator(
                            onRefresh: () => complaintViewModel.fetchUserComplaints(authViewModel.accessToken!),
                            color: const Color(0xFF1A1D1F),
                            child: _buildGroupedComplaintList(complaintViewModel),
                          ),
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
        120 * widget.scale,
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
                  fontSize: 15 * widget.scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 20 * widget.scale),
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
            SizedBox(height: 50 * widget.scale),
          ],
        );
      },
    );
  }

  Widget _buildComplaintTile(Complaint complaint, ComplaintViewModel viewModel) {
    final borderRadius = BorderRadius.circular(1 * widget.scale);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border(
          bottom: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
          top: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
          right: BorderSide(color: const Color(0xFF1A1D1F), width: 1 * widget.scale),
          left: BorderSide(color: const Color(0xFF1A1D1F), width: 4 * widget.scale),
        ),
      ),
      child: Material(
        color: const Color(0xFFFFFDFD),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            viewModel.loadExistingComplaint(complaint);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComplaintSummaryView(scale: widget.scale),
              ),
            );
          },
          child: Padding(
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
                SizedBox(height: 12 * widget.scale),
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

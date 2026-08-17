import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/complaint/complaint_header.dart';
import 'widgets/complaint/complaint_empty_state.dart';
import 'widgets/complaint/complaint_logged_out.dart';
import 'add_complaint_view.dart';

class ComplaintView extends StatelessWidget {
  final double scale;

  const ComplaintView({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Container(
      color: const Color(0xFFFFFDFD),
      child: Column(
        children: [
          ComplaintHeader(
            scale: scale,
            isLoggedIn: authViewModel.isLoggedIn,
            onAddPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddComplaintView(scale: scale),
                ),
              );
            },
          ),
          Expanded(
            child: !authViewModel.isLoggedIn
                ? ComplaintLoggedOutState(scale: scale)
                : ComplaintEmptyState(scale: scale),
          ),
        ],
      ),
    );
  }
}

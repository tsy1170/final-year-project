import 'package:flutter/material.dart';

class ProfileUserCard extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final double scale;

  const ProfileUserCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF325E6A),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1 * scale,
        ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF325E6A).withValues(alpha: 0.5), // Shadow color
              spreadRadius: -6,                     // How far the shadow extends
              blurRadius: 8,                      // Softness of the shadow
              offset: const Offset(6, 6),        // Offset of the shadow, 2),
            )
          ]
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle, color: const Color(0xFFFFFDFD), size: 60 * scale),
          SizedBox(width: 20 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFFDFD),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  userEmail ?? '',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: const Color(0xFFFFFDFD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

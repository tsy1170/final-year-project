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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          // Elegant Avatar Stage
          Container(
            padding: EdgeInsets.all(4 * scale),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB85A3A).withValues(alpha: 0.1),
                width: 2 * scale,
              ),
            ),
            child: Container(
              width: 60 * scale,
              height: 60 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F5F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: const Color(0xFFB85A3A),
                size: 35 * scale,
              ),
            ),
          ),
          SizedBox(width: 20 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName ?? 'User',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1D1F),
                        letterSpacing: -0.5,
                      ),
                    ),

                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  userEmail ?? '',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: const Color(0xFF9A9FA5),
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

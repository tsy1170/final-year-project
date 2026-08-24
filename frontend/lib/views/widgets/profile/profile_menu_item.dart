import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final double scale;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFD),
            borderRadius: BorderRadius.circular(1 * scale),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1 * scale,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1A1D1F), size: 22 * scale),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

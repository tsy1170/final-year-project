import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final Color text;
  final bool isOutlined;
  final IconData? icon;
  final double scale;

  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.bg,
    required this.text,
    required this.scale,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50 * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: text,
          side: isOutlined ? BorderSide(color: text) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1 * scale),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
        ),
        child: Row(
          mainAxisAlignment:
              icon != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (icon != null) Icon(icon, size: 20 * scale),
          ],
        ),
      ),
    );
  }
}

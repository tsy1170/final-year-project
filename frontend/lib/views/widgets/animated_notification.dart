import 'package:flutter/material.dart';

class AnimatedTopNotification extends StatefulWidget {
  final String message;
  final bool status;
  final double scale;
  final VoidCallback onDismiss;

  const AnimatedTopNotification({
    super.key,
    required this.message,
    required this.status,
    required this.scale,
    required this.onDismiss,
  });

  @override
  State<AnimatedTopNotification> createState() => _AnimatedTopNotificationState();
}

class _AnimatedTopNotificationState extends State<AnimatedTopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 20 * widget.scale),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20 * widget.scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * widget.scale,
                    vertical: 12 * widget.scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1F),
                    borderRadius: BorderRadius.circular(1 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.status == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: const Color(0xFFFFFDFD),
                        size: 24 * widget.scale,
                      ),
                      SizedBox(width: 12 * widget.scale),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * widget.scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showTopNotification(BuildContext context, String message, bool status, double scale) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => AnimatedTopNotification(
      message: message,
      status: status,
      scale: scale,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  overlay.insert(overlayEntry);
}

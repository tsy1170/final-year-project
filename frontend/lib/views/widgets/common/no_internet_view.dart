import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'animated_notification.dart';
import '../../../viewmodels/connectivity_view_model.dart';

class NoInternetView extends StatelessWidget {
  const NoInternetView({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityVM = context.watch<ConnectivityViewModel>();
    final double width = MediaQuery.of(context).size.width;
    final double scale = width / 402;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3), // Consistent with app background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon representation for offline
                Container(
                  padding: EdgeInsets.all(24 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EFEA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 72 * scale,
                    color: const Color(0xFFB85A3A),
                  ),
                ),
                SizedBox(height: 25 * scale),
                
                // NO INTERNET heading
                Text(
                  "NO INTERNET",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1D1F),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 7 * scale),
                
                // Details text
                Text(
                  "Internet connection lost. Please check your Internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6F767E),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30 * scale),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 48 * scale,
                  child: ElevatedButton(
                    onPressed: connectivityVM.isChecking
                        ? null
                        : () async {
                            await connectivityVM.checkConnection();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1D1F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1A1D1F).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      elevation: 0,
                    ),
                    child: connectivityVM.isChecking
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Retry",
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

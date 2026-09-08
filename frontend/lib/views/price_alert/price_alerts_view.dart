import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/price_alert.dart';
import '../widgets/price_alert/price_alert_card.dart';
import '../widgets/common/animated_notification.dart';

class PriceAlertsView extends StatefulWidget {
  final double scale;

  const PriceAlertsView({super.key, required this.scale});

  @override
  State<PriceAlertsView> createState() => _PriceAlertsViewState();
}

class _PriceAlertsViewState extends State<PriceAlertsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      if (authVM.isLoggedIn && authVM.accessToken != null) {
        context.read<NotificationViewModel>().fetchPriceAlerts(authVM.accessToken!);
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, PriceAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDFD),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        title: Text(
          "DELETE NOTIFICATION",
          style: TextStyle(
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        content: Text(
          "Are you sure you want to delete the price notification for ${alert.itemName}?",
          style: TextStyle(
            fontSize: 14 * widget.scale,
            color: const Color(0xFF1A1D1F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () async {
              Navigator.pop(context);
              final authVM = context.read<AuthViewModel>();
              final notificationVM = context.read<NotificationViewModel>();
              
              try {
                final message = await notificationVM.removePriceAlert(
                  authVM.accessToken!,
                  alert.alertId,
                );
                if (mounted) {
                  showTopNotification(context, message, true, widget.scale);
                }
              } catch (e) {
                if (mounted) {
                  showTopNotification(context, e.toString().replaceAll('Exception: ', ''), false, widget.scale);
                }
              }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PRICE ALERTS',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)));
          }

          if (viewModel.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60 * widget.scale, color: Colors.grey),
                  SizedBox(height: 16 * widget.scale),
                  Text(
                    'No price alerts found',
                    style: TextStyle(fontSize: 16 * widget.scale, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16 * widget.scale),
            itemCount: viewModel.alerts.length,
            itemBuilder: (context, index) {
              final alert = viewModel.alerts[index];
              return PriceAlertCard(
                alert: alert,
                scale: widget.scale,
                onEdit: () {
                  // TODO: Implement edit logic
                },
                onDelete: () => _showDeleteConfirmation(context, alert),
              );
            },
          );
        },
      ),
    );
  }
}

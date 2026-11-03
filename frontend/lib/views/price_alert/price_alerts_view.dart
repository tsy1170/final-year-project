import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/location_view_model.dart';
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

  Future<void> _showEditDialog(BuildContext context, PriceAlert alert) async {
    final authVM = context.read<AuthViewModel>();
    final notificationVM = context.read<NotificationViewModel>();
    final locationVM = context.read<LocationViewModel>();
    
    if (!authVM.isLoggedIn || authVM.accessToken == null) return;

    final TextEditingController priceController = TextEditingController(
      text: alert.target_price.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * widget.scale)),
        title: Text(
          'Update Price Notification',
          style: TextStyle(
            fontSize: 18 * widget.scale, 
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1D1F),
          )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${alert.itemName}',
              style: TextStyle(fontSize: 13 * widget.scale, fontWeight: FontWeight.w600, color: const Color(0xFF9A9FA5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12 * widget.scale),
            Text(
              'Enter new target price:', 
              style: TextStyle(fontSize: 14 * widget.scale, color: const Color(0xFF1A1D1F))
            ),
            SizedBox(height: 16 * widget.scale),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: true,
              style: TextStyle(fontSize: 16 * widget.scale, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7F5F0),
                prefixText: 'RM ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB85A3A)),
                hintText: '0.00',
                contentPadding: EdgeInsets.symmetric(horizontal: 15 * widget.scale, vertical: 12 * widget.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: const Color(0xFF9A9FA5), fontSize: 13 * widget.scale, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              final targetPrice = double.tryParse(priceController.text);
              if (targetPrice == null || targetPrice <= 0) return;
              
              Navigator.pop(context);

              try {
                await notificationVM.createPriceAlert(
                  authVM.accessToken!,
                  alert.itemCode,
                  targetPrice,
                  locationVM.currentPosition?.latitude ?? 5.356,
                  locationVM.currentPosition?.longitude ?? 100.301,
                );
                
                await notificationVM.fetchPriceAlerts(authVM.accessToken!);
                
                if (mounted) {
                  showTopNotification(context, "Notification Updated Successfully", true, widget.scale);
                }
              } catch (e) {
                if (mounted) {
                  showTopNotification(context, e.toString().replaceAll('Exception: ', ''), false, widget.scale);
                }
              }
            },
            child: Text('UPDATE', style: TextStyle(color: const Color(0xFFB85A3A), fontSize: 13 * widget.scale, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PRICE NOTIFICATIONS',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 16 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0
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
                    'No price notification found',
                    style: TextStyle(fontSize: 16 * widget.scale, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 10 * widget.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 5 * widget.scale, bottom: 15 * widget.scale),
                  child: Text(
                    "ACTIVE ALERTS",
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF9A9FA5),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: viewModel.alerts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: const Color(0xFFF2EFEA),
                      indent: 20 * widget.scale,
                      endIndent: 20 * widget.scale,
                    ),
                    itemBuilder: (context, index) {
                      final alert = viewModel.alerts[index];
                      return PriceAlertCard(
                        alert: alert,
                        scale: widget.scale,
                        onEdit: () => _showEditDialog(context, alert),
                        onDelete: () => _showDeleteConfirmation(context, alert),
                        isFirst: index == 0,
                        isLast: index == viewModel.alerts.length - 1,
                      );
                    },
                  ),
                ),
                SizedBox(height: 40 * widget.scale),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../viewmodels/optimization_view_model.dart';
import 'optimization_item_row.dart';
import 'optimization_missing_item_row.dart';

class OptimizationMultiStoreContent extends StatelessWidget {
  final OptimizationViewModel viewModel;
  final double scale;

  const OptimizationMultiStoreContent({
    super.key,
    required this.viewModel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1D1F)),
      );
    }

    final data = viewModel.multiStoreOptimization;
    if (data == null) {
      return const Center(child: Text('No recommendation available.'));
    }

    final recommendation = data['multi_store_recommendation'];
    if (recommendation == null) {
      return const Center(child: Text('No recommendation found.'));
    }

    final stores = recommendation['stores'] as List;
    final missingItems = recommendation['missing_items'] as List;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20 * scale, 10 * scale, 20 * scale, 40 * scale),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Journey Header
              Padding(
                padding: EdgeInsets.fromLTRB(24 * scale, 24 * scale, 24 * scale, 10 * scale),
                child: Text(
                  "OPTIMIZED ROUTE",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB85A3A),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Iterate through stores
              ...stores.asMap().entries.map((entry) {
                final index = entry.key;
                final store = entry.value;
                final items = store['items'] as List;
                final distance = store['distance_from_previous_stop_km'];
                final isLast = index == stores.length - 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 15 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D1F),
                                  borderRadius: BorderRadius.circular(6 * scale),
                                ),
                                child: Text(
                                  "STOP ${index + 1}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9 * scale,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10 * scale),
                              Expanded(
                                child: Text(
                                  store['premise_name'] ?? 'Unknown Store',
                                  style: TextStyle(
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1D1F),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _launchMaps(store['premise_name'], store['address']),
                                child: Container(
                                  padding: EdgeInsets.all(7 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF6F3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.directions_rounded,
                                    color: const Color(0xFFB85A3A),
                                    size: 20 * scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),
                          Text(
                            store['address'] ?? '',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: const Color(0xFF9A9FA5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          Text(
                            index == 0
                                ? '${distance?.toStringAsFixed(2) ?? '0.00'} km from your location'
                                : '${distance?.toStringAsFixed(2) ?? '0.00'} km from previous stop',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB85A3A),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          ...items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 10 * scale),
                            child: OptimizationItemRow(item: item, scale: scale),
                          )),
                          Divider(
                            height: 25 * scale,
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Stop Subtotal",
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9A9FA5),
                                ),
                              ),
                              Text(
                                "RM ${store['subtotal']?.toStringAsFixed(2) ?? '0.00'}",
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1D1F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 15 * scale),
                          child: Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: const Color(0xFFB85A3A).withValues(alpha: 0.5),
                            size: 24 * scale,
                          ),
                        ),
                      ),
                  ],
                );
              }),

              // Missing Items Badge
              if (missingItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(24 * scale),
                  child: Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF6F3),
                      borderRadius: BorderRadius.circular(16 * scale),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18 * scale, color: const Color(0xFFB85A3A)),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            '${missingItems.length} items unavailable on this route',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB85A3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Hero Price Section (Grand Total)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFB85A3A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24 * scale)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL",
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          "Across ${stores.length} stores",
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'RM ${recommendation['product_cost']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 26 * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Detailed list of unavailable items
        if (missingItems.isNotEmpty) ...[
          SizedBox(height: 32 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8 * scale),
            child: Text(
              'UNAVAILABLE ITEMS',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF9A9FA5),
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          ...missingItems.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 12 * scale),
            child: OptimizationMissingItemRow(item: item, scale: scale),
          )),
        ],
        SizedBox(height: 40 * scale),
      ],
    );
  }

  Future<void> _launchMaps(String? name, String? address) async {
    final String query = Uri.encodeComponent(name ?? address ?? 'Store');
    final Uri geoUrl = Uri.parse("geo:0,0?q=$query");
    final Uri httpsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch maps: $e");
    }
  }
}

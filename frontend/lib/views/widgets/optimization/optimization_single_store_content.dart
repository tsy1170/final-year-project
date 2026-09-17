import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../viewmodels/optimization_view_model.dart';
import 'optimization_item_row.dart';
import 'optimization_missing_item_row.dart';

class OptimizationSingleStoreContent extends StatelessWidget {
  final OptimizationViewModel viewModel;
  final double scale;

  const OptimizationSingleStoreContent({
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

    final data = viewModel.singleStoreOptimization;
    if (data == null) {
      return const Center(child: Text('No recommendation available.'));
    }

    final recommendation = data['single-store-recommendation'];
    if (recommendation == null) {
      return const Center(child: Text('No recommendation found.'));
    }

    final store = recommendation['store'];
    final items = store['items'] as List;
    final missingItems = recommendation['missing_items'] as List;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20 * scale, 10 * scale, 20 * scale, 40 * scale),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(2, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Section
              Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            store['premise_name'] ?? 'Unknown Store',
                            style: TextStyle(
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
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
                    SizedBox(height: 6 * scale),
                    Text(
                      store['address'] ?? '',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF9A9FA5),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5F0),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14 * scale, color: const Color(0xFFB85A3A)),
                          SizedBox(width: 4 * scale),
                          Text(
                            '${store['distance_from_user_km']?.toStringAsFixed(2) ?? '0.00'} km away',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB85A3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),

              // Items Section
              Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ITEMS TO PURCHASE",
                      style: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9A9FA5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 15 * scale),
                    ...items.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 10 * scale),
                      child: OptimizationItemRow(item: item, scale: scale),
                    )),

                    // Missing Items Badge
                    if (missingItems.isNotEmpty) ...[
                      SizedBox(height: 10 * scale),
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF6F3),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18 * scale, color: const Color(0xFFB85A3A)),
                            SizedBox(width: 10 * scale),
                            Expanded(
                              child: Text(
                                '${missingItems.length} items unavailable at this store',
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
                    ],
                  ],
                ),
              ),

              // Hero Price Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFB85A3A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20 * scale)),
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
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          "Price for available items",
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'RM ${recommendation['product_cost']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.white, // A lighter shade of terracotta for contrast on dark
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Optional: List missing items below the card if they still want to see names
        if (missingItems.isNotEmpty) ...[
          SizedBox(height: 30 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5 * scale),
            child: Text(
              'UNAVAILABLE ITEMS',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF9A9FA5),
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: 15 * scale),
          ...missingItems.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 10 * scale),
            child: OptimizationMissingItemRow(item: item, scale: scale),
          )),
        ],
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/grocery_view_model.dart';
import 'optimization_item_row.dart';
import 'optimization_missing_item_row.dart';

class OptimizationMultiStoreContent extends StatelessWidget {
  final GroceryViewModel viewModel;
  final double scale;

  const OptimizationMultiStoreContent({
    super.key,
    required this.viewModel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isOptimizationLoading) {
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
      padding: EdgeInsets.all(20 * scale),
      children: [
        ...stores.asMap().entries.map((entry) {
          final index = entry.key;
          final store = entry.value;
          final items = store['items'] as List;
          final distance = store['distance_from_previous_stop_km'];
          final isFirst = index == 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFirst) SizedBox(height: 40 * scale),
              // Premise Name, Address and Location Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['premise_name'] ?? 'Unknown Store',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  IconButton(
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      final query = Uri.encodeComponent(store['premise_name'] ?? store['address'] ?? 'Store');
                      final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(
                      Icons.location_on,
                      color: const Color(0xFF1A1D1F),
                      size: 25 * scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),
              Text(
                store['address'] ?? '',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500
                ),
              ),
              SizedBox(height: 10 * scale),
              // Distance
              Text(
                isFirst 
                  ? '${distance?.toStringAsFixed(2) ?? '0.00'} km from your location'
                  : '${distance?.toStringAsFixed(2) ?? '0.00'} km from previous store',
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFED1A4B),
                  letterSpacing: 0
                ),
              ),
              SizedBox(height: 25 * scale),
              // Recommended Items for this store
              ...items.map((item) => OptimizationItemRow(item: item, scale: scale)),
              
              Divider(
                height: 40 * scale,
                color: Colors.grey.withValues(alpha: 0.3),
                thickness: 1 * scale
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal :',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                  Text(
                    'RM ${store['subtotal']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),

        Divider(
            height: 40 * scale,
            color: Colors.grey.withValues(alpha: 0.3),
            thickness: 1 * scale
        ),

        // Total Cost
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Price :',
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            Text(
              'RM ${recommendation['product_cost']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFED1A4B),
              ),
            ),
          ],
        ),

        Divider(
            height: 40 * scale,
            color: Colors.grey.withValues(alpha: 0.3),
            thickness: 1 * scale
        ),

        if (missingItems.isNotEmpty) ...[
          SizedBox(height: 10 * scale),
          Text(
            'MISSING ITEMS',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 15 * scale),
          ...missingItems.map((item) => OptimizationMissingItemRow(item: item, scale: scale)),
        ],
        
        SizedBox(height: 40 * scale),
      ],
    );
  }
}

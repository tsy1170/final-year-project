import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/store_price.dart';
import '../models/grocery_product.dart';
import '../viewmodels/grocery_view_model.dart';

class ProductMapView extends StatefulWidget {
  final GroceryProduct item;
  final List<StorePrice> stores;
  final double scale;

  const ProductMapView({
    super.key,
    required this.item,
    required this.stores,
    required this.scale,
  });

  @override
  State<ProductMapView> createState() => _ProductMapViewState();
}

class _ProductMapViewState extends State<ProductMapView> {
  late StorePrice _selectedStore;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Default to the store with the lowest price
    _selectedStore = widget.stores.reduce((curr, next) => curr.price < next.price ? curr : next);
  }

  Color _getPriceColor(String level) {
    if (level == 'low') return Colors.green;
    if (level == 'medium') return Colors.orange;
    return Colors.red;
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16 * widget.scale, color: color),
        SizedBox(width: 8 * widget.scale),
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * widget.scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1D1F),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final userPosition = context.read<GroceryViewModel>().currentPosition;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF1A1D1F),
            size: 20 * widget.scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 13 * widget.scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_selectedStore.latitude, _selectedStore.longitude),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              MarkerLayer(
                markers: [
                  // User current location marker
                  if (userPosition != null)
                    Marker(
                      point: LatLng(userPosition.latitude, userPosition.longitude),
                      width: 40 * widget.scale,
                      height: 40 * widget.scale,
                      child: Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 25 * widget.scale
                      ),
                    ),
                  // Store location markers
                  ...widget.stores.map((store) {
                    final isSelected = _selectedStore.premiseCode == store.premiseCode;
                    return Marker(
                      point: LatLng(store.latitude, store.longitude),
                      width: 50 * widget.scale,
                      height: 50 * widget.scale,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStore = store;
                          });
                          _mapController.move(LatLng(store.latitude, store.longitude), 13.0);
                        },
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? const Color(0xFFED1A4B) : const Color(0xFF1A1D1F),
                          size: (isSelected ? 40 : 30) * widget.scale,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          // Marker Legend
          Positioned(
            top: 15 * widget.scale,
            right: 15 * widget.scale,
            child: Container(
              padding: EdgeInsets.all(10 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10 * widget.scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(Icons.my_location, Colors.blueAccent, "Current Location"),
                  SizedBox(height: 6 * widget.scale),
                  _buildLegendItem(Icons.location_on, const Color(0xFF1A1D1F), "Stores"),
                ],
              ),
            ),
          ),
          // Bottom info card - Now filled to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20 * widget.scale,
                15 * widget.scale,
                20 * widget.scale,
                10 * widget.scale + bottomPadding, // Account for safe area
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFD),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(1 * widget.scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5), // Shadow above the card
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RM ${_selectedStore.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 20 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: _getPriceColor(_selectedStore.priceLevel),
                    ),
                  ),
                  SizedBox(height: 5 * widget.scale),
                  Divider(
                    color: Colors.black.withValues(alpha: 0.1),
                    thickness: 1 * widget.scale,
                  ),
                  SizedBox(height: 5 * widget.scale),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedStore.premiseName,
                          style: TextStyle(
                            fontSize: 15 * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1D1F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * widget.scale),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15 * widget.scale, color: const Color(0xFF1A1D1F)),
                      SizedBox(width: 8 * widget.scale),
                      Expanded(
                        child: Text(
                          _selectedStore.address,
                          style: TextStyle(
                            fontSize: 12 * widget.scale,
                            color: const Color(0xFF1A1D1F),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15 * widget.scale),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final String query = Uri.encodeComponent(_selectedStore.premiseName);
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not open Google Maps")),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text("Navigate to Store", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1D1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1 * widget.scale),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12 * widget.scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

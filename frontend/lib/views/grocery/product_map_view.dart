import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/store_price.dart';
import '../../models/grocery_product.dart';
import '../../viewmodels/location_view_model.dart';

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
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Custom marker icons
  BitmapDescriptor? _storeMarkerIcon;
  BitmapDescriptor? _selectedStoreMarkerIcon;

  @override
  void initState() {
    super.initState();
    // Default to the store with the lowest price
    _selectedStore = widget.stores.reduce((curr, next) => curr.price < next.price ? curr : next);
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    // Note: You can also use custom assets here if you have them
    // For now using default markers with colors
    _storeMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _selectedStoreMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    if (mounted) setState(() {});
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

  Future<void> _onStoreTapped(StorePrice store) async {
    setState(() {
      _selectedStore = store;
    });
    
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(store.latitude, store.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final userPosition = context.read<LocationViewModel>().currentPosition;

    // Create markers for Google Maps
    final Set<Marker> markers = widget.stores.map((store) {
      final isSelected = _selectedStore.premiseCode == store.premiseCode;
      return Marker(
        markerId: MarkerId(store.premiseCode.toString()),
        position: LatLng(store.latitude, store.longitude),
        icon: isSelected 
            ? (_selectedStoreMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose))
            : (_storeMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
        onTap: () => _onStoreTapped(store),
        infoWindow: InfoWindow(
          title: store.premiseName,
          snippet: "RM ${store.price.toStringAsFixed(2)}",
        ),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F5),
        elevation: 0,
        centerTitle: true,
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
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(_selectedStore.latitude, _selectedStore.longitude),
              zoom: 14.0,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          
          // Marker Legend
          Positioned(
            top: 15 * widget.scale,
            right: 15 * widget.scale,
            child: Container(
              padding: EdgeInsets.all(10 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(1 * widget.scale),
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
                  _buildLegendItem(Icons.circle_rounded, Colors.blueAccent, "My Location"),
                  SizedBox(height: 6 * widget.scale),
                  _buildLegendItem(Icons.location_on, const Color(0xFF1A1D1F), "Stores"),
                ],
              ),
            ),
          ),
          
          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20 * widget.scale,
                15 * widget.scale,
                20 * widget.scale,
                10 * widget.scale + bottomPadding,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F5),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(1 * widget.scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RM ${_selectedStore.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: _getPriceColor(_selectedStore.priceLevel),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale, vertical: 4 * widget.scale),
                        decoration: BoxDecoration(
                          color: _getPriceColor(_selectedStore.priceLevel).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20 * widget.scale),
                        ),
                        child: Text(
                          _selectedStore.priceLevel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10 * widget.scale,
                            fontWeight: FontWeight.w800,
                            color: _getPriceColor(_selectedStore.priceLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5 * widget.scale),
                  Divider(
                    color: const Color(0xFFF2EFEA),
                    thickness: 1 * widget.scale,
                  ),
                  SizedBox(height: 5 * widget.scale),
                  Text(
                    _selectedStore.premiseName,
                    style: TextStyle(
                      fontSize: 15 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 7 * widget.scale),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15 * widget.scale, color: const Color(0xFFB85A3A)),
                      SizedBox(width: 8 * widget.scale),
                      Expanded(
                        child: Text(
                          _selectedStore.address,
                          style: TextStyle(
                            fontSize: 11 * widget.scale,
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
                          borderRadius: BorderRadius.circular(12 * widget.scale),
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 200 * widget.scale),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          onPressed: () async {
             if (userPosition != null) {
               final GoogleMapController controller = await _controller.future;
               controller.animateCamera(
                 CameraUpdate.newLatLng(
                   LatLng(userPosition.latitude, userPosition.longitude),
                 ),
               );
             }
          },
          child: const Icon(Icons.my_location, color: Color(0xFF1A1D1F)),
        ),
      ),
    );
  }
}

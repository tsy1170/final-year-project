import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/grocery_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../../viewmodels/notification_view_model.dart';
import '../../models/store_price.dart';
import 'product_map_view.dart';
import '../widgets/common/animated_notification.dart';

class ProductDetailsView extends StatefulWidget {
  final int itemCode;
  final double scale;

  const ProductDetailsView({
    super.key,
    required this.itemCode,
    required this.scale,
  });

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final location = context.read<LocationViewModel>();
      context.read<GroceryViewModel>().loadProductDetails(
        itemCode: widget.itemCode,
        lat: location.currentPosition?.latitude ?? 5.356,
        lng: location.currentPosition?.longitude ?? 100.301,
      );
    });
  }

  Future<void> _showPriceAlertDialog(BuildContext context, double latitude, double longitude) async {
    final authVM = context.read<AuthViewModel>();
    final notificationVM = context.read<NotificationViewModel>();
    
    if (!authVM.isLoggedIn || authVM.accessToken == null) {
      showTopNotification(context, "Please login to set price alerts", false, widget.scale);
      return;
    }

    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * widget.scale)),
        title: Text(
          'Set Price Notification',
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
              'Enter your target price:', 
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
              if (targetPrice == null || targetPrice <= 0) {
                return;
              }
              
              Navigator.pop(context);

              try {
                final message = await notificationVM.createPriceAlert(
                  authVM.accessToken!,
                  widget.itemCode,
                  targetPrice,
                  latitude,
                  longitude,
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
            child: Text('SET ALERT', style: TextStyle(color: const Color(0xFFB85A3A), fontSize: 13 * widget.scale, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final favouriteViewModel = context.watch<FavouriteViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final details = viewModel.selectedProductDetails;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF1A1D1F),
            size: 20 * widget.scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 14 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          if (details != null)
            IconButton(
              icon: Icon(
                Icons.map_outlined,
                color: const Color(0xFFB85A3A),
                size: 24 * widget.scale,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductMapView(
                      item: details['item'],
                      stores: details['stores'],
                      scale: widget.scale,
                    ),
                  ),
                );
              },
            ),
          SizedBox(width: 10 * widget.scale),
        ],
      ),
      body: viewModel.isDetailsLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1D1F)))
          : details == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40 * widget.scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60 * widget.scale,
                      color: const Color(0xFF1A1D1F).withValues(alpha: 0.2),
                    ),
                    SizedBox(height: 20 * widget.scale),
                    Text(
                      viewModel.detailsError ?? "An unexpected error occurred",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15 * widget.scale,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    SizedBox(height: 30 * widget.scale),
                    SizedBox(
                      width: double.infinity,
                      height: 50 * widget.scale,
                      child: ElevatedButton(
                        onPressed: () {
                          final location = context.read<LocationViewModel>();
                          viewModel.loadProductDetails(
                            itemCode: widget.itemCode,
                            lat: location.currentPosition?.latitude ?? 5.356,
                            lng: location.currentPosition?.longitude ?? 100.301,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1D1F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * widget.scale),
                          ),
                        ),
                        child: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(15 * widget.scale, 15 * widget.scale, 15 * widget.scale, 40 * widget.scale),
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Hero: Horizontal split layout
                      Padding(
                        padding: EdgeInsets.all(16 * widget.scale),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side: Product Image Area with Edit icon in top-right corner
                            Stack(
                              children: [
                                Container(
                                  width: 120 * widget.scale,
                                  height: 120 * widget.scale,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16 * widget.scale),
                                    border: Border.all(
                                      color: const Color(0xFFF2EFEA),
                                      width: 1 * widget.scale
                                    )
                                  ),
                                  padding: EdgeInsets.all(12 * widget.scale),
                                  child: Image.asset(
                                    'assets/product_images/${widget.itemCode}.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/product_images/${widget.itemCode}.jpg',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 50 * widget.scale,
                                        color: const Color(0xFF9A9FA5),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6 * widget.scale,
                                  right: 6 * widget.scale,
                                  child: GestureDetector(
                                    onTap: () => _showPriceAlertDialog(
                                        context,
                                        locationViewModel.currentPosition?.latitude ?? 5.356,
                                        locationViewModel.currentPosition?.longitude ?? 100.301
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(6 * widget.scale),
                                      child: Icon(
                                        Icons.edit_notifications_outlined,
                                        color: const Color(0xFFB85A3A),
                                        size: 18 * widget.scale,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16 * widget.scale),
                            // Right side: title and unit info stacked
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4 * widget.scale),
                                  Text(
                                    details['item'].name,
                                    style: TextStyle(
                                      fontSize: 18 * widget.scale,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1D1F),
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 6 * widget.scale),
                                  Text(
                                    details['item'].unit,
                                    style: TextStyle(
                                      fontSize: 14 * widget.scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF9A9FA5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price Overview Section embedded in a tinted dashboard box (#F7F5F0)
                      Padding(
                        padding: EdgeInsets.only(left: 20 * widget.scale, right: 20 * widget.scale, bottom: 10 * widget.scale, top: 2 * widget.scale),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12 * widget.scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * widget.scale),
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF6F3),
                                  borderRadius: BorderRadius.circular(20 * widget.scale)
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 5 * widget.scale),
                                  child: Text(
                                    "PRICE OVERVIEW",
                                    style: TextStyle(
                                      fontSize: 10 * widget.scale,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFB85A3A),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16 * widget.scale),
                              Row(
                                children: [
                                  _buildMetricColumn(
                                    "Lowest",
                                    details['price_summary']['lowest_price'],
                                    Colors.green
                                  ),
                                  _buildMetricDivider(),
                                  _buildMetricColumn(
                                    "Average",
                                    details['price_summary']['average_price'],
                                    Colors.orange
                                  ),
                                  _buildMetricDivider(),
                                  _buildMetricColumn(
                                    "Highest",
                                    details['price_summary']['highest_price'],
                                    Colors.red
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 10 * widget.scale),

                      // Delicate warm divider line between Product Hero and Price Overview
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: const Color(0xFFF2EFEA),
                      ),

                      // Store Listings Section
                      () {
                        final sections = <Widget>[];
                        final lowSection = _buildPriceSection("Low Prices", details['stores'], "low");
                        final medSection = _buildPriceSection("Medium Prices", details['stores'], "medium");
                        final highSection = _buildPriceSection("High Prices", details['stores'], "high");
                        
                        if (details['stores'].where((s) => s.priceLevel == 'low').isNotEmpty) {
                          sections.add(lowSection);
                        }
                        if (details['stores'].where((s) => s.priceLevel == 'medium').isNotEmpty) {
                          if (sections.isNotEmpty) {
                            sections.add(Divider(height: 1, thickness: 1, color: const Color(0xFFF2EFEA)));
                          }
                          sections.add(medSection);
                        }
                        if (details['stores'].where((s) => s.priceLevel == 'high').isNotEmpty) {
                          if (sections.isNotEmpty) {
                            sections.add(Divider(height: 1, thickness: 1, color: const Color(0xFFF2EFEA)));
                          }
                          sections.add(highSection);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sections,
                        );
                      }(),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: details == null
          ? null
          : Container(
              height: 60 * widget.scale + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final itemCode = details['item'].itemCode;
                    if (authViewModel.isLoggedIn) {
                      final isAdding = !favouriteViewModel.favourites.contains(itemCode);
                      favouriteViewModel.toggleFavourite(
                        itemCode, 
                        authViewModel.accessToken!,
                        lat: locationViewModel.currentPosition?.latitude,
                        lng: locationViewModel.currentPosition?.longitude,
                      );
                      if (isAdding) {
                        showTopNotification(context, "Successfully Added to Favourites", true, widget.scale);
                      }
                    } else {
                      showTopNotification(context, "Please login to add favourites", false, widget.scale);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          favouriteViewModel.favourites.contains(details['item'].itemCode)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 24 * widget.scale,
                          color: favouriteViewModel.favourites.contains(details['item'].itemCode)
                              ? const Color(0xFFB85A3A)
                              : const Color(0xFF1A1D1F),
                        ),
                        SizedBox(width: 10 * widget.scale),
                        Text(
                          favouriteViewModel.favourites.contains(details['item'].itemCode)
                              ? "IN FAVOURITES"
                              : "ADD TO FAVOURITES",
                          style: TextStyle(
                            color: const Color(0xFF1A1D1F),
                            fontSize: 14 * widget.scale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricColumn(String label, dynamic price, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6 * widget.scale,
                height: 6 * widget.scale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6 * widget.scale),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9A9FA5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * widget.scale),
          Text(
            "RM ${(price as num).toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 15 * widget.scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5 * widget.scale),
      child: Container(
        width: 1,
        height: 30 * widget.scale,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildPriceSection(String title, List<StorePrice> allStores, String level) {
    final stores = allStores.where((s) => s.priceLevel == level).toList();
    if (stores.isEmpty) return const SizedBox.shrink();

    Color levelColor = level == 'low' ? Colors.green : (level == 'medium' ? Colors.orange : Colors.red);
    String badgeText = "$title • ${stores.length} store${stores.length > 1 ? 's' : ''} found";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Header
        Padding(
          padding: EdgeInsets.fromLTRB(20 * widget.scale, 15 * widget.scale, 20 * widget.scale, 10 * widget.scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8 * widget.scale,
                height: 8 * widget.scale,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8 * widget.scale),
              Text(
                badgeText.toUpperCase(),
                style: TextStyle(
                  fontSize: 11 * widget.scale,
                  fontWeight: FontWeight.w800,
                  color: levelColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: stores.length,
          separatorBuilder: (context, index) => SizedBox(
            height: 0,
          ),
          itemBuilder: (context, index) => _buildStoreTile(
            stores[index],
            levelColor,
            isFirst: false,
            isLast: false
          ),
        ),
        SizedBox(height: 10 * widget.scale),
      ],
    );
  }

  Widget _buildStoreTile(StorePrice store, Color levelColor, {required bool isFirst, required bool isLast}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final String query = Uri.encodeComponent(store.premiseName);
          final Uri geoUrl = Uri.parse("geo:0,0?q=$query");
          final Uri httpsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
          try {
            if (await canLaunchUrl(geoUrl)) {
              await launchUrl(geoUrl);
            } else {
              await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open maps")));
          }
        },
        child: Padding(
          padding: EdgeInsets.all(20 * widget.scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      store.premiseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * widget.scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D1F)
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * widget.scale),
                  Text(
                    "RM ${store.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16 * widget.scale, 
                      fontWeight: FontWeight.w700,
                      color: levelColor
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * widget.scale),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14 * widget.scale, color: const Color(0xFF9A9FA5)),
                  SizedBox(width: 4 * widget.scale),
                  Text(
                    "${store.distance.toStringAsFixed(2)} km away", 
                    style: TextStyle(
                      fontSize: 12 * widget.scale, 
                      fontWeight: FontWeight.w500, 
                      color: const Color(0xFF9A9FA5)
                    )
                  ),
                  const Spacer(),
                  Text(
                    store.priceDate, 
                    style: TextStyle(
                      fontSize: 11 * widget.scale, 
                      color: const Color(0xFF9A9FA5)
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/grocery_view_model.dart';
import '../models/store_price.dart';
import 'product_map_view.dart';
import 'widgets/animated_notification.dart';

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
    Future.microtask(
      () =>
          context.read<GroceryViewModel>().loadProductDetails(widget.itemCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final details = viewModel.selectedProductDetails;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFD),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF1A1D1F),
            size: 20 * widget.scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          details?['item']?.name ?? 'Loading...',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 13 * widget.scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.map_outlined,
              color: const Color(0xFF1A1D1F),
              size: 24 * widget.scale,
            ),
            onPressed: () {
              if (details != null) {
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
              }
            },
          ),
          SizedBox(width: 10 * widget.scale),
        ],
      ),
      body: viewModel.isDetailsLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
          ? const Center(child: Text("Failed to load details"))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    height: 300 * widget.scale,
                    color: const Color(0xFFF4F4F4),
                    child: details['item'].imageUrl != null
                        ? Image.network(
                            details['item'].imageUrl,
                            fit: BoxFit.fill,
                          )
                        : Icon(
                            Icons.image,
                            size: 100 * widget.scale,
                            color: Colors.grey,
                          ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20 * widget.scale,
                          15 * widget.scale,
                          20 * widget.scale,
                          10 * widget.scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    details['item'].name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20 * widget.scale,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1D1F),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact, // Removes the internal padding
                                  alignment: Alignment.center,
                                  icon: Icon(
                                    Icons.edit_notifications_outlined,
                                    color: const Color(0xFF1A1D1F),
                                    size: 26 * widget.scale,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            Text(
                              details['item'].unit,
                              style: TextStyle(
                                fontSize: 16 * widget.scale,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30 * widget.scale),
                      // Price Summary Row
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 45 * widget.scale,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              color: const Color(0xFF1A1D1F),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 5 * widget.scale,
                                ),
                                child: Center(
                                  child: Text(
                                    "Overview",
                                    style: TextStyle(
                                      fontSize: 18 * widget.scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFFFDFD),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10 * widget.scale),
                            _buildSummaryItem(
                              "Lowest",
                              details['price_summary']['lowest_price'],
                              Colors.green,
                            ),
                            _buildSummaryItem(
                              "Average",
                              details['price_summary']['average_price'],
                              Colors.orange,
                            ),
                            _buildSummaryItem(
                              "Highest",
                              details['price_summary']['highest_price'],
                              Colors.red,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30 * widget.scale),
                      // Price Sections
                      _buildPriceSection(
                        "Low Prices",
                        details['stores'],
                        "low",
                        isFirst: true,
                      ),
                      _buildPriceSection(
                        "Medium Prices",
                        details['stores'],
                        "medium",
                      ),
                      _buildPriceSection(
                        "High Prices",
                        details['stores'],
                        "high",
                      ),
                      SizedBox(height: 30 * widget.scale),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: details == null
          ? null
          : Container(
              height: 60 * widget.scale + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final isAdding = viewModel.favourites.contains(
                      details['item'].name,
                    );
                    viewModel.toggleFavourite(details['item'].name);
                    if (!isAdding) {
                      showTopNotification(
                        context,
                        "Successfully Added to Favourites",
                        true,
                        widget.scale,
                      );
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
                          viewModel.favourites.contains(details['item'].name)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 24 * widget.scale,
                          color:
                              viewModel.favourites.contains(
                                details['item'].name,
                              )
                              ? const Color(0xFFED1A4B)
                              : const Color(0xFF1A1D1F),
                        ),
                        SizedBox(width: 8 * widget.scale),
                        Text(
                          viewModel.favourites.contains(details['item'].name)
                              ? "In Favourites"
                              : "Add to Favourites",
                          style: TextStyle(
                            color: const Color(0xFF1A1D1F),
                            fontSize: 16 * widget.scale,
                            fontWeight: FontWeight.w600,
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

  Widget _buildSummaryItem(String label, dynamic price, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * widget.scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  7 * widget.scale,
                  0,
                  8 * widget.scale,
                  0,
                ),
                child: Container(
                  width: 4 * widget.scale,
                  height: 15 * widget.scale,
                  decoration: BoxDecoration(color: color),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14 * widget.scale,
                  color: const Color(0xFF1A1D1F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 7 * widget.scale, 0),
            child: Text(
              "RM ${(price as num).toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16 * widget.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    String title,
    List<StorePrice> allStores,
    String level, {
    bool isFirst = false,
  }) {
    final stores = allStores.where((s) => s.priceLevel == level).toList();
    if (stores.isEmpty) return const SizedBox.shrink();

    Color levelColor;
    if (level == 'low') {
      levelColor = Colors.green;
    } else if (level == 'medium') {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.red;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1 * widget.scale,
              ),
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1 * widget.scale,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 20 * widget.scale,
            vertical: 25 * widget.scale,
          ),
          child: Row(
            children: [
              Container(
                width: 4 * widget.scale,
                height: 18 * widget.scale,
                decoration: BoxDecoration(color: levelColor),
              ),
              SizedBox(width: 8 * widget.scale),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
            ],
          ),
        ),
        // Indented list of stores
        Column(
          children: stores
              .map((store) => _buildStoreTile(store, levelColor))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStoreTile(StorePrice store, Color levelColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final String query = Uri.encodeComponent(store.premiseName);
          final Uri geoUrl = Uri.parse("geo:0,0?q=$query");
          final Uri httpsUrl = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=$query",
          );

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
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            40 * widget.scale,
            20 * widget.scale,
            20 * widget.scale,
            20 * widget.scale,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.premiseName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14 * widget.scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D1F),
                            ),
                          ),
                        ),

                        Icon(
                          Icons.location_on,
                          size: 23 * widget.scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ],
                    ),

                    SizedBox(height: 2 * widget.scale),
                    Text(
                      "${store.distance.toStringAsFixed(2)} km away",
                      style: TextStyle(
                        fontSize: 12 * widget.scale,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    SizedBox(height: 15 * widget.scale),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Updated on: ${store.priceDate}",
                          style: TextStyle(
                            fontSize: 12 * widget.scale,
                            color: Colors.grey,
                          ),
                        ),

                        Text(
                          "RM ${store.price.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14 * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

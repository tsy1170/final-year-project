import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../../viewmodels/compare_prices_view_model.dart';
import '../../models/store_price.dart';

class ComparePricesView extends StatefulWidget {
  final double scale;

  const ComparePricesView({super.key, required this.scale});

  @override
  State<ComparePricesView> createState() => _ComparePricesViewState();
}

class _ComparePricesViewState extends State<ComparePricesView> {
  late PageController _itemPageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _itemPageController = PageController(
      viewportFraction: 0.25,
      initialPage: 0,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationViewModel>().currentPosition;
      final viewModel = context.read<ComparePricesViewModel>();
      final favViewModel = context.read<FavouriteViewModel>();
      
      if (loc != null) {
        viewModel.loadNearbyPremises(loc.latitude, loc.longitude);
      }
      
      // Auto-select first favourite if none selected
      if (favViewModel.favouriteProducts.isNotEmpty && viewModel.selectedProduct == null) {
        viewModel.setSelectedProduct(
          favViewModel.favouriteProducts[0],
          loc?.latitude,
          loc?.longitude,
        );
      }
    });
  }

  @override
  void dispose() {
    _itemPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favViewModel = context.watch<FavouriteViewModel>();
    final viewModel = context.watch<ComparePricesViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final scale = widget.scale;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF3),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'COMPARE PRICES',
          style: TextStyle(
            color: const Color(0xFF325E6A),
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20 * scale),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Select Product Section (Carousel)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15 * scale, horizontal: 20 * scale),
            child: Text(
              'Select an item from Favourites',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
          SizedBox(
            height: 160 * scale,
            child: PageView.builder(
              controller: _itemPageController,
              itemCount: favViewModel.favouriteProducts.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                final loc = locationViewModel.currentPosition;
                viewModel.setSelectedProduct(
                  favViewModel.favouriteProducts[index],
                  loc?.latitude,
                  loc?.longitude,
                );
              },
              itemBuilder: (context, index) {
                final product = favViewModel.favouriteProducts[index];
                return AnimatedBuilder(
                  animation: _itemPageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_itemPageController.position.haveDimensions) {
                      value = _itemPageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                    } else {
                      value = index == _currentPage ? 1.0 : 0.7;
                    }
                    return Center(
                      child: Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      _itemPageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      width: 140 * scale,
                      margin: EdgeInsets.symmetric(vertical: 10 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15 * scale),
                        border: Border.all(
                          color: const Color(0xFF325E6A).withOpacity(0.3),
                          width: 1 * scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(1, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (product.imageUrl != null)
                            Image.network(
                              product.imageUrl!,
                              height: 70 * scale,
                              width: 100 * scale,
                              errorBuilder: (c, e, s) => const Icon(Icons.image),
                            ),
                          SizedBox(height: 6 * scale),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1D1F),
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Selected Stores Section
          Padding(
            padding: EdgeInsets.fromLTRB(20 * scale, 24 * scale, 15 * scale, 8 * scale),
            child: SizedBox(
              height: 40 * scale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Stores (${viewModel.selectedPremises.length}/4)',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                  if (viewModel.selectedPremises.length < 4)
                    TextButton.icon(
                      onPressed: () => _showStorePicker(context),
                      icon: Icon(Icons.add, size: 18 * scale),
                      label: Text('Add Store', style: TextStyle(fontSize: 12 * scale)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF325E6A)),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: viewModel.selectedPremises.isEmpty
                ? Center(
                    child: Text(
                      'Add up to 4 stores to compare prices',
                      style: TextStyle(fontSize: 13 * scale, color: const Color(0xFF9A9FA5)),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    itemCount: viewModel.selectedPremises.length,
                    itemBuilder: (context, index) {
                      final premise = viewModel.selectedPremises[index];
                      final int premiseCode = premise['premise_code'];

                      StorePrice? priceInfo;
                      try {
                        priceInfo = viewModel.comparisonResults.firstWhere((s) => s.premiseCode == premiseCode);
                      } catch (_) {}

                      return Container(
                        margin: EdgeInsets.only(bottom: 12 * scale),
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(1, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    premise['premise_name'],
                                    style: TextStyle(
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1D1F),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final loc = locationViewModel.currentPosition;
                                    viewModel.removePremise(premiseCode, loc?.latitude, loc?.longitude);
                                  },
                                  child: Icon(Icons.close, size: 18 * scale, color: const Color(0xFFED1A4B)),
                                ),
                              ],
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              premise['address'] ?? 'No address',
                              style: TextStyle(
                                fontSize: 11 * scale,
                                color: const Color(0xFF9A9FA5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 17 * scale),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: viewModel.isFetchingPrices
                                  ? SizedBox(
                                      width: 15 * scale,
                                      height: 15 * scale,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF325E6A),
                                      ),
                                    )
                                  : Text(
                                      priceInfo != null 
                                          ? 'Price :  RM${priceInfo.price.toStringAsFixed(2)}'
                                          : 'Price :  N/A',
                                      style: TextStyle(
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w700,
                                        color: priceInfo != null ? const Color(0xFF325E6A) : Colors.grey,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showStorePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * widget.scale)),
      ),
      builder: (context) {
        return Consumer<ComparePricesViewModel>(
          builder: (context, viewModel, child) {
            final availablePremises = viewModel.nearbyPremises.where((p) {
              return !viewModel.selectedPremises.any((selected) => selected['premise_code'] == p['premise_code']);
            }).toList();

            return Container(
              padding: EdgeInsets.all(20 * widget.scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15 * widget.scale),
                  Center(
                    child: Text(
                      'Select Nearby Premise',
                      style: TextStyle(
                        fontSize: 16 * widget.scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 15 * widget.scale),
                  if (viewModel.isLoadingPremises)
                    const Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF325E6A)))
                    )
                  else if (availablePremises.isEmpty)
                    const Center(child: Text('No more stores available nearby'))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: availablePremises.length,
                        separatorBuilder: (c, i) => Divider(color: Colors.grey.withOpacity(0.1)),
                        itemBuilder: (context, index) {
                          final premise = availablePremises[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              premise['premise_name'],
                              style: TextStyle(fontSize: 14 * widget.scale, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              premise['address'] ?? '',
                              style: TextStyle(fontSize: 12 * widget.scale, color: const Color(0xFF9A9FA5)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(Icons.add_circle_outline, color: const Color(0xFF325E6A), size: 24 * widget.scale),
                            onTap: () {
                              final loc = context.read<LocationViewModel>().currentPosition;
                              viewModel.addPremise(premise, loc?.latitude, loc?.longitude);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

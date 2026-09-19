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
  late ScrollController _itemScrollController;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationViewModel>().currentPosition;
      final viewModel = context.read<ComparePricesViewModel>();
      final favViewModel = context.read<FavouriteViewModel>();

      if (loc != null) {
        viewModel.loadNearbyPremises(loc.latitude, loc.longitude);
      }

      if (favViewModel.favouriteProducts.isNotEmpty &&
          viewModel.selectedProduct == null) {
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
    _itemScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favViewModel = context.watch<FavouriteViewModel>();
    final viewModel = context.watch<ComparePricesViewModel>();
    final locationViewModel = context.watch<LocationViewModel>();
    final scale = widget.scale;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'COMPARE PRICES',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 16 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20 * scale, color: const Color(0xFF1A1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Item Selection Carousel
            Padding(
              padding: EdgeInsets.fromLTRB(20 * scale, 15 * scale, 20 * scale, 12 * scale),
              child: Text(
                'Select Item to Compare',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
            ),
            
            SizedBox(
              height: 130 * scale,
              child: ListView.builder(
                controller: _itemScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 15 * scale),
                itemCount: favViewModel.favouriteProducts.length,
                itemBuilder: (context, index) {
                  final product = favViewModel.favouriteProducts[index];
                  final isSelected = viewModel.selectedProduct?.itemCode == product.itemCode;

                  return GestureDetector(
                    onTap: () {
                      final loc = locationViewModel.currentPosition;
                      viewModel.setSelectedProduct(
                        product,
                        loc?.latitude,
                        loc?.longitude,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 110 * scale,
                      margin: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 10 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: isSelected
                          ? Border.all(color: const Color(0xFFB85A3A), width: 2 * scale)
                          : Border.all(color: Colors.transparent, width: 2 * scale),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFFB85A3A).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          )
                        ] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (product.imageUrl != null)
                              Image.network(
                                product.imageUrl!,
                                height: 50 * scale,
                                width: 50 * scale,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Icon(Icons.image, size: 30 * scale, color: Colors.grey),
                              ),
                            SizedBox(height: 6 * scale),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: const Color(0xFF1A1D1F),
                                ),
                                maxLines: 1,
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

            // Section 2: Selected Stores Group (Master Card)
            Padding(
              padding: EdgeInsets.fromLTRB(20 * scale, 30 * scale, 20 * scale, 15 * scale),
              child: SizedBox(
                height: 30 * scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Stores (${viewModel.selectedPremises.length}/4)',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                    if (viewModel.selectedPremises.length < 4)
                      GestureDetector(
                        onTap: () => _showStorePicker(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9ECE6),
                            borderRadius: BorderRadius.circular(20 * scale),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 16 * scale, color: const Color(0xFFB85A3A)),
                              SizedBox(width: 4 * scale),
                              Text(
                                'Add Store',
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB85A3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (viewModel.selectedPremises.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(40 * scale),
                        child: Center(
                          child: Text(
                            'Add stores to compare prices',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              color: const Color(0xFF9A9FA5),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: viewModel.selectedPremises.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: const Color(0xFFF2EFEA),
                          indent: 20 * scale,
                          endIndent: 20 * widget.scale,
                        ),
                        itemBuilder: (context, index) {
                          final premise = viewModel.selectedPremises[index];
                          final int premiseCode = premise['premise_code'];

                          StorePrice? priceInfo;
                          try {
                            priceInfo = viewModel.comparisonResults.firstWhere(
                              (s) => s.premiseCode == premiseCode,
                            );
                          } catch (_) {}

                          return Padding(
                            padding: EdgeInsets.all(16 * scale),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9ECE6),
                                    borderRadius: BorderRadius.circular(10 * scale),
                                  ),
                                  child: Icon(Icons.storefront_rounded, color: const Color(0xFFB85A3A), size: 20 * scale),
                                ),
                                SizedBox(width: 15 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        premise['premise_name'],
                                        style: TextStyle(
                                          fontSize: 13 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1D1F),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4 * scale),
                                      Text(
                                        "${premise['district'] ?? ''} • ${priceInfo?.distance.toStringAsFixed(2) ?? '0.00'} km",
                                        style: TextStyle(
                                          fontSize: 11 * scale,
                                          color: const Color(0xFF9A9FA5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 5 * scale),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (viewModel.isFetchingPrices)
                                      SizedBox(
                                        width: 14 * scale,
                                        height: 14 * scale,
                                        child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB85A3A)),
                                      )
                                    else
                                      Text(
                                        priceInfo != null ? 'RM ${priceInfo.price.toStringAsFixed(2)}' : 'N/A',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w800,
                                          color: priceInfo != null ? const Color(0xFFB85A3A) : Colors.grey,
                                        ),
                                      ),
                                    SizedBox(height: 8 * scale),
                                    GestureDetector(
                                      onTap: () {
                                        final loc = locationViewModel.currentPosition;
                                        viewModel.removePremise(premiseCode, loc?.latitude, loc?.longitude);
                                      },
                                      child: Icon(Icons.close_rounded, size: 15 * scale, color: const Color(0xFF9A9FA5)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    // Optional Slot Indicator
                    if (viewModel.selectedPremises.length > 0 && viewModel.selectedPremises.length < 4)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 16 * scale),
                        child: GestureDetector(
                          onTap: () => _showStorePicker(context),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 15 * scale),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF8F5),
                              borderRadius: BorderRadius.circular(12 * scale),
                              border: Border.all(
                                color: const Color(0xFFE2D4C9),
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Select Next Store (Optional)",
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  color: const Color(0xFF9A9FA5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40 * scale),
          ],
        ),
      ),
    );
  }

  void _showStorePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20 * widget.scale),
        ),
      ),
      builder: (context) {
        return Consumer<ComparePricesViewModel>(
          builder: (context, viewModel, child) {
            final availablePremises = viewModel.nearbyPremises.where((p) {
              return !viewModel.selectedPremises.any(
                (selected) => selected['premise_code'] == p['premise_code'],
              );
            }).toList();

            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                              width: 1 * widget.scale
                          )
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15 * widget.scale)),
                      color: const Color(0xFF1A1D1F),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              150 * widget.scale,
                              11 * widget.scale,
                              150 * widget.scale,
                              0,
                            ),
                            child: Container(
                              height: 4 * widget.scale,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFFDFD),
                                  borderRadius: BorderRadius.circular(15 * widget.scale)
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 25 * widget.scale,
                              horizontal: 20 * widget.scale
                          ),
                          child: Text(
                            "NEARBY PREMISES",
                            style: TextStyle(
                              fontSize: 15 * widget.scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFFDFD),
                            ),
                          ),

                        ),
                      ],
                    ),
                  ),
                  if (viewModel.isLoadingPremises)
                    const Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB85A3A),
                        ),
                      ),
                    )
                  else if (availablePremises.isEmpty)
                    const Center(child: Text('No more stores available nearby'))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: availablePremises.length,
                        itemBuilder: (context, index) {
                          final premise = availablePremises[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12 * widget.scale,
                              horizontal: 20 * widget.scale,
                            ),
                            title: Text(
                              premise['premise_name'],
                              style: TextStyle(
                                fontSize: 14 * widget.scale,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1D1F),
                              ),
                            ),
                            subtitle: Text(
                              premise['address'] ?? '',
                              style: TextStyle(
                                fontSize: 12 * widget.scale,
                                color: const Color(0xFF9A9FA5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              Icons.add_circle_outline_rounded,
                              color: const Color(0xFFB85A3A),
                              size: 24 * widget.scale,
                            ),
                            onTap: () {
                              final loc = context
                                  .read<LocationViewModel>()
                                  .currentPosition;
                              viewModel.addPremise(
                                premise,
                                loc?.latitude,
                                loc?.longitude,
                              );
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

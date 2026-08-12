import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/grocery_view_model.dart';
import '../viewmodels/auth_view_model.dart';

class OptimizationView extends StatefulWidget {
  final double scale;

  const OptimizationView({super.key, required this.scale});

  @override
  State<OptimizationView> createState() => _OptimizationViewState();
}

class _OptimizationViewState extends State<OptimizationView> {
  bool _isSingleStore = true;

  @override
  void initState() {
    super.initState();
    // Fetch optimization data when the view is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final groceryViewModel = context.read<GroceryViewModel>();
      if (authViewModel.isLoggedIn && authViewModel.accessToken != null) {
        groceryViewModel.fetchSingleStoreOptimization(authViewModel.accessToken!);
        groceryViewModel.fetchMultiStoreOptimization(authViewModel.accessToken!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              width: double.infinity,
              height: 60 * widget.scale,
              padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFD),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1 * widget.scale,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22 * widget.scale,
                        color: const Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'COMPARE',
                      style: TextStyle(
                        color: const Color(0xFF1A1D1F),
                        fontSize: 18 * widget.scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sub-header Bar with Sliding Indicator
            Container(
              width: double.infinity,
              height: 50 * widget.scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFD),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1 * widget.scale,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Animated Sliding Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    bottom: 0,
                    left: _isSingleStore ? 0 : screenWidth / 2,
                    child: Container(
                      width: screenWidth / 2,
                      height: 3 * widget.scale,
                      color: const Color(0xFFED1A4B),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _isSingleStore = true),
                          style: TextButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                            overlayColor: Colors.grey,
                            minimumSize: const Size(double.infinity, double.infinity),
                          ),
                          child: Text(
                            'SINGLE-STORE',
                            style: TextStyle(
                              color: _isSingleStore
                                  ? const Color(0xFFED1A4B)
                                  : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                              fontSize: 13 * widget.scale,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _isSingleStore = false),
                          style: TextButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                            overlayColor: Colors.grey,
                            minimumSize: const Size(double.infinity, double.infinity),
                          ),
                          child: Text(
                            'MULTI-STORE',
                            style: TextStyle(
                              color: !_isSingleStore
                                  ? const Color(0xFFED1A4B)
                                  : const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                              fontSize: 13 * widget.scale,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: _isSingleStore
                  ? _buildSingleStoreContent(viewModel)
                  : _buildMultiStoreContent(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleStoreContent(GroceryViewModel viewModel) {
    if (viewModel.isOptimizationLoading) {
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
      padding: EdgeInsets.all(20 * widget.scale),
      children: [
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
                      fontSize: 18 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10 * widget.scale),
            IconButton(
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                shape: CircleBorder(),
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
                size: 25 * widget.scale,
              ),
            ),
          ],
        ),
        SizedBox(height: 5 * widget.scale),
        Text(
          store['address'] ?? '',
          style: TextStyle(
            fontSize: 12 * widget.scale,
            color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
            fontWeight: FontWeight.w500
          ),
        ),
        SizedBox(height: 10 * widget.scale),
        // Distance
        Text(
          '${store['distance_from_user_km']?.toStringAsFixed(2) ?? '0.00'} km from your location',
          style: TextStyle(
            fontSize: 13 * widget.scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFED1A4B),
            letterSpacing: 0
          ),
        ),
        SizedBox(height: 25 * widget.scale),
        // Recommended Items
        ...items.map((item) => _buildItemRow(item)),

        Divider(
          height: 40 * widget.scale, 
          color: Colors.grey.withValues(alpha: 0.3),
          thickness: 1 * widget.scale
        ),

        // Total Cost
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Price :',
              style: TextStyle(
                fontSize: 15 * widget.scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            Text(
              'RM ${recommendation['product_cost']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 17 * widget.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFED1A4B),
              ),
            ),
          ],
        ),

        Divider(
          height: 40 * widget.scale, 
          color: Colors.grey.withValues(alpha: 0.3),
          thickness: 1 * widget.scale
        ),

        // Missing Items
        if (missingItems.isNotEmpty) ...[
          SizedBox(height: 10 * widget.scale),
          Text(
            'MISSING ITEMS',
            style: TextStyle(
              fontSize: 14 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 15 * widget.scale),
          ...missingItems.map((item) => _buildMissingItemRow(item)).toList(),
        ],
        
        SizedBox(height: 40 * widget.scale),
      ],
    );
  }

  Widget _buildMultiStoreContent(GroceryViewModel viewModel) {
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
      padding: EdgeInsets.all(20 * widget.scale),
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
              if (!isFirst) SizedBox(height: 40 * widget.scale),
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
                            fontSize: 18 * widget.scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * widget.scale),
                  IconButton(
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      shape: CircleBorder(),
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
                      size: 25 * widget.scale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * widget.scale),
              Text(
                store['address'] ?? '',
                style: TextStyle(
                  fontSize: 12 * widget.scale,
                  color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500
                ),
              ),
              SizedBox(height: 10 * widget.scale),
              // Distance
              Text(
                isFirst 
                  ? '${distance?.toStringAsFixed(2) ?? '0.00'} km from your location'
                  : '${distance?.toStringAsFixed(2) ?? '0.00'} km from previous store',
                style: TextStyle(
                  fontSize: 13 * widget.scale,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFED1A4B),
                  letterSpacing: 0
                ),
              ),
              SizedBox(height: 25 * widget.scale),
              // Recommended Items for this store
              ...items.map((item) => _buildItemRow(item)),
              
              Divider(
                height: 40 * widget.scale,
                color: Colors.grey.withValues(alpha: 0.3),
                thickness: 1 * widget.scale
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal :',
                    style: TextStyle(
                      fontSize: 14 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F),
                    ),
                  ),
                  Text(
                    'RM ${store['subtotal']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 15 * widget.scale,
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
            height: 40 * widget.scale,
            color: Colors.grey.withValues(alpha: 0.3),
            thickness: 1 * widget.scale
        ),

        // Total Cost
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Price :',
              style: TextStyle(
                fontSize: 15 * widget.scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
            Text(
              'RM ${recommendation['product_cost']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 17 * widget.scale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFED1A4B),
              ),
            ),
          ],
        ),

        Divider(
            height: 40 * widget.scale,
            color: Colors.grey.withValues(alpha: 0.3),
            thickness: 1 * widget.scale
        ),

        if (missingItems.isNotEmpty) ...[
          SizedBox(height: 10 * widget.scale),
          Text(
            'MISSING ITEMS',
            style: TextStyle(
              fontSize: 14 * widget.scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 15 * widget.scale),
          ...missingItems.map((item) => _buildMissingItemRow(item)),
        ],
        
        SizedBox(height: 40 * widget.scale),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 15 * widget.scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align top
        children: [
          // Image
          Container(
            width: 55 * widget.scale,
            height: 55 * widget.scale,
            padding: EdgeInsets.all(5 * widget.scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8 * widget.scale),
            ),
            child: item['image_url'] != null
                ? Image.network(
                    item['image_url'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported_outlined, size: 20 * widget.scale),
                  )
                : Icon(Icons.image_outlined, color: Colors.grey, size: 20 * widget.scale),
          ),
          SizedBox(width: 15 * widget.scale),
          // Name and Unit
          Expanded(

              // padding: EdgeInsets.only(top: 5 * widget.scale), // Align with image top
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['unit'] ?? '',
                    style: TextStyle(
                      fontSize: 11 * widget.scale,
                      color: const Color(0xFF9A9FA5),
                    ),
                  ),
                ],
              ),

          ),
          SizedBox(width: 10 * widget.scale),
          // Price
          Padding(
            padding: EdgeInsets.only(top: 5 * widget.scale), // Align with image top
            child: Text(
              'RM ${item['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 14 * widget.scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItemRow(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * widget.scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: 45 * widget.scale,
            height: 45 * widget.scale,
            padding: EdgeInsets.all(5 * widget.scale),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8 * widget.scale),
            ),
            child: item['image_url'] != null
                ? Opacity(
                    opacity: 0.5,
                    child: Image.network(item['image_url'], fit: BoxFit.contain),
                  )
                : Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey.withValues(alpha: 0.5), size: 18 * widget.scale),
          ),
          SizedBox(width: 15 * widget.scale),
          // Name and Unit
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5 * widget.scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1F).withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    item['unit'] ?? '',
                    style: TextStyle(
                      fontSize: 10 * widget.scale,
                      color: const Color(0xFF9A9FA5),
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

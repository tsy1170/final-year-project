import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grocery_product.dart';
import '../../services/grocery_service.dart';
import '../../viewmodels/navigation_view_model.dart';
import 'product_details_view.dart';

class SearchPageView extends StatefulWidget {
  final double scale;
  final bool isTab;

  const SearchPageView({
    super.key, 
    required this.scale, 
    this.isTab = false
  });

  @override
  State<SearchPageView> createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  final TextEditingController _searchController = TextEditingController();
  final GroceryService _groceryService = GroceryService();
  final _focusNode = FocusNode();
  List<GroceryProduct> _searchResults = [];
  bool _showClearButton = false;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    
    setState(() {
      _showClearButton = query.isNotEmpty;
      if (query.isNotEmpty) {
        _isLoading = true; // Show loading indicator immediately
      } else {
        _isLoading = false;
        _searchResults = [];
      }
    });

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _groceryService.searchProducts(query);
      if (mounted && _searchController.text == query) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTab) {
      final navViewModel = context.watch<NavigationViewModel>();
      final bool isSelectedTab = navViewModel.selectedIndex == 2;

      // Unfocus if we switch away from the search tab
      if (!isSelectedTab && _focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.unfocus();
        });
      }

      // Auto-focus when the search tab becomes active
      if (isSelectedTab && !_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10 * widget.scale,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFF2EFEA),
                      width: 1.5 * widget.scale,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          // If accessed via bottom navigation, return to the first tab (Grocery)
                          context.read<NavigationViewModel>().setSelectedIndex(0);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Padding(
                        padding: EdgeInsets.all(12 * widget.scale),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20 * widget.scale,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 40 * widget.scale,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1 * widget.scale),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          autofocus: !widget.isTab, // Only autofocus if NOT in a tab
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 14 * widget.scale,
                            color: const Color(0xFF1A1D1F),
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search Items',
                            hintStyle: TextStyle(
                              fontSize: 14 * widget.scale,
                              color: const Color(0xFF9A9FA5),
                              letterSpacing: -0.5,
                            ),
                            suffixIcon: _showClearButton
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 20 * widget.scale,
                                        color: const Color(0xFFB85A3A),
                                      ),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10 * widget.scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * widget.scale),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 25 * widget.scale,
                        height: 25 * widget.scale,
                        child: const CircularProgressIndicator(
                          color: Color(0xFF1A1D1F),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(width: 15 * widget.scale),
                      Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 13 * widget.scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  padding: EdgeInsets.fromLTRB(
                    10 * widget.scale,
                    0,
                    10 * widget.scale,
                    80 * widget.scale
                  ),
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8 * widget.scale),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12 * widget.scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              spreadRadius: -6,
                              blurRadius: 10,
                              offset: const Offset(2, 6),
                            )
                          ]
                        ),
                        child: Material(
                          color: const Color(0xFFFFFDFD),
                          borderRadius: BorderRadius.circular(12 * widget.scale),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12 * widget.scale),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsView(
                                    itemCode: product.itemCode,
                                    scale: widget.scale,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(8 * widget.scale),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    clipBehavior: Clip.antiAlias,
                                    width: 70 * widget.scale,
                                    height: 70 * widget.scale,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12 * widget.scale),
                                    ),
                                    child: product.imageUrl != null
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.fill,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.image_not_supported_outlined),
                                          )
                                        : const Icon(Icons.image_outlined),
                                  ),
                                  SizedBox(width: 12 * widget.scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name[0].toUpperCase() + product.name.substring(1).toLowerCase(),
                                          style: TextStyle(
                                            fontSize: 13 * widget.scale,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1D1F),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4 * widget.scale),
                                        Text(
                                          product.unit,
                                          style: TextStyle(
                                            fontSize: 12 * widget.scale,
                                            color: const Color(0xFF9A9FA5),
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

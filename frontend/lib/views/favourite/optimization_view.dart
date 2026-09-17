import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/optimization_view_model.dart';
import '../../viewmodels/favourite_view_model.dart';
import '../../viewmodels/location_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/optimization/optimization_sub_header.dart';
import '../widgets/optimization/optimization_single_store_content.dart';
import '../widgets/optimization/optimization_multi_store_content.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final favouriteViewModel = context.read<FavouriteViewModel>();
      final optimizationViewModel = context.read<OptimizationViewModel>();
      final locationViewModel = context.read<LocationViewModel>();

      if (authViewModel.isLoggedIn && authViewModel.accessToken != null) {
        final token = authViewModel.accessToken!;
        final lat = locationViewModel.currentPosition?.latitude ?? 5.356;
        final lng = locationViewModel.currentPosition?.longitude ?? 100.301;
        final itemCodes = favouriteViewModel.favouriteProducts.map((p) => p.itemCode).toList();

        optimizationViewModel.fetchSingleStoreOptimization(
          token: token,
          latitude: lat,
          longitude: lng,
          itemCodes: itemCodes,
        );
        optimizationViewModel.fetchMultiStoreOptimization(
          token: token,
          latitude: lat,
          longitude: lng,
          itemCodes: itemCodes,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OptimizationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'COMPARE',
          style: TextStyle(
            color: const Color(0xFF1A1D1F),
            fontSize: 18 * widget.scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          OptimizationSubHeader(
            scale: widget.scale,
            isSingleStore: _isSingleStore,
            onSingleStoreTap: () => setState(() => _isSingleStore = true),
            onMultiStoreTap: () => setState(() => _isSingleStore = false),
          ),
          Expanded(
            child: _isSingleStore
                ? OptimizationSingleStoreContent(
                    viewModel: viewModel,
                    scale: widget.scale,
                  )
                : OptimizationMultiStoreContent(
                    viewModel: viewModel,
                    scale: widget.scale,
                  ),
          ),
        ],
      ),
    );
  }
}

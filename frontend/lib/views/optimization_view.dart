import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/grocery_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/optimization_header.dart';
import 'widgets/optimization_sub_header.dart';
import 'widgets/optimization_single_store_content.dart';
import 'widgets/optimization_multi_store_content.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar (Title + Back Button)
            OptimizationHeader(scale: widget.scale),
            
            // Sub-header Bar (Toggle + Sliding Indicator)
            OptimizationSubHeader(
              scale: widget.scale,
              isSingleStore: _isSingleStore,
              onSingleStoreTap: () => setState(() => _isSingleStore = true),
              onMultiStoreTap: () => setState(() => _isSingleStore = false),
            ),

            // Body Content (Switches between Single and Multi Store views)
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
      ),
    );
  }
}

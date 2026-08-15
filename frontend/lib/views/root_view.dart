import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/navigation_view_model.dart';
import 'grocery_view.dart';
import 'favourite_view.dart';
import 'profile_view.dart';
import 'widgets/common/bottom_navigation.dart';

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final navViewModel = context.read<NavigationViewModel>();
    _pageController = PageController(initialPage: navViewModel.selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navViewModel = context.watch<NavigationViewModel>();

    if (_pageController.hasClients) {
      if (_pageController.page?.round() != navViewModel.selectedIndex) {
        _pageController.animateToPage(
          navViewModel.selectedIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 402;

              return Container(
                color: const Color(0xFFFFFDFD),
                child: Stack(
                  children: [
                    // 1. Content Layer
                    Positioned.fill(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          GroceryView(scale: scale),
                          FavouriteView(scale: scale),
                          _buildSimplePage('COMPLAINT', scale),
                          ProfileView(scale: scale),
                        ],
                      ),
                    ),
                    
                    // 2. Bottom Navigation
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: BottomNavigation(
                        scale: scale,
                        selectedIndex: navViewModel.selectedIndex,
                        onTap: navViewModel.setSelectedIndex,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePage(String title, double scale) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 160 * scale,
          padding: EdgeInsets.only(top: 45 * scale, left: 20 * scale),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1F),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$title coming soon'
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'views/root_view.dart';
import 'viewmodels/grocery_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/favourite_view_model.dart';
import 'viewmodels/optimization_view_model.dart';
import 'viewmodels/navigation_view_model.dart';
import 'viewmodels/location_view_model.dart';
import 'services/grocery_service.dart';
import 'services/auth_service.dart';
import 'services/favourite_service.dart';
import 'services/optimization_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI mode to edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Services
  final authService = AuthService();
  final groceryService = GroceryService();
  final favouriteService = FavouriteService();
  final optimizationService = OptimizationService();

  // Initialize AuthViewModel first as it handles the global auth state
  final authViewModel = AuthViewModel(authService);

  // Wire up the authentication guard across all services
  authService.onResponseStatus = authViewModel.handleServiceResponse;
  groceryService.onResponseStatus = authViewModel.handleServiceResponse;
  favouriteService.onResponseStatus = authViewModel.handleServiceResponse;
  optimizationService.onResponseStatus = authViewModel.handleServiceResponse;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProvider<NavigationViewModel>(
          create: (_) => NavigationViewModel(),
        ),
        ChangeNotifierProvider<LocationViewModel>(
          create: (_) => LocationViewModel(),
        ),
        ChangeNotifierProvider<GroceryViewModel>(
          create: (_) => GroceryViewModel(groceryService),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, FavouriteViewModel>(
          create: (_) => FavouriteViewModel(favouriteService),
          update: (_, auth, favourite) {
            if (auth.isLoggedIn && auth.accessToken != null) {
              favourite!.loadFavourites(auth.accessToken!);
            } else {
              favourite!.clearFavourites();
            }
            return favourite;
          },
        ),
        ChangeNotifierProvider<OptimizationViewModel>(
          create: (_) => OptimizationViewModel(optimizationService),
        ),
      ],
      child: const GroceryApp(),
    ),
  );
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC83A)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat',
        useMaterial3: true,
      ),
      home: const RootView(),
    );
  }
}

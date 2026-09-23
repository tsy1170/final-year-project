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
import 'viewmodels/complaint_view_model.dart';
import 'viewmodels/notification_view_model.dart';
import 'viewmodels/compare_prices_view_model.dart';
import 'viewmodels/connectivity_view_model.dart';
import 'views/widgets/common/no_internet_view.dart';
import 'services/grocery_service.dart';
import 'services/auth_service.dart';
import 'services/favourite_service.dart';
import 'services/optimization_service.dart';
import 'services/complaint_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safeguard global initialization steps so any failure or missing native plugin/resource
  // in release mode does not stall execution or result in a black screen.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
    ),
  );

  // Initialize Services
  final authService = AuthService();
  final groceryService = GroceryService();
  final favouriteService = FavouriteService();
  final optimizationService = OptimizationService();
  final complaintService = ComplaintService();
  final notificationService = NotificationService();

  // Initialize AuthViewModel first as it handles the global auth state
  final authViewModel = AuthViewModel(authService);

  // Wire up the authentication guard across all services
  authService.onResponseStatus = authViewModel.handleServiceResponse;
  groceryService.onResponseStatus = authViewModel.handleServiceResponse;
  favouriteService.onResponseStatus = authViewModel.handleServiceResponse;
  optimizationService.onResponseStatus = authViewModel.handleServiceResponse;
  notificationService.onResponseStatus = authViewModel.handleServiceResponse;

  // Safeguard push notification and device token initialization
  try {
    await notificationService.initNotifications();
    final fcmToken = await notificationService.getDeviceToken();
    if (fcmToken != null) {
      await authViewModel.setFcmToken(fcmToken);
    }
  } catch (e) {
    debugPrint("Notification plugin initialization failed safely: $e");
  }

  // Register background handler safely before runApp
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase background messaging registration failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityViewModel>(
          create: (_) => ConnectivityViewModel(),
        ),
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
        ChangeNotifierProxyProvider2<AuthViewModel, LocationViewModel, FavouriteViewModel>(
          create: (_) => FavouriteViewModel(favouriteService),
          update: (_, auth, location, favourite) {
            if (auth.isLoggedIn && auth.accessToken != null) {
              favourite!.loadFavourites(auth.accessToken!);
              if (location.currentPosition != null && !favourite.isWorthBuyingLoading) {
                favourite.loadWorthBuyingFavourites(
                  auth.accessToken!, 
                  location.currentPosition!.latitude, 
                  location.currentPosition!.longitude
                );
              }
            } else {
              favourite!.clearFavourites();
            }
            return favourite;
          },
        ),
        ChangeNotifierProvider<OptimizationViewModel>(
          create: (_) => OptimizationViewModel(optimizationService),
        ),
        ChangeNotifierProvider<ComplaintViewModel>(
          create: (_) => ComplaintViewModel(complaintService),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, NotificationViewModel>(
          create: (_) => NotificationViewModel(notificationService),
          update: (_, auth, notification) {
            if (auth.isLoggedIn && auth.accessToken != null) {
              notification!.fetchPriceAlerts(auth.accessToken!);
            } else {
              notification!.clearAlerts();
            }
            return notification;
          },
        ),
        ChangeNotifierProvider<ComparePricesViewModel>(
          create: (_) => ComparePricesViewModel(complaintService, groceryService),
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
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: const Color(0xFF1A1D1F).withOpacity(0.4),
          selectionHandleColor: const Color(0xFF1A1D1F),
          cursorColor: const Color(0xFF1A1D1F),
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat',
        useMaterial3: true,
      ),
      home: const RootView(),
      builder: (context, child) {
        final connectivityVM = context.watch<ConnectivityViewModel>();
        if (connectivityVM.isOffline) {
          return const NoInternetView();
        }
        return child!;
      },
    );
  }
}

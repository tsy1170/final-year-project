import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'views/grocery_view.dart';
import 'viewmodels/grocery_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'services/grocery_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI mode to edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,

      // Required for Android 10+ to prevent the system from adding a semi-transparent overlay
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,

      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final groceryService = GroceryService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(groceryService)),
        ChangeNotifierProxyProvider<AuthViewModel, GroceryViewModel>(
          create: (_) => GroceryViewModel(groceryService),
          update: (_, auth, grocery) {
            if (auth.isLoggedIn && auth.accessToken != null) {
              grocery!.loadFavourites(auth.accessToken!);
            } else {
              grocery!.clearFavourites();
            }
            return grocery;
          },
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
        // Setting a solid background here ensures the transparent nav bar
        // has a color to show through from the Scaffold.
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat',
        useMaterial3: true,
      ),
      home: const GroceryView(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/grocery_view.dart';
import 'viewmodels/grocery_view_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroceryViewModel()),
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
      home: const GroceryView(),
    );
  }
}

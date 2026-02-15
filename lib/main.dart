import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/license_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChekuLeftApp());
}

class ChekuLeftApp extends StatelessWidget {
  const ChekuLeftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
      ],
      child: MaterialApp(
        title: 'Cheku Left',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE94560),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16213E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

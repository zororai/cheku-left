import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/license_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lock_screen.dart';

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
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 64, color: Color(0xFFE94560)),
                  SizedBox(height: 24),
                  Text(
                    'CHEKU LEFT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Color(0xFFE94560)),
                ],
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const _LicenseWrapper();
        }

        return const LoginScreen();
      },
    );
  }
}

class _LicenseWrapper extends StatefulWidget {
  const _LicenseWrapper();

  @override
  State<_LicenseWrapper> createState() => _LicenseWrapperState();
}

class _LicenseWrapperState extends State<_LicenseWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLicense();
    });
  }

  Future<void> _checkLicense() async {
    final auth = context.read<AuthProvider>();
    final licenseProvider = context.read<LicenseProvider>();
    final saleProvider = context.read<SaleProvider>();

    if (auth.butcherId != null) {
      saleProvider.setCurrentUser(
        butcherId: auth.butcherId!,
        butcherName: auth.butcherName,
      );

      await licenseProvider.checkLicenseStatus(butcherId: auth.butcherId!);
      await saleProvider.checkLicenseStatus(butcherId: auth.butcherId!);
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 64, color: Color(0xFFE94560)),
              SizedBox(height: 24),
              Text(
                'Verifying License...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFE94560)),
            ],
          ),
        ),
      );
    }

    return Consumer2<LicenseProvider, SaleProvider>(
      builder: (context, license, sale, _) {
        if (license.isLocked || sale.isLicenseLocked) {
          return const LockScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}

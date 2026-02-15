import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/license_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'lock_screen.dart';
import 'subscription_expired_screen.dart';
import 'suspended_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Starting...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Step 1: Check stored token/auth status
    setState(() => _statusMessage = 'Checking authentication...');
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (!authProvider.isAuthenticated) {
      _navigateTo(const LoginScreen());
      return;
    }

    // Step 2: Check subscription status
    if (authProvider.isSubscriptionExpired) {
      _navigateTo(const SubscriptionExpiredScreen());
      return;
    }

    if (authProvider.isAccountSuspended) {
      _navigateTo(const SuspendedScreen());
      return;
    }

    // Step 3: Check license status
    setState(() => _statusMessage = 'Verifying license...');
    final licenseProvider = context.read<LicenseProvider>();

    if (authProvider.butcherId != null) {
      await licenseProvider.checkLicenseStatus(
        butcherId: authProvider.butcherId!,
      );
    }

    if (!mounted) return;

    if (licenseProvider.isLocked) {
      _navigateTo(const LockScreen());
      return;
    }

    // All checks passed - go to Dashboard
    setState(() => _statusMessage = 'Loading dashboard...');
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _navigateTo(const DashboardScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CHEKU LEFT',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Butcher POS System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFE94560),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

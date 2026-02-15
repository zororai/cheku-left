import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.access_time_filled,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Subscription Expired',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your subscription has expired. Please contact your administrator to renew your subscription and continue using Cheku Left POS.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: Colors.white60, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '+263 77 521 9766',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/auth_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _hasInternet = false;
  String? _lastSyncMessage;
  bool _syncSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<SaleProvider>().loadSales(butcherId: auth.butcherId);
    });
  }

  Future<void> _checkConnection() async {
    final hasInternet = await context
        .read<SaleProvider>()
        .hasInternetConnection();
    setState(() => _hasInternet = hasInternet);
  }

  Future<void> _syncSales() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<SaleProvider>();

    if (!_hasInternet) {
      setState(() {
        _lastSyncMessage = 'No internet connection';
        _syncSuccess = false;
      });
      return;
    }

    final result = await provider.syncSales(butcherId: auth.butcherId);

    setState(() {
      _lastSyncMessage = result.message;
      _syncSuccess = result.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Sync Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkConnection();
              final auth = context.read<AuthProvider>();
              context.read<SaleProvider>().loadSales(butcherId: auth.butcherId);
            },
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _hasInternet
                              ? const Color(0xFF4CAF50).withOpacity(0.2)
                              : const Color(0xFFFF9800).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasInternet ? Icons.wifi : Icons.wifi_off,
                          size: 48,
                          color: _hasInternet
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasInternet ? 'Connected' : 'No Connection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _hasInternet
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasInternet
                            ? 'Ready to sync sales to server'
                            : 'Connect to internet to sync',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        color: Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${provider.unsyncedCount}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Sales Pending Sync',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_lastSyncMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _syncSuccess
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : const Color(0xFFFF5252).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _syncSuccess
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF5252),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _syncSuccess ? Icons.check_circle : Icons.error,
                          color: _syncSuccess
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF5252),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _lastSyncMessage!,
                            style: TextStyle(
                              color: _syncSuccess
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF5252),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSyncing || provider.unsyncedCount == 0
                        ? null
                        : _syncSales,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: provider.isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      provider.isSyncing
                          ? 'SYNCING...'
                          : provider.unsyncedCount == 0
                          ? 'ALL SYNCED'
                          : 'SYNC NOW',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Pending Sales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.unsyncedSales.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.cloud_done,
                          size: 48,
                          color: Color(0xFF4CAF50),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'All sales are synced!',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.unsyncedSales.map((sale) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cloud_off,
                              size: 20,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.saleNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${sale.items.length} items • ${sale.paymentMethod}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${sale.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

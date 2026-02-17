import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/print_service.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final PrintService _printService = PrintService.instance;
  List<PrinterDevice> _devices = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Request Bluetooth permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );

    if (!allGranted) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Bluetooth permissions required';
        _isLoading = false;
      });
      return;
    }

    await _scanDevices();
  }

  Future<void> _scanDevices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Scanning for printers...';
    });

    try {
      final devices = await _printService.getBondedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _statusMessage = devices.isEmpty
            ? 'No paired printers found. Please pair your printer in Bluetooth settings.'
            : '${devices.length} printer(s) found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error scanning: $e';
      });
    }

    // Check current connection
    final connected = await _printService.checkConnection();
    debugPrint('Connection status: $connected');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      // Force UI rebuild with latest connection status
    });
  }

  Future<void> _connectToDevice(PrinterDevice device) async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    final success = await _printService.connect(device);

    // Verify connection after connecting
    if (success) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _printService.checkConnection();
    }

    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _statusMessage = success
          ? 'Connected to ${device.name}'
          : 'Failed to connect to ${device.name}. Make sure printer is ON and in range.';
    });
  }

  Future<void> _disconnect() async {
    await _printService.disconnect();
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Disconnected';
    });
  }

  Future<void> _printTestPage() async {
    if (!mounted) return;
    setState(() => _statusMessage = 'Printing test page...');

    final success = await _printService.printTestPage();

    if (!mounted) return;
    setState(() {
      _statusMessage = success
          ? 'Test page printed!'
          : 'Failed to print test page';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Printer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _scanDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _printService.isConnected
                          ? Icons.print
                          : Icons.print_disabled,
                      color: _printService.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _printService.isConnected
                                ? 'Connected'
                                : 'Not Connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _printService.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          if (_printService.connectedDevice != null)
                            Text(
                              _printService.connectedDevice!.name,
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                    if (_printService.isConnected)
                      ElevatedButton(
                        onPressed: _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Disconnect'),
                      ),
                  ],
                ),
                if (_printService.isConnected) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _printTestPage,
                      icon: const Icon(Icons.print),
                      label: const Text('Print Test Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status Message
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Available Printers Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.bluetooth, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Available Printers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Device List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE94560)),
                  )
                : _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No printers found',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Make sure your printer is paired\nin Bluetooth settings',
                          style: TextStyle(color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _scanDevices,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnected =
                          _printService.connectedDevice?.address ==
                          device.address;

                      return Card(
                        color: const Color(0xFF16213E),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: isConnected ? Colors.green : Colors.white54,
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            device.address,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE94560),
                                  ),
                                )
                              : isConnected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    },
                  ),
          ),

          // Help Text
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Tip: If your printer is not listed, go to phone Settings > Bluetooth and pair your printer first.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

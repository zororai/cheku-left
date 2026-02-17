import 'dart:typed_data';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class PrinterDevice {
  final String name;
  final String address;

  PrinterDevice({required this.name, required this.address});
}

class PrintService {
  static final PrintService instance = PrintService._init();

  PrinterDevice? _connectedDevice;
  bool _isConnected = false;

  PrintService._init();

  bool get isConnected => _isConnected;
  PrinterDevice? get connectedDevice => _connectedDevice;

  Future<List<PrinterDevice>> getBondedDevices() async {
    try {
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      return devices
          .map((d) => PrinterDevice(name: d.name, address: d.macAdress))
          .toList();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  Future<bool> connect(PrinterDevice device) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      );
      _connectedDevice = device;
      _isConnected = result;
      return result;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
      _isConnected = false;
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      return _isConnected;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  Future<bool> printReceipt({
    required Sale sale,
    required List<SaleItem> items,
    required String shopName,
    required String cashierName,
    String? shopAddress,
    String? shopPhone,
    String? buyerName,
    double? charge,
  }) async {
    try {
      if (!_isConnected) {
        _isConnected = await PrintBluetoothThermal.connectionStatus;
        if (!_isConnected) {
          debugPrint('Printer not connected');
          return false;
        }
      }

      List<int> bytes = [];

      // Initialize
      bytes += [0x1B, 0x40]; // ESC @ - Initialize
      bytes += [0x0A]; // Line feed

      // Header - Shop name (centered, bold, large)
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      bytes += [0x1D, 0x21, 0x11]; // Double size
      bytes += shopName.toUpperCase().codeUnits;
      bytes += [0x0A];
      bytes += [0x1D, 0x21, 0x00]; // Normal size
      bytes += 'BUTCHER SHOP'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold off

      // Shop address if provided
      if (shopAddress != null && shopAddress.isNotEmpty) {
        bytes += shopAddress.codeUnits;
        bytes += [0x0A];
      }

      // Shop phone if provided
      if (shopPhone != null && shopPhone.isNotEmpty) {
        bytes += 'Tel: $shopPhone'.codeUnits;
        bytes += [0x0A];
      }

      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A, 0x0A];

      // Sale Info (left aligned)
      bytes += [0x1B, 0x61, 0x00]; // Left align
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      bytes += 'Receipt: ${sale.saleNumber}'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold off
      bytes += 'Date: ${_formatDate(sale.createdAt)}'.codeUnits;
      bytes += [0x0A];
      bytes += 'Cashier: $cashierName'.codeUnits;
      bytes += [0x0A];
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A];

      // Items Header
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      bytes += 'ITEM                      TOTAL'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold off
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A];

      // Print each item
      for (var item in items) {
        final weightKg = (item.weightGrams / 1000).toStringAsFixed(2);
        bytes += item.productName.codeUnits;
        bytes += [0x0A];
        final detail =
            '  ${weightKg}kg x \$${item.pricePerKg.toStringAsFixed(2)}/kg';
        final price = '\$${item.totalPrice.toStringAsFixed(2)}';
        final padding = 32 - detail.length - price.length;
        bytes += '$detail${' ' * (padding > 0 ? padding : 1)}$price'.codeUnits;
        bytes += [0x0A];
      }

      // Total
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      bytes += [0x1D, 0x21, 0x11]; // Double size
      final totalLabel = 'TOTAL:';
      final totalValue = '\$${sale.totalAmount.toStringAsFixed(2)}';
      bytes += '$totalLabel${' ' * 6}$totalValue'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1D, 0x21, 0x00]; // Normal size
      bytes += [0x1B, 0x45, 0x00]; // Bold off
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A];

      // Payment Method
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += 'Payment: ${sale.paymentMethod}'.codeUnits;
      bytes += [0x0A];

      // Buyer name and charge (if provided)
      if ((buyerName != null && buyerName.isNotEmpty) ||
          (charge != null && charge > 0)) {
        bytes += '--------------------------------'.codeUnits;
        bytes += [0x0A];
        bytes += [0x1B, 0x61, 0x00]; // Left align

        if (buyerName != null && buyerName.isNotEmpty) {
          bytes += 'Customer: $buyerName'.codeUnits;
          bytes += [0x0A];
        }

        if (charge != null && charge > 0) {
          bytes += [0x1B, 0x45, 0x01]; // Bold on
          bytes += 'Balance/Charge: \$${charge.toStringAsFixed(2)}'.codeUnits;
          bytes += [0x0A];
          bytes += [0x1B, 0x45, 0x00]; // Bold off
        }
      }
      bytes += [0x0A];

      // Footer
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += 'Thank you for your purchase!'.codeUnits;
      bytes += [0x0A];
      bytes += 'Visit us again'.codeUnits;
      bytes += [0x0A, 0x0A, 0x0A, 0x0A];
      bytes += [0x1D, 0x56, 0x00]; // Cut

      final result = await PrintBluetoothThermal.writeBytes(
        Uint8List.fromList(bytes),
      );
      debugPrint('Print result: $result');
      return result;
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  Future<bool> printTestPage() async {
    try {
      if (!_isConnected) {
        _isConnected = await PrintBluetoothThermal.connectionStatus;
        if (!_isConnected) {
          debugPrint('Printer not connected');
          return false;
        }
      }

      List<int> bytes = [];

      bytes += [0x1B, 0x40]; // Initialize
      bytes += [0x0A];
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += [0x1B, 0x45, 0x01]; // Bold on
      bytes += [0x1D, 0x21, 0x11]; // Double size
      bytes += 'CHEKU LEFT POS'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1D, 0x21, 0x00]; // Normal size
      bytes += 'Test Print'.codeUnits;
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold off
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A];
      bytes += 'Printer is working correctly!'.codeUnits;
      bytes += [0x0A];
      bytes += '--------------------------------'.codeUnits;
      bytes += [0x0A, 0x0A, 0x0A, 0x0A];
      bytes += [0x1D, 0x56, 0x00]; // Cut

      final result = await PrintBluetoothThermal.writeBytes(
        Uint8List.fromList(bytes),
      );
      debugPrint('Test print result: $result');
      return result;
    } catch (e) {
      debugPrint('Error printing test page: $e');
      return false;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}

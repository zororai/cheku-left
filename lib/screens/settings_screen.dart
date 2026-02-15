import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiUrlController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  bool _isLoading = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiTokenController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrlController.text =
          prefs.getString('api_url') ?? 'https://api.chekuleft.com';
      _apiTokenController.text = prefs.getString('api_token') ?? '';
      _shopAddressController.text = prefs.getString('shop_address') ?? '';
      _shopPhoneController.text = prefs.getString('shop_phone') ?? '';
      _logoPath = prefs.getString('shop_logo_path');
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_url', _apiUrlController.text.trim());
      await prefs.setString('api_token', _apiTokenController.text.trim());
      await prefs.setString('shop_address', _shopAddressController.text.trim());
      await prefs.setString('shop_phone', _shopPhoneController.text.trim());
      if (_logoPath != null) {
        await prefs.setString('shop_logo_path', _logoPath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final logoFile = File('${appDir.path}/shop_logo.png');
        await File(image.path).copy(logoFile.path);

        setState(() {
          _logoPath = logoFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shop_logo_path');

    if (_logoPath != null) {
      final file = File(_logoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _logoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE94560),
                    child: Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.username ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          auth.role?.toUpperCase() ?? 'CASHIER',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Receipt Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop Logo',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _logoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_logoPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.white38,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add logo',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (_logoPath != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _removeLogo,
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        label: const Text(
                          'Remove Logo',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Shop Address',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shopAddressController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter shop address',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shop Phone',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shopPhoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'API Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server URL',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'https://api.example.com',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link, color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'API Token',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiTokenController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your API token',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.key, color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.storefront, size: 48, color: Color(0xFFE94560)),
                  SizedBox(height: 12),
                  Text(
                    'CHEKU LEFT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Butcher POS System',
                    style: TextStyle(color: Colors.white60),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Offline-first POS system designed for butcher shops and meat markets in African market conditions.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

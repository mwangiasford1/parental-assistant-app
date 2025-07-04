// features/home/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../auth/login_screen.dart';

class QRCodeScreen extends StatelessWidget {
  final UserModel user;
  const QRCodeScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: user.uid,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Text('${user.name} (${user.role})'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR to Link Device'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QRScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      setState(() { scanned = true; });
      final userId = scanData.code;
      // Fetch user profile and log in as that user
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromJson(doc.data()!);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreenWithRole(user: user)),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found.')));
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text(scanned ? 'Scanned! Logging in...' : 'Scan a QR code to link device')),
          ),
        ],
      ),
    );
  }
} 
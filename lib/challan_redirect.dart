import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openChallanPortalWithPlate(
  String plateNumber,
  BuildContext context,
) async {
  // 📋 Copy plate number
  await Clipboard.setData(
    ClipboardData(text: plateNumber),
  );

  // 🌐 Open official site
  final uri = Uri.parse('https://echallan.mponline.gov.in');
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  // 🔔 Inform user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Vehicle number copied. Paste it on the challan site.',
      ),
      duration: Duration(seconds: 3),
    ),
  );
}

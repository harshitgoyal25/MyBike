import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTripScreen extends StatefulWidget {
  final String bikeId;
  final String tripId;
  final double distance;

  const EditTripScreen({
    super.key,
    required this.bikeId,
    required this.tripId,
    required this.distance,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.distance.toString());
    super.initState();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await FirebaseFirestore.instance
        .collection('bikes')
        .doc(widget.bikeId)
        .collection('trips')
        .doc(widget.tripId)
        .update({'distance': double.parse(_controller.text)});

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 🌞 AMBER APP BAR
      appBar: AppBar(
        title: const Text(
          'Edit Trip',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🧾 FORM CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    prefixIcon: Icon(Icons.route_outlined),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

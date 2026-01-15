import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTripScreen extends StatefulWidget {
  final String bikeId;
  final double currentOdometer;

  const AddTripScreen({
    super.key,
    required this.bikeId,
    required this.currentOdometer,
  });

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final distanceController = TextEditingController();
  final startOdoController = TextEditingController();
  final endOdoController = TextEditingController();

  DateTime date = DateTime.now();
  bool saving = false;
  bool useOdometer = false;

  @override
  void initState() {
    super.initState();
    startOdoController.text =
        widget.currentOdometer.toStringAsFixed(1);
  }

  Future<void> saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    double distance;
    double newOdometer;

    if (useOdometer) {
      final start = double.parse(startOdoController.text);
      final end = double.parse(endOdoController.text);

      if (end <= start) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End odometer must be greater'),
          ),
        );
        return;
      }

      distance = end - start;
      newOdometer = end;
    } else {
      distance = double.parse(distanceController.text);
      newOdometer = widget.currentOdometer + distance;
    }

    setState(() => saving = true);

    final bikeRef =
        FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId);

    final tripRef = bikeRef.collection('trips').doc();

    await FirebaseFirestore.instance.runTransaction((txn) async {
      txn.set(tripRef, {
        'distance': distance,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        if (useOdometer) ...{
          'startOdometer': double.parse(startOdoController.text),
          'endOdometer': newOdometer,
        },
      });

      txn.update(bikeRef, {
        'currentOdometer': newOdometer,
      });
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    distanceController.dispose();
    startOdoController.dispose();
    endOdoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📅 Date
              ListTile(
                title: Text(DateFormat('dd MMM yyyy').format(date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => date = d);
                },
              ),

              SwitchListTile(
                title: const Text('Use Odometer'),
                value: useOdometer,
                onChanged: (v) => setState(() => useOdometer = v),
              ),

              if (!useOdometer)
                TextFormField(
                  controller: distanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Distance (km)'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),

              if (useOdometer) ...[
                TextFormField(
                  controller: startOdoController,
                  decoration:
                      const InputDecoration(labelText: 'Start Odometer'),
                  enabled: false,
                ),
                TextFormField(
                  controller: endOdoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'End Odometer'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveTrip,
                  child: const Text('Save Trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

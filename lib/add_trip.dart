import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/bike_model.dart';
import 'trip_calculator.dart';

enum TripInputType { distance, odometer }

class AddTripScreen extends StatefulWidget {
  final String bikeId;

  const AddTripScreen({super.key, required this.bikeId});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _distanceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _petrolPriceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  TripInputType _inputType = TripInputType.distance;

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // 1️⃣ Fetch bike
      final bikeDoc = await FirebaseFirestore.instance
          .collection('bikes')
          .doc(widget.bikeId)
          .get();

      final bike = Bike.fromMap(bikeDoc.id, bikeDoc.data()!);

      // 2️⃣ Fetch last trip (for odometer)
      final lastTripSnap = await FirebaseFirestore.instance
          .collection('bikes')
          .doc(widget.bikeId)
          .collection('trips')
          .orderBy('endOdometer', descending: true)
          .limit(1)
          .get();

      final lastOdometer = lastTripSnap.docs.isNotEmpty
          ? (lastTripSnap.docs.first['endOdometer'] as num).toDouble()
          : bike.initialOdometer;

      // 3️⃣ Calculate trip
      final result = calculateTrip(
        bike: bike,
        distanceInput: _inputType == TripInputType.distance
            ? double.parse(_distanceController.text)
            : null,
        endOdometerInput: _inputType == TripInputType.odometer
            ? double.parse(_odometerController.text)
            : null,
        lastOdometer: lastOdometer,
        petrolPrice: double.parse(_petrolPriceController.text),
      );

      // 4️⃣ Save trip
      await FirebaseFirestore.instance
          .collection('bikes')
          .doc(widget.bikeId)
          .collection('trips')
          .add({
        'date': Timestamp.fromDate(_selectedDate),
        'distance': result.distance,
        'startOdometer': lastOdometer,
        'endOdometer': result.endOdometer,
        'petrolUsed': result.petrolUsed,
        'petrolPrice': double.parse(_petrolPriceController.text),
        'moneySpent': result.moneySpent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5️⃣ Update bike petrol
      await FirebaseFirestore.instance
          .collection('bikes')
          .doc(widget.bikeId)
          .update({
        'currentPetrol': result.updatedPetrol,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _odometerController.dispose();
    _petrolPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📅 Date
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.amber),
                title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _pickDate,
                ),
              ),

              const SizedBox(height: 16),

              // 🔀 Distance / Odometer Toggle
              SegmentedButton<TripInputType>(
                segments: const [
                  ButtonSegment(
                    value: TripInputType.distance,
                    label: Text('Distance'),
                  ),
                  ButtonSegment(
                    value: TripInputType.odometer,
                    label: Text('Odometer'),
                  ),
                ],
                selected: {_inputType},
                onSelectionChanged: (v) {
                  setState(() => _inputType = v.first);
                },
              ),

              const SizedBox(height: 16),

              // 📏 Distance OR Odometer input
              if (_inputType == TripInputType.distance)
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Distance (km)'),
                  validator: (v) =>
                      v == null || double.tryParse(v) == null
                          ? 'Enter valid distance'
                          : null,
                )
              else
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'End Odometer (km)'),
                  validator: (v) =>
                      v == null || double.tryParse(v) == null
                          ? 'Enter valid odometer'
                          : null,
                ),

              const SizedBox(height: 16),

              // 💰 Petrol Price
              TextFormField(
                controller: _petrolPriceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Petrol Price (₹/litre)'),
                validator: (v) =>
                    v == null || double.tryParse(v) == null
                        ? 'Enter valid price'
                        : null,
              ),

              const SizedBox(height: 24),

              // 💾 Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Save Trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

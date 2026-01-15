import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/bike_model.dart';

class AddBikeScreen extends StatefulWidget {
  final Bike? bike; // 👈 null = add, not null = edit

  const AddBikeScreen({super.key, this.bike});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mileageController;
  late TextEditingController _plateController;
  late TextEditingController _tankController;
  late TextEditingController _petrolController;
  late TextEditingController _odometerController;

  bool _saving = false;

  bool get isEdit => widget.bike != null;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.bike?.name ?? '');
    _mileageController =
        TextEditingController(text: widget.bike?.mileage.toString() ?? '');
    _plateController =
        TextEditingController(text: widget.bike?.plate ?? '');
    _tankController = TextEditingController(
        text: widget.bike?.fuelTankCapacity.toString() ?? '');
    _petrolController = TextEditingController(
        text: widget.bike?.currentPetrol.toString() ?? '');
    _odometerController = TextEditingController(
        text: widget.bike?.initialOdometer.toString() ?? '');
  }

  Future<void> _saveBike() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'mileage': double.parse(_mileageController.text),
      'plate': _plateController.text.trim(),
      'fuelTankCapacity': double.parse(_tankController.text),
      'currentPetrol': double.parse(_petrolController.text),
      'initialOdometer': double.parse(_odometerController.text),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final bikesRef =
          FirebaseFirestore.instance.collection('bikes');

      if (isEdit) {
        // ✏️ EDIT
        await bikesRef.doc(widget.bike!.id).update(data);
      } else {
        // ➕ ADD
        await bikesRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mileageController.dispose();
    _plateController.dispose();
    _tankController.dispose();
    _petrolController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Bike' : 'Add Bike'),
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
              _field(_nameController, 'Bike Name'),
              _field(_plateController, 'Plate Number'),
              _field(_mileageController, 'Mileage (km/l)'),
              _field(_tankController, 'Fuel Tank Capacity (L)'),
              _field(_petrolController, 'Current Petrol (L)'),
              _field(_odometerController, 'Initial Odometer (km)'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveBike,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.black)
                      : Text(
                          isEdit ? 'Save Changes' : 'Add Bike',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (v) =>
            v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}

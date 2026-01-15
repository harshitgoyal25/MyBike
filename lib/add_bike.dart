import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/bike_model.dart';

class AddBikeScreen extends StatefulWidget {
  final Bike? bike; // null = add, not null = edit

  const AddBikeScreen({super.key, this.bike});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController mileageCtrl;
  late TextEditingController plateCtrl;
  late TextEditingController monthlyLimitCtrl;
  late TextEditingController petrolCtrl;
  late TextEditingController initialOdoCtrl;

  bool saving = false;

  bool get isEdit => widget.bike != null;

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.bike?.name ?? '');
    mileageCtrl =
        TextEditingController(text: widget.bike?.mileage.toString() ?? '');
    plateCtrl = TextEditingController(text: widget.bike?.plate ?? '');
    monthlyLimitCtrl = TextEditingController(
        text: widget.bike?.monthlyLimit.toString() ?? '');
    petrolCtrl = TextEditingController(
        text: widget.bike?.currentPetrol.toString() ?? '');

    initialOdoCtrl = TextEditingController(
      text: widget.bike == null
          ? ''
          : widget.bike!.initialOdometer.toString(),
    );
  }

  Future<void> saveBike() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final bikesRef = FirebaseFirestore.instance.collection('bikes');

    final double initialOdo =
        double.tryParse(initialOdoCtrl.text) ?? 0;

    final data = {
      'name': nameCtrl.text.trim(),
      'mileage': double.parse(mileageCtrl.text),
      'plate': plateCtrl.text.trim(),
      'monthlyLimit': double.parse(monthlyLimitCtrl.text),
      'currentPetrol': double.parse(petrolCtrl.text),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (isEdit) {
        // ✏️ EDIT BIKE (DO NOT TOUCH ODOMETER)
        await bikesRef.doc(widget.bike!.id).update(data);
      } else {
        // ➕ ADD BIKE
        await bikesRef.add({
          ...data,
          'initialOdometer': initialOdo,
          'currentOdometer': initialOdo, // 🔥 IMPORTANT
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    mileageCtrl.dispose();
    plateCtrl.dispose();
    monthlyLimitCtrl.dispose();
    petrolCtrl.dispose();
    initialOdoCtrl.dispose();
    super.dispose();
  }

  Widget field(
    TextEditingController c,
    String label, {
    bool number = true,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        enabled: enabled,
        keyboardType:
            number ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    );
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
              field(nameCtrl, 'Bike Name', number: false),
              field(plateCtrl, 'Plate Number', number: false),
              field(mileageCtrl, 'Mileage (km/l)'),
              field(monthlyLimitCtrl, 'Monthly Limit (km)'),
              field(petrolCtrl, 'Current Petrol (L)'),

              // 🔒 Initial odometer only while adding
              if (!isEdit)
                field(initialOdoCtrl, 'Initial Odometer (km)'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveBike,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                        )
                      : Text(isEdit ? 'Save Changes' : 'Add Bike'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveBike() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('bikes').add({
      'name': _nameController.text.trim(),
      'plate': _plateController.text.trim(),
      'monthlyLimit': int.parse(_limitController.text),
      'mileage': double.parse(_mileageController.text),
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isSaving = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _limitController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 🌞 AMBER APP BAR
      appBar: AppBar(
        title: const Text(
          'Add Bike',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🚲 FORM CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Bike name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Bike Name',
                          hintText: 'Discover 100',
                          prefixIcon: Icon(Icons.motorcycle),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      // Number plate
                      TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          labelText: 'Number Plate',
                          hintText: 'MP09AB1234',
                          prefixIcon:
                              Icon(Icons.confirmation_number_outlined),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Monthly limit
                      TextFormField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Distance Limit (km)',
                          hintText: '1000',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ⛽ MILEAGE
                      TextFormField(
                        controller: _mileageController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Mileage (km per litre)',
                          hintText: '45',
                          prefixIcon:
                              Icon(Icons.local_gas_station_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final mileage = double.tryParse(value);
                          if (mileage == null || mileage <= 0) {
                            return 'Enter valid mileage';
                          }
                          return null;
                        },
                      ),
                    ],
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveBike,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Save Bike',
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
      ),
    );
  }
}

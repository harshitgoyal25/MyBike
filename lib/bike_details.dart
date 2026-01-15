import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'add_bike.dart';
import 'add_trip.dart';
import 'edit_trip.dart';
import 'models/bike_model.dart';

class BikeDetailsScreen extends StatelessWidget {
  final String bikeId;

  const BikeDetailsScreen({super.key, required this.bikeId});

  // 🚨 Challan helper
  Future<void> _openChallanWithPlate(
    BuildContext context,
    String plateNumber,
  ) async {
    await Clipboard.setData(ClipboardData(text: plateNumber));
    final uri = Uri.parse('https://echallan.mponline.gov.in');
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Vehicle number copied. Paste it on the challan site.'),
      ),
    );
  }

  Future<void> _showRefillDialog(BuildContext context, String bikeId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refill Petrol'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Litres added',
            hintText: 'e.g. 2.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;

              await FirebaseFirestore.instance
                  .collection('bikes')
                  .doc(bikeId)
                  .update({'currentPetrol': FieldValue.increment(value)});

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Petrol refilled')),
                );
              }
            },
            child: const Text('Refill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyBike',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Bike'),
                  content: const Text(
                    'This will delete the bike and all its trips. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseFirestore.instance
                    .collection('bikes')
                    .doc(bikeId)
                    .delete();

                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bikes')
            .doc(bikeId)
            .snapshots(),
        builder: (context, bikeSnapshot) {
          if (!bikeSnapshot.hasData ||
              bikeSnapshot.data == null ||
              !bikeSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final bike = Bike.fromMap(
            bikeId,
            bikeSnapshot.data!.data()! as Map<String, dynamic>,
          );

          // 🔥 PETROL PRICE STREAM (FIX ONLY HERE)
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('config')
                .doc('fuel')
                .snapshots(),
            builder: (context, fuelSnap) {
              final double petrolPrice =
                  fuelSnap.hasData &&
                      fuelSnap.data != null &&
                      fuelSnap.data!.data() != null
                  ? ((fuelSnap.data!.data()
                                    as Map<String, dynamic>)['petrolPrice']
                                as num?)
                            ?.toDouble() ??
                        106.5
                  : 106.5;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bikes')
                    .doc(bikeId)
                    .collection('trips')
                    .where(
                      'date',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
                    )
                    .where(
                      'date',
                      isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
                    )
                    .snapshots(),
                builder: (context, tripSnapshot) {
                  double driven = 0;

                  if (tripSnapshot.hasData) {
                    for (var doc in tripSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      driven += (data['distance'] as num?)?.toDouble() ?? 0;
                    }
                  }

                  final remainingKm = bike.monthlyLimit - driven;
                  final remainingDays = daysInMonth - now.day;
                  final kmPerDay = remainingDays > 0
                      ? remainingKm / remainingDays
                      : 0;

                  final petrolLimit = bike.mileage > 0
                      ? bike.monthlyLimit / bike.mileage
                      : 0;
                  final petrolUsed = bike.mileage > 0
                      ? driven / bike.mileage
                      : 0;
                  final petrolRemaining = petrolLimit - petrolUsed;

                  final moneyLimit = petrolLimit * petrolPrice;
                  final moneyUsed = petrolUsed * petrolPrice;
                  final moneyRemaining = moneyLimit - moneyUsed;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // HEADER
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.motorcycle,
                              color: Colors.amber,
                            ),
                            title: Text(bike.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mileage: ${bike.mileage.toStringAsFixed(1)} km/l • '
                                  'Limit: ${bike.monthlyLimit.toStringAsFixed(0)} km',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Petrol: ${bike.currentPetrol.toStringAsFixed(2)} L',
                                  style: TextStyle(
                                    color: bike.currentPetrol < 0.5
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _grid([
                          _stat('Driven', '${driven.toStringAsFixed(1)} km'),
                          _stat(
                            'Remaining',
                            '${remainingKm.toStringAsFixed(1)} km',
                            remainingKm < 0 ? Colors.red : Colors.green,
                          ),
                        ]),

                        _grid([
                          _stat('Days Left', '$remainingDays'),
                          _stat('Km / Day', kmPerDay.toStringAsFixed(1)),
                        ]),

                        _grid([
                          _stat(
                            'Petrol Used / Limit',
                            '${petrolUsed.toStringAsFixed(2)} / ${petrolLimit.toStringAsFixed(2)} L',
                          ),
                          _stat(
                            'Petrol Needed',
                            '${petrolRemaining.toStringAsFixed(2)} L',
                          ),
                        ]),

                        _grid([
                          _stat(
                            'Money Used / Limit',
                            '₹${moneyUsed.toStringAsFixed(0)} / ₹${moneyLimit.toStringAsFixed(0)}',
                          ),
                          _stat(
                            'Money Needed',
                            '₹${moneyRemaining.toStringAsFixed(0)}',
                          ),
                        ]),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.local_gas_station),
                            label: const Text('Refill Petrol'),
                            onPressed: () => _showRefillDialog(context, bikeId),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ACTION BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Trip'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTripScreen(
                                        bikeId: bikeId,
                                        currentOdometer: bike.currentOdometer,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Challan'),
                                onPressed: bike.plate.isEmpty
                                    ? null
                                    : () => _openChallanWithPlate(
                                        context,
                                        bike.plate,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddBikeScreen(bike: bike),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // TRIP LIST (UNCHANGED)
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bikes')
                                .doc(bikeId)
                                .collection('trips')
                                .orderBy('date', descending: true)
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snap.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text('No trips yet'),
                                );
                              }

                              return ListView.builder(
                                itemCount: snap.data!.docs.length,
                                itemBuilder: (context, i) {
                                  final t = snap.data!.docs[i];
                                  final d = (t['date'] as Timestamp).toDate();
                                  return ListTile(
                                    title: Text('${t['distance']} km'),
                                    subtitle: Text(
                                      DateFormat('dd MMM yyyy').format(d),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: children.map((e) => Expanded(child: e)).toList()),
    );
  }

  Widget _stat(String title, String value, [Color? color]) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

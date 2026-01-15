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
    final uri = Uri.parse('https://echallan.parivahan.gov.in');
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle number copied. Paste it on the challan site.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bike',
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
          if (!bikeSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bikeData = bikeSnapshot.data!.data() as Map<String, dynamic>;

          final double mileage = (bikeData['mileage'] as num?)?.toDouble() ?? 0;
          final String plate = bikeData['plate']?.toString() ?? '';
          final int monthlyLimit = bikeData['monthlyLimit'] ?? 0;

          final bike = Bike.fromMap(bikeId, bikeData);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🚲 BIKE HEADER
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.motorcycle,
                          size: 36,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bike.name, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Mileage: ${mileage > 0 ? mileage.toStringAsFixed(1) : '-'} km/l',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 📊 MONTH STATS
                StreamBuilder<QuerySnapshot>(
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
                  builder: (context, snapshot) {
                    double driven = 0;
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        driven += (doc['distance'] as num?)?.toDouble() ?? 0;
                      }
                    }

                    final remainingKm = monthlyLimit - driven;
                    final remainingDays = daysInMonth - now.day;
                    final perDay = remainingDays > 0
                        ? remainingKm / remainingDays
                        : 0;

                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.55,
                          ),
                      children: [
                        _statCard(
                          icon: Icons.speed,
                          title: 'Driven',
                          value: '${driven.toStringAsFixed(1)} km',
                        ),
                        _statCard(
                          icon: Icons.flag_outlined,
                          title: 'Remaining',
                          value: '${remainingKm.toStringAsFixed(1)} km',
                          valueColor: remainingKm >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        _statCard(
                          icon: Icons.calendar_today_outlined,
                          title: 'Days Left',
                          value: '$remainingDays',
                        ),
                        _statCard(
                          icon: Icons.trending_up,
                          title: 'Km / Day',
                          value: perDay.toStringAsFixed(1),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 🔘 ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTripScreen(bikeId: bikeId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Challan'),
                        onPressed: plate.isEmpty
                            ? null
                            : () => _openChallanWithPlate(context, plate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
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

                const SizedBox(height: 16),

                // 📋 TRIPS (Swipe + Undo)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bikes')
                        .doc(bikeId)
                        .collection('trips')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No trips yet'));
                      }

                      return ListView.separated(
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tripDoc = snapshot.data!.docs[index];
                          final tripData =
                              tripDoc.data() as Map<String, dynamic>;
                          final date = (tripData['date'] as Timestamp).toDate();

                          return Dismissible(
                            key: ValueKey(tripDoc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final deletedTrip = Map<String, dynamic>.from(
                                tripData,
                              );
                              final tripId = tripDoc.id;
                              final double petrolUsed =
                                  (tripData['petrolUsed'] as num?)
                                      ?.toDouble() ??
                                  0;

                              await tripDoc.reference.delete();

                              await FirebaseFirestore.instance
                                  .collection('bikes')
                                  .doc(bikeId)
                                  .update({
                                    'currentPetrol': FieldValue.increment(
                                      petrolUsed,
                                    ),
                                  });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Trip deleted'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('bikes')
                                          .doc(bikeId)
                                          .collection('trips')
                                          .doc(tripId)
                                          .set(deletedTrip);

                                      await FirebaseFirestore.instance
                                          .collection('bikes')
                                          .doc(bikeId)
                                          .update({
                                            'currentPetrol':
                                                FieldValue.increment(
                                                  -petrolUsed,
                                                ),
                                          });
                                    },
                                  ),
                                ),
                              );

                              return true;
                            },
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.route_outlined),
                                title: Text('${tripData['distance']} km'),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy').format(date),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditTripScreen(
                                        bikeId: bikeId,
                                        tripId: tripDoc.id,
                                        distance: (tripData['distance'] as num)
                                            .toDouble(),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'add_trip.dart';
import 'edit_trip.dart';

class BikeDetailsScreen extends StatelessWidget {
  final String bikeId;

  const BikeDetailsScreen({super.key, required this.bikeId});

  // 🚨 Challan helper (copy plate + open site)
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
        elevation: 0,
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

          final int monthlyLimit = bikeData['monthlyLimit'] ?? 0;
          final double mileage = (bikeData['mileage'] as num?)?.toDouble() ?? 0;
          final String plate = bikeData['plate']?.toString() ?? '';

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
                            Text(
                              bikeData['name'] ?? 'Bike',
                              style: theme.textTheme.titleLarge,
                            ),
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

                // 📊 CURRENT MONTH STATS
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
                        driven += (doc['distance'] as num).toDouble();
                      }
                    }

                    final remainingKm = monthlyLimit - driven;
                    final remainingDays = daysInMonth - now.day;
                    final perDay = remainingDays > 0
                        ? remainingKm / remainingDays
                        : 0;

                    final petrolLimit = mileage > 0
                        ? monthlyLimit / mileage
                        : null;

                    final petrolRemaining = mileage > 0
                        ? remainingKm / mileage
                        : null;

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
                          value: '${perDay.toStringAsFixed(1)}',
                        ),
                        _statCard(
                          icon: Icons.local_gas_station_outlined,
                          title: 'Petrol (Limit)',
                          value: petrolLimit == null
                              ? '-'
                              : '${petrolLimit.toStringAsFixed(2)} L',
                        ),
                        _statCard(
                          icon: Icons.local_gas_station_outlined,
                          title: 'Petrol (Remaining)',
                          value: petrolRemaining == null
                              ? '-'
                              : '${petrolRemaining.toStringAsFixed(2)} L',
                          valueColor:
                              petrolRemaining != null && petrolRemaining < 0
                              ? Colors.red
                              : null,
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
                  ],
                ),

                const SizedBox(height: 16),

                // 📋 TRIPS
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
                          final trip = snapshot.data!.docs[index];
                          final date = (trip['date'] as Timestamp).toDate();

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.route_outlined),
                              title: Text('${trip['distance']} km'),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy').format(date),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditTripScreen(
                                      bikeId: bikeId,
                                      tripId: trip.id,
                                      distance: (trip['distance'] as num)
                                          .toDouble(),
                                    ),
                                  ),
                                );
                              },
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
              textAlign: TextAlign.center,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_bike.dart';
import 'bike_details.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 🌞 AMBER APP BAR
      appBar: AppBar(
        title: const Text(
          'My Bikes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bikes').snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.motorcycle_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No bikes added yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to add your first bike',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final bikes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bikes.length,
            itemBuilder: (context, index) {
              final bike = bikes[index];
              final data = bike.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.motorcycle, color: Colors.amber),
                  title: Text(
                    data['name'] ?? 'Unknown Bike',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    data['plate'] ?? '-',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BikeDetailsScreen(bikeId: bike.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // ➕ FLOATING BUTTON (AMBER)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBikeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

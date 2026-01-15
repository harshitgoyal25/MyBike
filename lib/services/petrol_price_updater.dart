import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mybike/petrol_price_service.dart';

class PetrolPriceUpdater {
  static Future<void> updateIfNeeded() async {
    final ref = FirebaseFirestore.instance.collection('config').doc('fuel');
    final now = DateTime.now();

    final snap = await ref.get();

    if (snap.exists && snap.data() != null) {
      final lastUpdated = snap.data()!['lastUpdated'];

      if (lastUpdated != null) {
        final last = (lastUpdated as Timestamp).toDate();

        // ⏱ update only once every 12 hours
        if (now.difference(last).inHours < 12) {
          return;
        }
      }
    }

    final price = await PetrolPriceService.fetchPetrolPrice();

    // ❗ DO NOT overwrite with null
    if (price == null) {
      print('⚠️ Petrol price fetch failed');
      return;
    }

    await ref.set({
      'petrolPrice': price,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('✅ Petrol price updated: ₹$price');
  }
}


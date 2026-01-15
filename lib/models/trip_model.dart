import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final DateTime date;

  final double? distance;        // km
  final double? startOdometer;   // km
  final double? endOdometer;     // km

  final double petrolUsed;       // litres
  final double petrolPrice;      // ₹/litre
  final double moneySpent;       // ₹

  Trip({
    required this.id,
    required this.date,
    this.distance,
    this.startOdometer,
    this.endOdometer,
    required this.petrolUsed,
    required this.petrolPrice,
    required this.moneySpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'distance': distance,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'petrolUsed': petrolUsed,
      'petrolPrice': petrolPrice,
      'moneySpent': moneySpent,
    };
  }

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,

      // 🔐 date safe handling
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ??
              DateTime.now(),

      // 🔢 optional fields
      distance: (map['distance'] as num?)?.toDouble(),
      startOdometer: (map['startOdometer'] as num?)?.toDouble(),
      endOdometer: (map['endOdometer'] as num?)?.toDouble(),

      // 🔢 required but safe
      petrolUsed: (map['petrolUsed'] as num?)?.toDouble() ?? 0.0,
      petrolPrice: (map['petrolPrice'] as num?)?.toDouble() ?? 0.0,
      moneySpent: (map['moneySpent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

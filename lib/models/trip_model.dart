class Trip {
  final String id;
  final DateTime date;

  final double? distance;        // km (optional)
  final double? startOdometer;   // km (optional)
  final double? endOdometer;     // km (optional)

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
      'date': date.toIso8601String(),
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
      date: DateTime.parse(map['date']),
      distance: map['distance'] != null
          ? (map['distance'] as num).toDouble()
          : null,
      startOdometer: map['startOdometer'] != null
          ? (map['startOdometer'] as num).toDouble()
          : null,
      endOdometer: map['endOdometer'] != null
          ? (map['endOdometer'] as num).toDouble()
          : null,
      petrolUsed: (map['petrolUsed'] as num).toDouble(),
      petrolPrice: (map['petrolPrice'] as num).toDouble(),
      moneySpent: (map['moneySpent'] as num).toDouble(),
    );
  }
}

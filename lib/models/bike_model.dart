class Bike {
  final String id;
  final String name;
  final double mileage; // km per litre
  final String plate;
  final double monthlyLimit; // km per month
  final double currentPetrol; // litres
  final double initialOdometer; // km
  final double currentOdometer; // km

  Bike({
    required this.id,
    required this.name,
    required this.mileage,
    required this.currentPetrol,
    required this.initialOdometer,
    required this.plate,
    required this.monthlyLimit,
    required this.currentOdometer,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mileage': mileage,
      'plate': plate,
      'currentPetrol': currentPetrol,
      'initialOdometer': initialOdometer,
      'monthlyLimit': monthlyLimit,
      'currentOdometer': currentOdometer,
    };
  }

  factory Bike.fromMap(String id, Map<String, dynamic> map) {
    final initialOdo =
        (map['initialOdometer'] as num?)?.toDouble() ?? 0.0;

    final currentOdo =
        (map['currentOdometer'] as num?)?.toDouble() ?? initialOdo;

    return Bike(
      id: id,
      name: map['name']?.toString() ?? '',
      mileage: (map['mileage'] as num?)?.toDouble() ?? 0.0,
      plate: map['plate']?.toString() ?? '',
      currentPetrol: (map['currentPetrol'] as num?)?.toDouble() ?? 0.0,
      initialOdometer: initialOdo,
      monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
      currentOdometer: currentOdo,
    );
  }
}

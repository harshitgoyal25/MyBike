class Bike {
  final String id;
  final String name;
  final double mileage; // km per litre
  final String plate;

  final double fuelTankCapacity; // litres
  final double currentPetrol; // litres
  final double initialOdometer; // km

  Bike({
    required this.id,
    required this.name,
    required this.mileage,
    required this.fuelTankCapacity,
    required this.currentPetrol,
    required this.initialOdometer,
    required this.plate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mileage': mileage,
      'plate': plate, // ✅ FIXED
      'fuelTankCapacity': fuelTankCapacity,
      'currentPetrol': currentPetrol,
      'initialOdometer': initialOdometer,
    };
  }

  factory Bike.fromMap(String id, Map<String, dynamic> map) {
    return Bike(
      id: id,
      name: map['name']?.toString() ?? '',
      mileage: (map['mileage'] as num?)?.toDouble() ?? 0.0,
      plate: map['plate']?.toString() ?? '',
      fuelTankCapacity: (map['fuelTankCapacity'] as num?)?.toDouble() ?? 0.0,
      currentPetrol: (map['currentPetrol'] as num?)?.toDouble() ?? 0.0,
      initialOdometer: (map['initialOdometer'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

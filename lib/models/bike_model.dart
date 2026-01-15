class Bike {
  final String id;
  final String name;
  final double mileage; // km per litre

  final double fuelTankCapacity; // litres
  final double currentPetrol;    // litres

  final double initialOdometer;  // km

  Bike({
    required this.id,
    required this.name,
    required this.mileage,
    required this.fuelTankCapacity,
    required this.currentPetrol,
    required this.initialOdometer,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mileage': mileage,
      'fuelTankCapacity': fuelTankCapacity,
      'currentPetrol': currentPetrol,
      'initialOdometer': initialOdometer,
    };
  }

  factory Bike.fromMap(String id, Map<String, dynamic> map) {
    return Bike(
      id: id,
      name: map['name'],
      mileage: (map['mileage'] as num).toDouble(),
      fuelTankCapacity: (map['fuelTankCapacity'] as num).toDouble(),
      currentPetrol: (map['currentPetrol'] as num).toDouble(),
      initialOdometer: (map['initialOdometer'] as num).toDouble(),
    );
  }
}

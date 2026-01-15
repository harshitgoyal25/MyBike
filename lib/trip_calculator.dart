import 'models/bike_model.dart';

class TripCalculationResult {
  final double distance;
  final double petrolUsed;
  final double moneySpent;
  final double updatedPetrol;
  final double endOdometer;

  TripCalculationResult({
    required this.distance,
    required this.petrolUsed,
    required this.moneySpent,
    required this.updatedPetrol,
    required this.endOdometer,
  });
}

TripCalculationResult calculateTrip({
  required Bike bike,
  double? distanceInput,
  double? endOdometerInput,
  required double lastOdometer,
  required double petrolPrice,
}) {
  late double distance;
  late double endOdometer;

  // 1️⃣ Decide distance
  if (distanceInput != null) {
    distance = distanceInput;
    endOdometer = lastOdometer + distance;
  } else if (endOdometerInput != null) {
    endOdometer = endOdometerInput;
    distance = endOdometer - lastOdometer;
  } else {
    throw Exception("Either distance or odometer is required");
  }

  if (distance <= 0) {
    throw Exception("Invalid distance calculated");
  }

  // 2️⃣ Petrol calculation
  final petrolUsed = distance / bike.mileage;

  // 3️⃣ Money calculation
  final moneySpent = petrolUsed * petrolPrice;

  // 4️⃣ Petrol update
  final updatedPetrol = bike.currentPetrol - petrolUsed;

  if (updatedPetrol < 0) {
    throw Exception("Not enough petrol in bike");
  }

  return TripCalculationResult(
    distance: distance,
    petrolUsed: petrolUsed,
    moneySpent: moneySpent,
    updatedPetrol: updatedPetrol,
    endOdometer: endOdometer,
  );
}

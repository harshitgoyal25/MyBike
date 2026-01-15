import 'dart:convert';
import 'package:http/http.dart' as http;

class PetrolPriceService {
  static const String _url =
      'https://daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com/v1/fuel-prices/today/india/Madhya%20Pradesh/Indore';

  static const Map<String, String> _headers = {
    'X-RapidAPI-Key': 'YOUR_KEY_HERE',
    'X-RapidAPI-Host':
        'daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com',
  };

  static Future<double?> fetchPetrolPrice() async {
    try {
      final response = await http.get(Uri.parse(_url), headers: _headers);

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);

      final petrolString =
          decoded['data']?['fuel_prices']?[0]?['petrol'];

      if (petrolString == null) return null;

      return double.tryParse(petrolString.toString());
    } catch (e) {
      print('❌ Petrol API error: $e');
      return null;
    }
  }
}


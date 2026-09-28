import 'dart:convert';
import 'package:http/http.dart' as http;
import 'log_service.dart';

class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest/USD';
  
  // Cache the rates so we don't spam the API unnecessarily
  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetchTime;
  
  // Supported currencies we want to display
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'CAD', 'INR', 'AUD', 'JPY'];
  
  // Currency symbols mapping
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CAD': 'C\$',
    'INR': '₹',
    'AUD': 'A\$',
    'JPY': '¥',
  };

  /// Fetches the latest exchange rates relative to USD.
  /// Returns a map of currency codes to their exchange rates.
  static Future<Map<String, double>> fetchRates() async {
    // Return cached rates if they were fetched within the last hour
    if (_cachedRates != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inHours < 1) {
        return _cachedRates!;
      }
    }

    try {
      LogService.info('CurrencyService', 'Fetching live exchange rates from REST API');
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final ratesData = data['rates'] as Map<String, dynamic>;
          
          final Map<String, double> rates = {};
          ratesData.forEach((key, value) {
            rates[key] = (value as num).toDouble();
          });
          
          _cachedRates = rates;
          _lastFetchTime = DateTime.now();
          LogService.info('CurrencyService', 'Successfully cached new exchange rates');
          
          return rates;
        } else {
          throw Exception('API returned failure: ${data['error-type']}');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      LogService.error('CurrencyService', 'Failed to fetch currency rates', error: e);
      // Fallback to basic rates if network request fails
      return _cachedRates ?? {'USD': 1.0, 'EUR': 0.9, 'GBP': 0.8, 'CAD': 1.35, 'INR': 83.0, 'AUD': 1.5, 'JPY': 150.0};
    }
  }
}

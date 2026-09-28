import 'package:flutter/foundation.dart';
import '../services/currency_service.dart';

class CurrencyProvider with ChangeNotifier {
  String _selectedCurrency = 'USD';
  Map<String, double> _rates = {};
  bool _isLoading = false;

  String get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;
  List<String> get availableCurrencies => CurrencyService.supportedCurrencies;

  CurrencyProvider() {
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    _isLoading = true;
    notifyListeners();

    _rates = await CurrencyService.fetchRates();
    
    _isLoading = false;
    notifyListeners();
  }

  void setCurrency(String currencyCode) {
    if (CurrencyService.supportedCurrencies.contains(currencyCode)) {
      _selectedCurrency = currencyCode;
      notifyListeners();
    }
  }

  /// Converts a USD price to the currently selected currency.
  double convertPrice(double priceInUsd) {
    if (_selectedCurrency == 'USD' || _rates.isEmpty) {
      return priceInUsd;
    }
    final rate = _rates[_selectedCurrency] ?? 1.0;
    return priceInUsd * rate;
  }

  /// Formats a USD price as a string in the currently selected currency.
  String formatPrice(double priceInUsd) {
    final convertedPrice = convertPrice(priceInUsd);
    final symbol = CurrencyService.currencySymbols[_selectedCurrency] ?? '\$';
    return '$symbol${convertedPrice.toStringAsFixed(2)}';
  }
}

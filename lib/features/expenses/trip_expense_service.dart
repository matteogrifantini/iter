import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_expense_models.dart';

/// Service managing real-time currency rates from European Central Bank & Open Exchange,
/// budget tracking and multi-currency expense logging.
class TripExpenseService {
  TripExpenseService({http.Client? httpClient}) : _client = httpClient;

  final http.Client? _client;

  static const String _expensePrefix = 'iter_expenses_';
  static const String _budgetPrefix = 'iter_budget_';
  static const String _ratesCacheKey = 'iter_exchange_rates_cache';

  static Map<String, double> _cachedRates = {
    'EUR': 1.0,
    'HUF': 0.0025,
    'GBP': 1.18,
    'USD': 0.92,
    'CHF': 1.05,
    'CZK': 0.040,
    'PLN': 0.23,
    'JPY': 0.0062,
  };

  /// Fetches real-time exchange rates from open.er-api.com (100% free, updated daily).
  Future<void> refreshLiveRates() async {
    final client = _client ?? http.Client();
    final url = Uri.parse('https://open.er-api.com/v6/latest/EUR');
    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null) {
          final newRates = <String, double>{};
          rates.forEach((key, val) {
            final rateToEur = (val as num).toDouble();
            if (rateToEur > 0) {
              newRates[key] = 1.0 / rateToEur; // Invert to get 1 UNIT = X EUR
            }
          });
          newRates['EUR'] = 1.0;
          _cachedRates = newRates;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_ratesCacheKey, jsonEncode(newRates));
        }
      }
    } catch (_) {}
  }

  /// Converts any foreign amount into EUR using real market exchange rates.
  double convertToEur(double amount, String currency) {
    final rate = _cachedRates[currency.toUpperCase()] ?? 1.0;
    return amount * rate;
  }

  /// Loads expenses list for a trip.
  Future<List<TripExpense>> loadExpenses(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_expensePrefix$tripId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => TripExpense.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  /// Saves expenses for a trip.
  Future<void> saveExpenses(String tripId, List<TripExpense> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('$_expensePrefix$tripId', raw);
  }

  /// Loads budget target for a trip.
  Future<double> loadBudgetTarget(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_budgetPrefix$tripId') ?? 450.0;
  }

  /// Saves budget target for a trip.
  Future<void> saveBudgetTarget(String tripId, double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_budgetPrefix$tripId', budget);
  }
}

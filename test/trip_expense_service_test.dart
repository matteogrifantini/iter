import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/expenses/trip_expense_models.dart';
import 'package:iter/features/expenses/trip_expense_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripExpenseService', () {
    late TripExpenseService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = TripExpenseService();
    });

    test('converts foreign currencies to EUR correctly', () {
      final hufInEur = service.convertToEur(10000, 'HUF');
      expect(hufInEur, closeTo(25.0, 0.1));

      final gbpInEur = service.convertToEur(100, 'GBP');
      expect(gbpInEur, closeTo(118.0, 0.1));

      final eurInEur = service.convertToEur(50, 'EUR');
      expect(eurInEur, 50.0);
    });

    test('persists and loads expenses correctly', () async {
      final exp = TripExpense(
        id: 'exp-1',
        title: 'Cena Goulash Budapest',
        amount: 8000,
        currency: 'HUF',
        amountEur: 20.0,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      await service.saveExpenses('trip-bud', [exp]);
      final loaded = await service.loadExpenses('trip-bud');

      expect(loaded.length, 1);
      expect(loaded.first.title, 'Cena Goulash Budapest');
      expect(loaded.first.amountEur, 20.0);
      expect(loaded.first.category, ExpenseCategory.food);
    });

    test('persists and loads custom budget target', () async {
      await service.saveBudgetTarget('trip-bud', 650.0);
      final budget = await service.loadBudgetTarget('trip-bud');
      expect(budget, 650.0);
    });
  });
}

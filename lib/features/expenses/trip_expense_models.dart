import 'package:flutter/material.dart';

enum ExpenseCategory { food, stay, transport, tickets, shopping, other }

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Cibo & Ristoranti';
      case ExpenseCategory.stay:
        return 'Alloggio';
      case ExpenseCategory.transport:
        return 'Voli & Trasporti';
      case ExpenseCategory.tickets:
        return 'Attrazioni & Biglietti';
      case ExpenseCategory.shopping:
        return 'Shopping & Souvenir';
      case ExpenseCategory.other:
        return 'Varie';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.stay:
        return Icons.hotel_rounded;
      case ExpenseCategory.transport:
        return Icons.flight_takeoff_rounded;
      case ExpenseCategory.tickets:
        return Icons.confirmation_number_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.stay:
        return Colors.indigo;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.tickets:
        return Colors.purple;
      case ExpenseCategory.shopping:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}

/// A recorded real expense.
class TripExpense {
  TripExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.amountEur,
    required this.category,
    required this.date,
    this.paidBy = 'Tu',
  });

  final String id;
  final String title;
  final double amount;
  final String currency; // EUR, HUF, USD, GBP, etc.
  final double amountEur;
  final ExpenseCategory category;
  final DateTime date;
  final String paidBy;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'currency': currency,
    'amountEur': amountEur,
    'category': category.name,
    'date': date.toIso8601String(),
    'paidBy': paidBy,
  };

  factory TripExpense.fromJson(Map<String, dynamic> json) => TripExpense(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'EUR',
    amountEur: (json['amountEur'] as num?)?.toDouble() ?? 0.0,
    category:
        ExpenseCategory.values.asNameMap()[json['category']] ??
        ExpenseCategory.other,
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    paidBy: json['paidBy'] as String? ?? 'Tu',
  );
}

import 'package:flutter/material.dart';
import 'trip_expense_models.dart';
import 'trip_expense_service.dart';

/// Modal sheet offering full travel budget management and expense logging.
class TripExpenseSheet extends StatefulWidget {
  const TripExpenseSheet({
    super.key,
    required this.tripId,
    required this.destination,
  });

  final String tripId;
  final String destination;

  @override
  State<TripExpenseSheet> createState() => _TripExpenseSheetState();
}

class _TripExpenseSheetState extends State<TripExpenseSheet> {
  final _service = TripExpenseService();
  List<TripExpense> _expenses = [];
  double _budgetTarget = 450.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _service.loadExpenses(widget.tripId);
    final budget = await _service.loadBudgetTarget(widget.tripId);
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _budgetTarget = budget;
        _loading = false;
      });
    }
  }

  void _addExpense({
    required String title,
    required double amount,
    required String currency,
    required ExpenseCategory category,
  }) {
    final amountEur = _service.convertToEur(amount, currency);
    final item = TripExpense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      currency: currency,
      amountEur: amountEur,
      category: category,
      date: DateTime.now(),
    );

    setState(() {
      _expenses.insert(0, item);
    });
    _service.saveExpenses(widget.tripId, _expenses);
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
    _service.saveExpenses(widget.tripId, _expenses);
  }

  void _editBudget() {
    final controller = TextEditingController(
      text: _budgetTarget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Imposta budget di viaggio'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget totale in EUR (€)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _budgetTarget = val);
                _service.saveBudgetTarget(widget.tripId, val);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalSpentEur = _expenses.fold<double>(
      0.0,
      (acc, item) => acc + item.amountEur,
    );
    final remainingBudget = _budgetTarget - totalSpentEur;
    final budgetProgress = _budgetTarget > 0
        ? (totalSpentEur / _budgetTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Spese & Budget · ${widget.destination}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monitora le spese reali e converti valute estere',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Budget Overview Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E232A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Totale speso',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '€${totalSpentEur.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _editBudget,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(
                                    20,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Budget: €${_budgetTarget.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: budgetProgress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.black.withAlpha(15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              remainingBudget < 0
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(budgetProgress * 100).round()}% del budget',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              remainingBudget >= 0
                                  ? 'Rimanenti: €${remainingBudget.toStringAsFixed(2)}'
                                  : 'Sforato di €${(-remainingBudget).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: remainingBudget >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Expense Button
                  FilledButton.icon(
                    onPressed: () => _showAddExpenseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Registra nuova spesa'),
                  ),
                  const SizedBox(height: 20),
                  // Expenses List
                  Text(
                    'Storico spese',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_expenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              100,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nessuna spesa registrata finora.\nAggiungi scontrini, biglietti o cene per monitorare il viaggio!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._expenses.map((e) {
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : Colors.black.withAlpha(15),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e.category.color.withAlpha(30),
                            child: Icon(
                              e.category.icon,
                              color: e.category.color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            e.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${e.category.label} · ${_formatDate(e.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '€${e.amountEur.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (e.currency != 'EUR')
                                    Text(
                                      '${e.amount.toStringAsFixed(0)} ${e.currency}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                onPressed: () => _removeExpense(e.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String currency = widget.destination.toLowerCase().contains('budapest')
        ? 'HUF'
        : 'EUR';
    ExpenseCategory category = ExpenseCategory.food;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuova spesa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    hintText: 'Es. Cena tipica, Biglietto Terme...',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Importo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: currency,
                        items: const [
                          DropdownMenuItem(value: 'EUR', child: Text('EUR €')),
                          DropdownMenuItem(value: 'HUF', child: Text('HUF Ft')),
                          DropdownMenuItem(value: 'USD', child: Text('USD \$')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP £')),
                          DropdownMenuItem(value: 'CHF', child: Text('CHF')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => currency = v);
                        },
                        decoration: const InputDecoration(labelText: 'Valuta'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: category,
                  items: ExpenseCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.label, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text);
                if (amt != null && amt > 0 && titleCtrl.text.isNotEmpty) {
                  _addExpense(
                    title: titleCtrl.text.trim(),
                    amount: amt,
                    currency: currency,
                    category: category,
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Salva spesa'),
            ),
          ],
        ),
      ),
    );
  }
}

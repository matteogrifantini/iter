import 'package:flutter/material.dart';

/// Esito della richiesta di conferma acquisto esterno.
enum PurchaseDialogResult {
  /// L'utente ha completato l'acquisto sul portale del provider.
  confirmed,

  /// L'utente non ha ancora completato l'acquisto ma mantiene aperta l'opzione.
  pending,

  /// L'utente desidera annullare la selezione e tornare alla comparazione.
  cancelled,
}

/// Dialog esplicito per la conferma dell'acquisto completato esternamente.
class ExternalPurchaseDialog extends StatelessWidget {
  const ExternalPurchaseDialog({
    super.key,
    required this.providerName,
    required this.itemTitle,
    this.isStay = false,
  });

  final String providerName;
  final String itemTitle;
  final bool isStay;

  /// Mostra il dialog modale senza dismiss accidentale.
  static Future<PurchaseDialogResult?> show(
    BuildContext context, {
    required String providerName,
    required String itemTitle,
    bool isStay = false,
  }) {
    return showDialog<PurchaseDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExternalPurchaseDialog(
        providerName: providerName,
        itemTitle: itemTitle,
        isStay: isStay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = isStay ? 'questo alloggio' : 'questo volo';

    return AlertDialog(
      title: Text('Hai confermato $target?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sei tornato dal sito di $providerName.'),
          const SizedBox(height: 8),
          Text(
            itemTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conferma solo se hai completato l’acquisto con il fornitore. '
            'Iter non addebita pagamenti né conferma prenotazioni senza la tua approvazione esplicita.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(PurchaseDialogResult.cancelled),
          child: const Text('Annulla selezione'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(PurchaseDialogResult.pending),
          child: const Text('Non ancora'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(PurchaseDialogResult.confirmed),
          child: const Text('Sì, confermato'),
        ),
      ],
    );
  }
}

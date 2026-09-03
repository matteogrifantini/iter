import 'package:flutter/material.dart';
import '../../chat_first_prototype/chat_first_controller.dart';
import '../../chat_first_prototype/trip_snapshot_screen.dart';
import '../adapters/trip_plan_mapper.dart';
import '../engine/organization_session.dart';
import '../models/organization_card.dart';
import '../models/organization_state.dart';
import '../ui/cards/flight_comparison_card_view.dart';
import '../ui/cards/intent_summary_card_view.dart';
import '../ui/cards/question_card_view.dart';
import '../ui/cards/search_status_card_view.dart';
import '../ui/cards/stay_comparison_card_view.dart';
import '../ui/cards/zone_proposal_card_view.dart';
import '../ui/dialogs/external_purchase_dialog.dart';
import 'organization_message_composer.dart';

/// Schermata/View interattiva della timeline di organizzazione viaggio guidata.
class OrganizationThreadView extends StatefulWidget {
  const OrganizationThreadView({
    super.key,
    required this.session,
    this.title = 'Organizza viaggio',
  });

  final OrganizationSession session;
  final String title;

  @override
  State<OrganizationThreadView> createState() => _OrganizationThreadViewState();
}

class _OrganizationThreadViewState extends State<OrganizationThreadView> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCard(BuildContext context, OrganizationCard card) {
    switch (card.kind) {
      case OrganizationCardKind.intentSummary:
        return IntentSummaryCardView(card: card);
      case OrganizationCardKind.question:
        final qKey = card.payload['questionKey']?.toString() ?? '';
        return QuestionCardView(
          card: card,
          onAnswerSelected: (answer) {
            widget.session.answerQuestion(questionKey: qKey, answer: answer);
            _scrollToBottom();
          },
        );
      case OrganizationCardKind.searchStatus:
        return SearchStatusCardView(card: card);
      case OrganizationCardKind.flightComparison:
        final currentFlightId = widget.session.state.selectedFlightId;
        final updatedPayload = <String, dynamic>{
          ...card.payload,
          'selectedOfferId': ?currentFlightId,
        };

        return FlightComparisonCardView(
          card: card.copyWith(payload: updatedPayload),
          onOfferSelected: (offer) {
            widget.session.selectFlight(offer.id);
            _scrollToBottom();
          },

          onContinueToProvider: (offer) async {
            await widget.session.openExternalPurchase(
              offer.id,
              purchaseUrl: offer.deepLinkUrl,
            );
            if (!mounted) return;
            final result = await ExternalPurchaseDialog.show(
              this.context,
              providerName: offer.providerName,
              itemTitle:
                  '${offer.origin} → ${offer.destination} (${offer.conditions['airlineName'] ?? 'Volo'})',
            );

            if (result == PurchaseDialogResult.confirmed) {
              await widget.session.confirmFlightPurchase(
                offer.id,
                bookingReference:
                    'CONF-${DateTime.now().millisecondsSinceEpoch}',
              );
            }
            _scrollToBottom();
          },
        );
      case OrganizationCardKind.zoneProposal:
        return ZoneProposalCardView(
          card: card,
          onZoneSelected: (zone) {
            widget.session.selectZone(zone);
            _scrollToBottom();
          },
        );
      case OrganizationCardKind.stayComparison:
        return StayComparisonCardView(
          card: card,
          onOfferSelected: (offer) {
            widget.session.selectStay(offer.id);
            _scrollToBottom();
          },
          onSelfBookConfirmed: () {
            widget.session.confirmStayPurchase('self-booked-stay');
            _scrollToBottom();
          },
        );
      case OrganizationCardKind.planProposal:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(60),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.title ?? 'Piano di viaggio pronto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (card.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  card.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Visualizza itinerario'),
                onPressed: () {
                  try {
                    final snapshot = TripPlanMapper.mapStateToSnapshot(
                      widget.session.state,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TripSnapshotScreen(
                          controller: ChatFirstPrototypeController(),
                          conversationId: widget.session.tripId,
                          initialSnapshot: snapshot,
                        ),
                      ),
                    );
                  } catch (_) {}
                },
              ),
            ],
          ),
        );
      default:
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.title != null)
                  Text(
                    card.title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                if (card.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(card.description!),
                  ),
              ],
            ),
          ),
        );
    }
  }

  List<String> _resolveQuickChips(OrganizationState state) {
    if (state.cards.isEmpty) {
      return const [
        'Lisbona a novembre',
        'Weekend a Porto',
        'Tokyo in primavera',
      ];
    }

    final lastCard = state.cards.last;
    if (lastCard.kind == OrganizationCardKind.question &&
        lastCard.state != OrganizationCardState.confirmed) {
      final opts =
          (lastCard.payload['options'] as List?)?.cast<String>() ??
          const <String>[];
      if (opts.isNotEmpty) {
        return [...opts, 'Non lo so', 'Decidi tu'];
      }
      return const ['Non lo so', 'Decidi tu'];
    }

    return const [];
  }

  void _handleMessageSubmit(String text, OrganizationState state) {
    if (state.cards.isEmpty) {
      widget.session.submitDesire(text);
      _scrollToBottom();
      return;
    }

    final lastCard = state.cards.last;
    if (lastCard.kind == OrganizationCardKind.question &&
        lastCard.state != OrganizationCardState.confirmed) {
      final qKey = lastCard.payload['questionKey']?.toString() ?? '';
      widget.session.answerQuestion(questionKey: qKey, answer: text);
      _scrollToBottom();
      return;
    }

    // Input libero durante le altre fasi
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<OrganizationState>(
        stream: widget.session.states,
        initialData: widget.session.state,
        builder: (context, snapshot) {
          final state = snapshot.data ?? widget.session.state;
          final quickChips = _resolveQuickChips(state);

          return Column(
            children: [
              Expanded(
                child: state.cards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Descrivi il tuo prossimo viaggio ideale per iniziare.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: state.cards.length,
                        itemBuilder: (context, index) =>
                            _buildCard(context, state.cards[index]),
                      ),
              ),
              OrganizationMessageComposer(
                quickChips: quickChips,
                placeholder: state.cards.isEmpty
                    ? 'Es. Vorrei un weekend a Lisbona a novembre...'
                    : 'Scrivi la tua preferenza...',
                onSend: (text) => _handleMessageSubmit(text, state),
                onChipSelected: (chip) => _handleMessageSubmit(chip, state),
              ),
            ],
          );
        },
      ),
    );
  }
}

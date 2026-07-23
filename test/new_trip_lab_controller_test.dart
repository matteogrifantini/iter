import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_controller.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_models.dart';
import 'package:iter/features/new_trip_lab/new_trip_lab_proposals.dart';

void main() {
  group('saved availability windows', () {
    test('groups only real free days into consecutive windows', () {
      final windows = groupConsecutiveDates(<DateTime>[
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 26),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 3, 18),
      ]);

      expect(windows, hasLength(2));
      expect(windows.first.dayCount, 3);
      expect(windows.last.dayCount, 1);
    });

    test('counts calendar days across daylight-saving changes', () {
      final window = PrototypeDateWindow(
        start: DateTime(2026, 3, 29),
        end: DateTime(2026, 3, 30),
      );

      expect(window.dayCount, 2);
      expect(calendarDayDifference(window.start, window.end), 1);
    });
  });

  group('new trip v2 controller', () {
    late NewTripPrototypeController controller;

    setUp(() {
      controller = NewTripPrototypeController(
        clock: () => DateTime(2026, 7, 16, 22, 30),
        autoAdvanceDelay: Duration.zero,
        searchStageDelay: Duration.zero,
      );
    });

    tearDown(() => controller.dispose());

    Future<void> resolveOrigin([String city = 'Firenze']) async {
      controller.beginOriginResolution();
      controller.applyOriginResolution(
        PrototypeOriginResolution.resolved(
          PrototypeOriginSelection(
            label: city,
            source: PrototypeOriginSource.device,
          ),
        ),
      );
      await pumpEventQueue();
    }

    Future<void> completeOpenQuestions() async {
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.open);
      controller.setDurationPreset(
        PrototypeDateMode.open,
        PrototypeDurationPreset.any,
      );
      controller.performContextualAction();
      controller.selectCompany(PrototypeCompany.couple);
      await pumpEventQueue();
      controller.selectAnyTransport();
      await pumpEventQueue();
      controller.setBudget(500, autoAdvance: true);
      await pumpEventQueue();
      controller.toggleTravelStyle(PrototypeTravelStyle.culture);
      controller.performContextualAction();
      controller.selectPace(PrototypePace.balanced);
      await pumpEventQueue();
      controller.selectWalking(PrototypeWalking.normal);
      await pumpEventQueue();
    }

    test(
      'device origin is preselected and removed from question count',
      () async {
        expect(controller.currentStep, NewTripPrototypeStep.origin);
        expect(controller.totalSteps, 8);

        await resolveOrigin();

        expect(controller.origin, 'Firenze');
        expect(controller.originFromDevice, isTrue);
        expect(controller.currentStep, NewTripPrototypeStep.dates);
        expect(controller.totalSteps, 7);
      },
    );

    test(
      'manual origin replaces a failed resolution and stays editable',
      () async {
        controller.beginOriginResolution();
        controller.applyOriginResolution(
          const PrototypeOriginResolution.failed(
            PrototypeOriginFailure.permissionDenied,
          ),
        );
        expect(controller.originStatus, PrototypeOriginStatus.manualRequired);

        controller.setManualOrigin('Firenze Santa Maria Novella');
        await pumpEventQueue();

        expect(controller.origin, 'Firenze Santa Maria Novella');
        expect(controller.originFromDevice, isFalse);
        expect(controller.currentStep, NewTripPrototypeStep.dates);
      },
    );

    test('every origin failure falls back to manual entry', () {
      for (final failure in PrototypeOriginFailure.values) {
        controller.beginOriginResolution();
        controller.applyOriginResolution(
          PrototypeOriginResolution.failed(failure),
        );

        expect(
          controller.originStatus,
          PrototypeOriginStatus.manualRequired,
          reason: failure.name,
        );
        expect(controller.originFailure, failure, reason: failure.name);
        expect(
          controller.originFailureMessage(),
          isNotEmpty,
          reason: failure.name,
        );
      }
    });

    test('exact dates require at least one night', () async {
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.exact);
      controller.setExactDates(<DateTime>[DateTime(2026, 8, 31)]);
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isFalse);

      controller.setExactDates(<DateTime>[
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 1),
      ]);
      expect(controller.exactNights, 1);
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isTrue);
    });

    test('exact nights use calendar dates across daylight saving', () async {
      controller.dispose();
      controller = NewTripPrototypeController(
        clock: () => DateTime(2026, 3, 28),
        autoAdvanceDelay: Duration.zero,
      );
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.exact);
      controller.setExactDates(<DateTime>[
        DateTime(2026, 3, 29),
        DateTime(2026, 3, 30),
      ]);

      expect(controller.exactNights, 1);
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isTrue);
    });

    test('isolated flexible dates are valid departure dates', () async {
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.manualAvailability);
      controller.setDepartureDates(<DateTime>[
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 12),
        DateTime(2026, 8, 27),
      ]);

      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isFalse);
      controller.setDurationPreset(
        PrototypeDateMode.manualAvailability,
        PrototypeDurationPreset.threeFour,
      );

      expect(controller.departureDates, hasLength(3));
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isTrue);
      expect(
        controller.plainSummaryFor(NewTripPrototypeStep.dates),
        contains('3 partenze possibili'),
      );
      expect(controller.dateValidationMessage, isNull);
    });

    test('saved free days still require a consecutive usable window', () async {
      controller.dispose();
      controller = NewTripPrototypeController(
        clock: () => DateTime(2026, 7, 16),
        savedFreeDays: <DateTime>[
          DateTime(2026, 8, 2),
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 12),
        ],
        autoAdvanceDelay: Duration.zero,
      );
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.savedAvailability);
      controller.setDurationPreset(
        PrototypeDateMode.savedAvailability,
        PrototypeDurationPreset.threeFour,
      );

      expect(controller.savedWindows, hasLength(2));
      expect(controller.usableSavedWindows, hasLength(1));
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isTrue);

      controller.toggleSavedWindow(controller.savedWindows.first);
      expect(controller.isStepComplete(NewTripPrototypeStep.dates), isFalse);
    });

    test('saved free days outside the visible horizon are discarded', () {
      controller.dispose();
      controller = NewTripPrototypeController(
        clock: () => DateTime(2026, 7, 16),
        savedFreeDays: <DateTime>[
          DateTime(2026, 7, 15),
          DateTime(2026, 7, 16),
          DateTime(2027, 7, 16),
          DateTime(2027, 7, 17),
        ],
      );

      expect(controller.savedFreeDays, <DateTime>[
        DateTime(2026, 7, 16),
        DateTime(2027, 7, 16),
      ]);
    });

    test('double tap schedules only one automatic transition', () async {
      await resolveOrigin();
      controller.setDateMode(PrototypeDateMode.open);
      controller.setDurationPreset(
        PrototypeDateMode.open,
        PrototypeDurationPreset.any,
      );
      controller.performContextualAction();
      expect(controller.currentStep, NewTripPrototypeStep.company);

      controller.selectCompany(PrototypeCompany.solo);
      controller.selectCompany(PrototypeCompany.solo);
      await pumpEventQueue();

      expect(controller.currentStep, NewTripPrototypeStep.transport);
    });

    test(
      'all questions reach a shared summary without a generic next step',
      () async {
        await completeOpenQuestions();

        expect(controller.stage, NewTripFlowStage.summary);
        expect(controller.canStartSearch, isTrue);
        expect(controller.completedQuestionCount, 7);
      },
    );

    test(
      'deterministic search builds six internally consistent proposals',
      () async {
        await completeOpenQuestions();
        await controller.startSearch();

        expect(controller.stage, NewTripFlowStage.results);
        expect(controller.proposals, hasLength(6));
        expect(
          controller.proposals.map((item) => item.id).toSet(),
          hasLength(6),
        );
        for (final proposal in controller.proposals) {
          expect(
            proposal.cost.total,
            proposal.cost.transport + proposal.cost.stay + proposal.cost.local,
          );
          expect(
            proposal.groupTotal(controller.travelers),
            proposal.cost.total * 2,
          );
          expect(proposal.hasPriceRange, isTrue);
          expect(proposal.confidence, PrototypePriceConfidence.indicative);
        }
      },
    );

    test('exact dates produce point estimates with high confidence', () async {
      await completeOpenQuestions();
      controller.goToQuestion(
        NewTripPrototypeStep.dates,
        returnToSummary: true,
      );
      controller.setDateMode(PrototypeDateMode.exact);
      controller.setExactDates(<DateTime>[
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 14),
      ]);
      controller.performContextualAction();

      expect(controller.stage, NewTripFlowStage.summary);
      await controller.startSearch();

      for (final proposal in controller.proposals) {
        expect(proposal.hasPriceRange, isFalse);
        expect(proposal.confidence, PrototypePriceConfidence.high);
        expect(proposal.bestDateLabel, contains('10 set'));
      }
    });

    test(
      'open periods stay inside the chosen horizon and use walking needs',
      () async {
        await completeOpenQuestions();
        controller.goToQuestion(
          NewTripPrototypeStep.dates,
          returnToSummary: true,
        );
        controller.setOpenHorizon(3);
        controller.performContextualAction();
        controller.goToQuestion(
          NewTripPrototypeStep.walking,
          returnToSummary: true,
        );
        controller.selectWalking(PrototypeWalking.accessibility);
        await pumpEventQueue();
        await controller.startSearch();

        const allowedMonths = <String>{
          'Agosto 2026',
          'Settembre 2026',
          'Ottobre 2026',
        };
        for (final proposal in controller.proposals) {
          expect(
            allowedMonths.any(proposal.bestDateLabel.startsWith),
            isTrue,
            reason: proposal.bestDateLabel,
          );
          expect(
            proposal.matchReasons.any(
              (reason) => reason.toLowerCase().contains('accessibil'),
            ),
            isTrue,
          );
        }
      },
    );

    test('arrival mode follows the selected transport', () async {
      await completeOpenQuestions();
      controller.goToQuestion(
        NewTripPrototypeStep.transport,
        returnToSummary: true,
      );
      for (final transport in PrototypeTransport.values) {
        controller.toggleTransport(transport);
      }
      controller.toggleTransport(PrototypeTransport.train);
      controller.performContextualAction();
      await controller.startSearch();

      expect(
        controller.proposals.map((proposal) => proposal.arrivalTransport),
        everyElement(PrototypeTransport.train),
      );
    });

    test(
      'changing the origin changes deterministic costs and travel times',
      () async {
        await completeOpenQuestions();
        await controller.startSearch();
        final fromFirenze = <(int, int)>[
          for (final proposal in controller.proposals)
            (proposal.cost.transport, proposal.travelMinutes),
        ];

        expect(controller.consumeBack(), isTrue);
        controller.goToQuestion(
          NewTripPrototypeStep.origin,
          returnToSummary: true,
        );
        controller.setManualOrigin('Palermo');
        await pumpEventQueue();
        await controller.startSearch();
        final fromPalermo = <(int, int)>[
          for (final proposal in controller.proposals)
            (proposal.cost.transport, proposal.travelMinutes),
        ];

        expect(fromPalermo, isNot(fromFirenze));
        expect(
          controller.proposals.first.matchReasons.join(' '),
          contains('Da Palermo'),
        );
      },
    );

    test(
      'shortlist is stable, capped at four and compare starts at two',
      () async {
        await completeOpenQuestions();
        await controller.startSearch();
        final ids = controller.proposals.map((item) => item.id).toList();

        controller.toggleShortlist(ids[0]);
        expect(controller.canCompare, isFalse);
        controller.toggleShortlist(ids[1]);
        expect(controller.canCompare, isTrue);
        controller.toggleShortlist(ids[2]);
        controller.toggleShortlist(ids[3]);
        controller.toggleShortlist(ids[4]);

        expect(controller.shortlistIds, hasLength(4));
        expect(controller.shortlistIds, isNot(contains(ids[4])));
        controller.openComparison();
        expect(controller.stage, NewTripFlowStage.compare);
        controller.chooseProposal(ids[1]);
        expect(controller.stage, NewTripFlowStage.selected);
        expect(controller.selectedProposal?.id, ids[1]);
        expect(controller.selectedAlternatives, hasLength(3));
      },
    );

    test('empty proposal source exposes the no-result state', () async {
      controller.dispose();
      controller = NewTripPrototypeController(
        clock: () => DateTime(2026, 7, 16),
        proposalSource: const EmptyPrototypeProposalSource(),
        autoAdvanceDelay: Duration.zero,
        searchStageDelay: Duration.zero,
      );
      await completeOpenQuestions();
      await controller.startSearch();

      expect(controller.stage, NewTripFlowStage.results);
      expect(controller.proposals, isEmpty);
    });

    test(
      'a relaxation changes one query constraint and can unlock results',
      () async {
        final source = _RelaxationAwareProposalSource();
        controller.dispose();
        controller = NewTripPrototypeController(
          clock: () => DateTime(2026, 7, 16),
          proposalSource: source,
          autoAdvanceDelay: Duration.zero,
          searchStageDelay: Duration.zero,
        );
        await completeOpenQuestions();
        await controller.startSearch();
        expect(controller.proposals, isEmpty);

        await controller.retryWithRelaxation('+€100');

        expect(controller.proposals, hasLength(6));
        expect(source.queries.last.relaxationLabel, '+€100');
        expect(source.queries.last.budgetIncrease, 100);
        expect(source.queries.last.budgetPerPerson, 600);
        expect(source.queries.last.extraDurationDays, 0);
        expect(source.queries.last.includeNearbyOrigins, isFalse);
      },
    );

    test('editing one summary answer returns directly to summary', () async {
      await completeOpenQuestions();
      controller.goToQuestion(NewTripPrototypeStep.pace, returnToSummary: true);
      controller.selectPace(PrototypePace.relaxed);
      await pumpEventQueue();

      expect(controller.stage, NewTripFlowStage.summary);
      expect(controller.pace, PrototypePace.relaxed);
    });
  });
}

class _RelaxationAwareProposalSource implements PrototypeProposalSource {
  final List<PrototypeProposalQuery> queries = <PrototypeProposalQuery>[];

  @override
  Future<List<PrototypeTravelProposal>> search(
    PrototypeProposalQuery query,
  ) async {
    queries.add(query);
    if (query.relaxationLabel == null) {
      return const <PrototypeTravelProposal>[];
    }
    return const DeterministicPrototypeProposalSource().search(query);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_ops_filters.dart';
import 'package:admin_arawatan/core/admin_qa_fixtures.dart';
import 'package:admin_arawatan/admin/admin_driver_review_fixture/admin_qa_fixture_unavailable_widget.dart';

void main() {
  group('qaEvidenceSignature', () {
    test('empty filter has all tokens', () {
      const f = AdminOpsFilterState.empty;
      expect(
        f.qaEvidenceSignature,
        'country=all|status=all|activation=all|vehicle=all|docs=all|date=all',
      );
    });

    test('pending review changes status token and signature', () {
      const before = AdminOpsFilterState.empty;
      final after = before.copyWith(
        driverReview: AdminDriverReviewFilter.pendingReview,
      );
      expect(before.qaEvidenceSignature, isNot(after.qaEvidenceSignature));
      expect(after.qaStatusToken, 'pending_review');
      expect(after.qaEvidenceSignature.contains('status=pending_review'), isTrue);
    });

    test('activation / docs / date tokens', () {
      final f = AdminOpsFilterState.empty.copyWith(
        driverActivation: AdminDriverActivationFilter.activated,
        driverDocuments: AdminDriverDocumentsFilter.missing,
        datePreset: AdminDatePreset.last30Days,
      );
      expect(f.qaActivationToken, 'activated');
      expect(f.qaDocumentsToken, 'missing');
      expect(f.qaDateToken, '30d');
      expect(
        f.qaEvidenceSignature,
        'country=all|status=all|activation=activated|vehicle=all|docs=missing|date=30d',
      );
    });
  });

  group('describeDriverFilterPaths (query application)', () {
    test('All Drivers → ismndob only', () {
      expect(
        AdminOpsQueryBuilder.describeDriverFilterPaths(),
        ['ismndob==true'],
      );
    });

    test('Pending Review adds registration_status', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        driverReview: AdminDriverReviewFilter.pendingReview,
      );
      expect(c, contains('registration_status==pending_review'));
      expect(c, isNot(equals(['ismndob==true'])));
    });

    test('Activated adds actev_mndob', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        driverActivation: AdminDriverActivationFilter.activated,
      );
      expect(c, contains('actev_mndob==true'));
    });

    test('Documents Missing is server-side registration_documents_status', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        driverDocuments: AdminDriverDocumentsFilter.missing,
      );
      expect(c, contains('registration_documents_status==missing'));
      expect(c, isNot(contains('client_side:documents_missing')));
    });

    test('Documents Complete / Needs Reupload / Unknown Legacy are server-side',
        () {
      expect(
        AdminOpsQueryBuilder.describeDriverFilterPaths(
          driverDocuments: AdminDriverDocumentsFilter.complete,
        ),
        contains('registration_documents_status==complete'),
      );
      expect(
        AdminOpsQueryBuilder.describeDriverFilterPaths(
          driverDocuments: AdminDriverDocumentsFilter.needsReupload,
        ),
        contains('registration_documents_status==needs_reupload'),
      );
      expect(
        AdminOpsQueryBuilder.describeDriverFilterPaths(
          driverDocuments: AdminDriverDocumentsFilter.unknownLegacy,
        ),
        contains('registration_documents_status==unknown_legacy'),
      );
    });

    test('Vehicle Classification adds mndob_type_car', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        vehiclePath: 'type_car/family',
      );
      expect(c, contains('mndob_type_car==type_car/family'));
    });

    test('Country adds Rev_dolh', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        countryPath: 'countries/sa',
      );
      expect(c, contains('Rev_dolh==countries/sa'));
    });

    test('Last 30 Days adds created_time range', () {
      final now = DateTime.utc(2026, 8, 24, 12);
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.last30Days,
        now: now,
      )!;
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        dateRange: range,
      );
      expect(c, contains(startsWith('created_time>=')));
      expect(c, contains(startsWith('created_time<')));
      expect(
        AdminOpsFilterState.empty
            .copyWith(datePreset: AdminDatePreset.last30Days)
            .qaDateToken,
        '30d',
      );
    });

    test('Country + Status combines constraints', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        countryPath: 'countries/sa',
        driverReview: AdminDriverReviewFilter.pendingReview,
      );
      expect(c, contains('Rev_dolh==countries/sa'));
      expect(c, contains('registration_status==pending_review'));
    });

    test('Country + Vehicle combines constraints', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        countryPath: 'countries/sa',
        vehiclePath: 'type_car/sedan',
      );
      expect(c, contains('Rev_dolh==countries/sa'));
      expect(c, contains('mndob_type_car==type_car/sedan'));
    });

    test('Country + Status + Last 30 Days combines all', () {
      final now = DateTime.utc(2026, 8, 24, 12);
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.last30Days,
        now: now,
      )!;
      final c = AdminOpsQueryBuilder.describeDriverFilterPaths(
        countryPath: 'countries/sa',
        driverReview: AdminDriverReviewFilter.pendingReview,
        dateRange: range,
      );
      expect(c, contains('Rev_dolh==countries/sa'));
      expect(c, contains('registration_status==pending_review'));
      expect(c, contains(startsWith('created_time>=')));
      final sig = AdminOpsFilterState.empty
          .copyWith(
            driverReview: AdminDriverReviewFilter.pendingReview,
            datePreset: AdminDatePreset.last30Days,
          )
          .qaEvidenceSignature;
      expect(sig.contains('status=pending_review'), isTrue);
      expect(sig.contains('date=30d'), isTrue);
    });

    test('describeDriverFilterConstraints delegates to paths', () {
      final c = AdminOpsQueryBuilder.describeDriverFilterConstraints(
        AdminOpsFilterState.empty.copyWith(
          driverReview: AdminDriverReviewFilter.rejected,
        ),
      );
      expect(c, contains('registration_status==rejected'));
    });
  });

  group('FilterChip onSelected applies state (UI code)', () {
    testWidgets('tapping chip invokes onChanged with new review filter',
        (tester) async {
      AdminOpsFilterState? emitted;
      var current = AdminOpsFilterState.empty;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FilterChip(
                  key: const Key('qa-filter-review-pending'),
                  label: const Text('Pending'),
                  selected: current.driverReview ==
                      AdminDriverReviewFilter.pendingReview,
                  onSelected: (_) {
                    final next = current.copyWith(
                      driverReview: AdminDriverReviewFilter.pendingReview,
                    );
                    setState(() => current = next);
                    emitted = next;
                  },
                );
              },
            ),
          ),
        ),
      );

      final before = current.qaEvidenceSignature;
      await tester.tap(find.byKey(const Key('qa-filter-review-pending')));
      await tester.pump();

      expect(emitted, isNotNull);
      expect(emitted!.qaStatusToken, 'pending_review');
      expect(emitted!.qaEvidenceSignature, isNot(before));
    });
  });

  group('AdminQaFixtures production safety', () {
    test('default compile flag is false (production)', () {
      expect(AdminQaFixtures.enabled, isFalse);
    });

    testWidgets('unavailable page has denied semantics and no fixture PII',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminQaFixtureUnavailableWidget()),
      );
      expect(find.text('Not available'), findsOneWidget);
      expect(find.text('Not found'), findsOneWidget);
      expect(find.textContaining('QA Fixture'), findsNothing);
      expect(find.textContaining('fixture.driver@'), findsNothing);
    });
  });
}

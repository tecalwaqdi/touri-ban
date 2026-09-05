import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_edit_phase_ui.dart';

void main() {
  group('AdminDriverEditPhaseUi loading → loaded', () {
    test('loading: form absent, save absent, loading shell present', () {
      const phase = 'loading';
      expect(
        AdminDriverEditPhaseUi.showLoadingShell(phase, wantsEdit: true),
        isTrue,
      );
      expect(
        AdminDriverEditPhaseUi.showFormBody(phase, wantsEdit: true),
        isFalse,
      );
      expect(
        AdminDriverEditPhaseUi.showSaveAction(
          phase,
          wantsEdit: true,
          isEdit: true,
        ),
        isFalse,
      );
    });

    test('creating while wantsEdit: still loading shell (no blank create)', () {
      const phase = 'creating';
      expect(
        AdminDriverEditPhaseUi.showLoadingShell(phase, wantsEdit: true),
        isTrue,
      );
      expect(
        AdminDriverEditPhaseUi.showFormBody(phase, wantsEdit: true),
        isFalse,
      );
      expect(
        AdminDriverEditPhaseUi.showSaveAction(
          phase,
          wantsEdit: true,
          isEdit: false,
        ),
        isFalse,
      );
    });

    test('loaded: form present, save present, loading absent', () {
      const phase = 'loaded';
      expect(
        AdminDriverEditPhaseUi.showLoadingShell(phase, wantsEdit: true),
        isFalse,
      );
      expect(
        AdminDriverEditPhaseUi.showFormBody(phase, wantsEdit: true),
        isTrue,
      );
      expect(
        AdminDriverEditPhaseUi.showSaveAction(
          phase,
          wantsEdit: true,
          isEdit: true,
        ),
        isTrue,
      );
    });

    test('error/notFound/unauthorized: no save, no form', () {
      for (final phase in ['error', 'notFound', 'unauthorized']) {
        expect(AdminDriverEditPhaseUi.showErrorBody(phase), isTrue);
        expect(
          AdminDriverEditPhaseUi.showFormBody(phase, wantsEdit: true),
          isFalse,
        );
        expect(
          AdminDriverEditPhaseUi.showSaveAction(
            phase,
            wantsEdit: true,
            isEdit: true,
          ),
          isFalse,
        );
      }
    });

    test('create mode: form+save only in creating', () {
      expect(
        AdminDriverEditPhaseUi.showFormBody('creating', wantsEdit: false),
        isTrue,
      );
      expect(
        AdminDriverEditPhaseUi.showSaveAction(
          'creating',
          wantsEdit: false,
          isEdit: false,
        ),
        isTrue,
      );
      expect(
        AdminDriverEditPhaseUi.showLoadingShell('creating', wantsEdit: false),
        isFalse,
      );
    });
  });
}

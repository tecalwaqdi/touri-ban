/// Pure UI gates for Driver Create/Edit (`AddDrev`) paint contract.
///
/// Prevents blank body + Save: Save and form only when phase is ready.
abstract final class AdminDriverEditPhaseUi {
  AdminDriverEditPhaseUi._();

  static const phases = <String>{
    'creating',
    'loading',
    'loaded',
    'error',
    'notFound',
    'unauthorized',
  };

  /// Edit target known/resolving — never paint empty create form.
  static bool showLoadingShell(String phase, {required bool wantsEdit}) {
    if (!wantsEdit) return false;
    return phase == 'creating' || phase == 'loading';
  }

  static bool showFormBody(String phase, {required bool wantsEdit}) {
    if (wantsEdit) return phase == 'loaded';
    return phase == 'creating';
  }

  static bool showSaveAction(
    String phase, {
    required bool wantsEdit,
    required bool isEdit,
  }) {
    if (wantsEdit || isEdit) return phase == 'loaded';
    return phase == 'creating';
  }

  static bool showErrorBody(String phase) =>
      phase == 'error' || phase == 'notFound' || phase == 'unauthorized';
}

import 'dart:async';

/// Fired when a country agent's country scope is fully resolved (post-bootstrap).
class AdminAgentSessionReady {
  AdminAgentSessionReady._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get onReady => _controller.stream;

  static void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  static void reset() {}
}

/// FIN-4 agent attribution contract (proven from codebase audit).
///
/// Historical orders do NOT store per-order agent identity. Attribution uses:
/// - [AgentAttributionScope.country]: order `Rev_dolh` matches agent `Rev_dloh_agent`
/// - Agent commission rate from user `Agent_total` (percentage)
///
/// Multiple agents may share a country in data model; production commission is
/// only provable when exactly one active agent holds the country scope.
enum AgentAttributionScope {
  /// One exclusive country agent — commission applies to all country orders.
  countryExclusive,

  /// Country scope only — cannot prove which agent earned on a specific order.
  countryScopeOnly,

  /// Explicit per-order agent id (future snapshot fields — not on historical orders).
  perOrderAgent,
}

enum AgentAttributionConfidence {
  /// Rate + scope provable for attribution window.
  provable,

  /// Country scope only — commission shown as prospective / unallocated.
  scopeOnly,

  /// No agent or rate — exclude from canonical agent due.
  unknown,
}

class AgentAttributionContract {
  const AgentAttributionContract({
    required this.scope,
    required this.confidence,
    required this.multipleAgentsPerCountryPossible,
    required this.rateSourceField,
    required this.rateIsPercentage,
    required this.orderCountryField,
    required this.agentCountryField,
    this.historicalPerOrderSnapshotSupported = false,
  });

  final AgentAttributionScope scope;
  final AgentAttributionConfidence confidence;
  final bool multipleAgentsPerCountryPossible;
  final String rateSourceField;
  final bool rateIsPercentage;
  final String orderCountryField;
  final String agentCountryField;
  final bool historicalPerOrderSnapshotSupported;

  /// Canonical contract derived from project audit (FIN-4 §14–16).
  static const canonical = AgentAttributionContract(
    scope: AgentAttributionScope.countryScopeOnly,
    confidence: AgentAttributionConfidence.scopeOnly,
    multipleAgentsPerCountryPossible: true,
    rateSourceField: 'Agent_total',
    rateIsPercentage: true,
    orderCountryField: 'Rev_dolh',
    agentCountryField: 'Rev_dloh_agent',
    historicalPerOrderSnapshotSupported: false,
  );

  /// Future immutable snapshot field names (not written in FIN-2→6).
  static const prospectiveSnapshotFields = [
    'agent_id',
    'agent_scope',
    'agent_rate',
    'agent_rate_type',
    'agent_amount',
    'agent_currency',
    'agent_snapshot_at',
  ];
}

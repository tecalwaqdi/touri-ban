/// Canonical admin role / action matrix (documentation + UI reference).
/// Backend still enforces writes; this is not the security SoT alone.
library;

enum AdminPermAction {
  view,
  create,
  edit,
  approve,
  reverse,
  export,
  closePeriod,
}

enum AdminPermRole {
  superAdmin,
  finance,
  countryAdmin,
  other,
}

/// V = view, C = create, E = edit, A = approve, R = reverse, X = export, P = close period
const kAdminRoleMatrix = <String, Map<AdminPermRole, Set<AdminPermAction>>>{
  'Dashboard': {
    AdminPermRole.superAdmin: {AdminPermAction.view},
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {AdminPermAction.view},
  },
  'Users': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.other: {},
  },
  'Drivers': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.other: {},
  },
  'Orders': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.edit,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.edit,
      AdminPermAction.export,
    },
    AdminPermRole.other: {},
  },
  'Countries': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Cities': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.other: {},
  },
  'Landmarks': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.edit,
    },
    AdminPermRole.other: {},
  },
  'Support': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.edit,
    },
    AdminPermRole.finance: {AdminPermAction.view},
    AdminPermRole.countryAdmin: {
      AdminPermAction.view,
      AdminPermAction.edit,
    },
    AdminPermRole.other: {},
  },
  'Finance Hub': {
    AdminPermRole.superAdmin: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.finance: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Settlements': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.approve,
      AdminPermAction.reverse,
      AdminPermAction.export,
    },
    // F3-B2: Accountant (finance) is view-only; settlement execution is SuperAdmin.
    AdminPermRole.finance: {
      AdminPermAction.view,
      AdminPermAction.export,
    },
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Payments': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.approve,
      AdminPermAction.reverse,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {
      AdminPermAction.view,
      AdminPermAction.export,
    },
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Adjustments': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.approve,
      AdminPermAction.reverse,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {
      AdminPermAction.view,
      AdminPermAction.export,
    },
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Periods': {
    AdminPermRole.superAdmin: {
      AdminPermAction.view,
      AdminPermAction.create,
      AdminPermAction.closePeriod,
      AdminPermAction.export,
    },
    AdminPermRole.finance: {
      AdminPermAction.view,
      AdminPermAction.export,
    },
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Reports': {
    AdminPermRole.superAdmin: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.finance: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Audit': {
    AdminPermRole.superAdmin: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.finance: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
  'Reconciliation': {
    AdminPermRole.superAdmin: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.finance: {AdminPermAction.view, AdminPermAction.export},
    AdminPermRole.countryAdmin: {AdminPermAction.view},
    AdminPermRole.other: {},
  },
};

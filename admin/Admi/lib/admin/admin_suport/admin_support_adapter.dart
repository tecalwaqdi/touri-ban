import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';

/// Unified admin display status (does not replace stored values).
enum AdminSupportDisplayStatus {
  newTicket,
  open,
  inProgress,
  waitingUser,
  resolved,
  closed,
  unknown,
}

enum AdminSupportOwnerType {
  customer,
  driver,
  unknown,
}

enum AdminSupportTicketStatusFilter {
  all,
  open,
  inProgress,
  waitingUser,
  resolved,
  closed,
}

enum AdminSupportOwnerFilter {
  all,
  customer,
  driver,
}

enum AdminSupportOrderLinkFilter {
  all,
  linked,
  notLinked,
}

enum AdminSupportSort {
  newest,
  oldest,
  updated,
}

/// List row for `support` collection — dual-read legacy customer + driver schema.
class AdminSupportRow {
  const AdminSupportRow({
    required this.ticket,
    required this.ticketId,
    required this.legacyNumericId,
    required this.ownerName,
    required this.ownerType,
    required this.subject,
    required this.messagePreview,
    required this.category,
    required this.displayStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.phoneLabel,
    required this.email,
    required this.userRef,
    required this.orderRef,
    required this.attachmentUrl,
    required this.assignedAdminId,
    required this.isDriverSchema,
    required this.rawHalh,
    required this.rawStatus,
  });

  final SupportRecord ticket;
  final String ticketId;
  final int legacyNumericId;
  final String ownerName;
  final AdminSupportOwnerType ownerType;
  final String subject;
  final String messagePreview;
  final String category;
  final AdminSupportDisplayStatus displayStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String phoneLabel;
  final String email;
  final DocumentReference? userRef;
  final DocumentReference? orderRef;
  final String attachmentUrl;
  final String assignedAdminId;
  final bool isDriverSchema;
  final HalhSupport? rawHalh;
  final String rawStatus;

  static String _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static DateTime? _date(dynamic v) {
    if (v is DateTime) return v;
    return null;
  }

  static DateTime? createdAtOf(Map<String, dynamic> data) =>
      _date(data['data']) ?? _date(data['created_at']);

  static DateTime? updatedAtOf(Map<String, dynamic> data) =>
      _date(data['updated_at']) ??
      _date(data['resolved_at']) ??
      _date(data['closed_at']) ??
      createdAtOf(data);

  static DocumentReference? userRefOf(Map<String, dynamic> data) {
    final a = data['RefUser'];
    final b = data['user'];
    if (a is DocumentReference) return a;
    if (b is DocumentReference) return b;
    return null;
  }

  static DocumentReference? orderRefOf(Map<String, dynamic> data) {
    final a = data['order_ref'] ?? data['orderRef'] ?? data['order'];
    if (a is DocumentReference) return a;
    return null;
  }

  static bool isDriverSchemaData(Map<String, dynamic> data) {
    if (data.containsKey('user') && data['user'] is DocumentReference) {
      return true;
    }
    if (_str(data, 'status').isNotEmpty && !data.containsKey('halh')) {
      return true;
    }
    if (_str(data, 'msg').isNotEmpty && _str(data, 'osf').isEmpty) {
      return true;
    }
    return false;
  }

  static AdminSupportOwnerType ownerTypeFromUser(UserRecord? user) {
    if (user == null) return AdminSupportOwnerType.unknown;
    if (user.ismndob || user.ismndom) return AdminSupportOwnerType.driver;
    if (user.isagent) return AdminSupportOwnerType.unknown;
    return AdminSupportOwnerType.customer;
  }

  static AdminSupportDisplayStatus displayStatusOf({
    HalhSupport? halh,
    String? status,
    String? adminWorkflow,
  }) {
    final wf = (adminWorkflow ?? '').trim().toLowerCase();
    if (wf == 'in_progress') {
      return AdminSupportDisplayStatus.inProgress;
    }
    if (wf == 'waiting_user') {
      return AdminSupportDisplayStatus.waitingUser;
    }

    if (halh != null) {
      return switch (halh) {
        HalhSupport.Open => AdminSupportDisplayStatus.open,
        HalhSupport.Resolved => AdminSupportDisplayStatus.resolved,
        HalhSupport.Closed => AdminSupportDisplayStatus.closed,
      };
    }

    final s = (status ?? '').trim().toLowerCase();
    return switch (s) {
      'open' || 'new' => AdminSupportDisplayStatus.open,
      'in_progress' || 'inprogress' => AdminSupportDisplayStatus.inProgress,
      'waiting_user' || 'waiting' => AdminSupportDisplayStatus.waitingUser,
      'resolved' => AdminSupportDisplayStatus.resolved,
      'closed' => AdminSupportDisplayStatus.closed,
      '' => AdminSupportDisplayStatus.newTicket,
      _ => AdminSupportDisplayStatus.unknown,
    };
  }

  static String subjectOf(Map<String, dynamic> data) {
    final tsnef = _str(data, 'tsnef');
    if (tsnef.isNotEmpty) return tsnef;
    final sub = _str(data, 'sub');
    if (sub.isNotEmpty) return sub;
    return _str(data, 'naim');
  }

  static String ownerNameOf(Map<String, dynamic> data) {
    final naim = _str(data, 'naim');
    if (naim.isNotEmpty && !isDriverSchemaData(data)) return naim;
    final email = _str(data, 'email');
    if (email.isNotEmpty) return email;
    final sub = _str(data, 'sub');
    if (sub.contains(':')) return sub.split(':').first.trim();
    return naim.isNotEmpty ? naim : '—';
  }

  static String messageOf(Map<String, dynamic> data) {
    final osf = _str(data, 'osf');
    if (osf.isNotEmpty) return osf;
    return _str(data, 'msg');
  }

  static String phoneLabelOf(Map<String, dynamic> data) {
    final p = data['phone'];
    if (p is int && p > 0) return '$p';
    final pn = data['phon_n'];
    if (pn is int && pn > 0) return '$pn';
    return '';
  }

  static String categoryOf(Map<String, dynamic> data) {
    final tsnef = _str(data, 'tsnef');
    if (tsnef.isNotEmpty) return tsnef;
    return _str(data, 'category');
  }

  static AdminSupportRow fromTicket(SupportRecord ticket) {
    final data = ticket.snapshotData;
    final driverSchema = isDriverSchemaData(data);
    final msg = messageOf(data);
    final preview = msg.length > 120 ? '${msg.substring(0, 117)}…' : msg;
    final halh = ticket.halh;
    final status = _str(data, 'status');
    final wf = _str(data, 'admin_workflow');

    return AdminSupportRow(
      ticket: ticket,
      ticketId: ticket.reference.id,
      legacyNumericId: ticket.id,
      ownerName: ownerNameOf(data),
      ownerType: driverSchema
          ? AdminSupportOwnerType.driver
          : AdminSupportOwnerType.customer,
      subject: subjectOf(data),
      messagePreview: preview.isNotEmpty ? preview : '—',
      category: categoryOf(data).isNotEmpty ? categoryOf(data) : '—',
      displayStatus: displayStatusOf(
        halh: halh,
        status: status,
        adminWorkflow: wf,
      ),
      createdAt: createdAtOf(data),
      updatedAt: updatedAtOf(data),
      phoneLabel: phoneLabelOf(data),
      email: _str(data, 'email'),
      userRef: userRefOf(data),
      orderRef: orderRefOf(data),
      attachmentUrl: _str(data, 'attachment_url'),
      assignedAdminId: _str(data, 'admin_assigned_to'),
      isDriverSchema: driverSchema,
      rawHalh: halh,
      rawStatus: status,
    );
  }

  bool matchesSearch(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    return ticketId.toLowerCase().contains(q) ||
        (legacyNumericId > 0 && '$legacyNumericId'.contains(q)) ||
        ownerName.toLowerCase().contains(q) ||
        subject.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        messagePreview.toLowerCase().contains(q) ||
        phoneLabel.contains(q.replaceAll(RegExp(r'[\s\-]'), '')) ||
        email.toLowerCase().contains(q) ||
        (orderRef?.id.toLowerCase().contains(q) ?? false);
  }

  bool get isTerminal =>
      displayStatus == AdminSupportDisplayStatus.resolved ||
      displayStatus == AdminSupportDisplayStatus.closed;

  bool get hasOrderLink => orderRef != null;
}

class AdminSupportExtraFilters {
  const AdminSupportExtraFilters({
    this.status = AdminSupportTicketStatusFilter.all,
    this.owner = AdminSupportOwnerFilter.all,
    this.orderLink = AdminSupportOrderLinkFilter.all,
    this.category = '',
    this.sort = AdminSupportSort.newest,
  });

  final AdminSupportTicketStatusFilter status;
  final AdminSupportOwnerFilter owner;
  final AdminSupportOrderLinkFilter orderLink;
  final String category;
  final AdminSupportSort sort;

  static const empty = AdminSupportExtraFilters();

  bool get hasAny =>
      status != AdminSupportTicketStatusFilter.all ||
      owner != AdminSupportOwnerFilter.all ||
      orderLink != AdminSupportOrderLinkFilter.all ||
      category.trim().isNotEmpty ||
      sort != AdminSupportSort.newest;

  int get activeCount =>
      (status != AdminSupportTicketStatusFilter.all ? 1 : 0) +
      (owner != AdminSupportOwnerFilter.all ? 1 : 0) +
      (orderLink != AdminSupportOrderLinkFilter.all ? 1 : 0) +
      (category.trim().isNotEmpty ? 1 : 0) +
      (sort != AdminSupportSort.newest ? 1 : 0);

  String get signature =>
      '${status.name}|${owner.name}|${orderLink.name}|${category.trim().toLowerCase()}|${sort.name}';

  AdminSupportExtraFilters copyWith({
    AdminSupportTicketStatusFilter? status,
    AdminSupportOwnerFilter? owner,
    AdminSupportOrderLinkFilter? orderLink,
    String? category,
    AdminSupportSort? sort,
  }) =>
      AdminSupportExtraFilters(
        status: status ?? this.status,
        owner: owner ?? this.owner,
        orderLink: orderLink ?? this.orderLink,
        category: category ?? this.category,
        sort: sort ?? this.sort,
      );

  List<AdminSupportRow> apply(List<AdminSupportRow> rows) {
    var out = rows;
    switch (status) {
      case AdminSupportTicketStatusFilter.open:
        out = out
            .where((r) =>
                r.displayStatus == AdminSupportDisplayStatus.open ||
                r.displayStatus == AdminSupportDisplayStatus.newTicket)
            .toList(growable: false);
        break;
      case AdminSupportTicketStatusFilter.inProgress:
        out = out
            .where(
              (r) => r.displayStatus == AdminSupportDisplayStatus.inProgress,
            )
            .toList(growable: false);
        break;
      case AdminSupportTicketStatusFilter.waitingUser:
        out = out
            .where(
              (r) => r.displayStatus == AdminSupportDisplayStatus.waitingUser,
            )
            .toList(growable: false);
        break;
      case AdminSupportTicketStatusFilter.resolved:
        out = out
            .where((r) => r.displayStatus == AdminSupportDisplayStatus.resolved)
            .toList(growable: false);
        break;
      case AdminSupportTicketStatusFilter.closed:
        out = out
            .where((r) => r.displayStatus == AdminSupportDisplayStatus.closed)
            .toList(growable: false);
        break;
      case AdminSupportTicketStatusFilter.all:
        break;
    }
    switch (owner) {
      case AdminSupportOwnerFilter.customer:
        out = out
            .where((r) => r.ownerType == AdminSupportOwnerType.customer)
            .toList(growable: false);
        break;
      case AdminSupportOwnerFilter.driver:
        out = out
            .where((r) => r.ownerType == AdminSupportOwnerType.driver)
            .toList(growable: false);
        break;
      case AdminSupportOwnerFilter.all:
        break;
    }
    switch (orderLink) {
      case AdminSupportOrderLinkFilter.linked:
        out = out.where((r) => r.hasOrderLink).toList(growable: false);
        break;
      case AdminSupportOrderLinkFilter.notLinked:
        out = out.where((r) => !r.hasOrderLink).toList(growable: false);
        break;
      case AdminSupportOrderLinkFilter.all:
        break;
    }
    final cat = category.trim().toLowerCase();
    if (cat.isNotEmpty) {
      out = out
          .where((r) => r.category.toLowerCase().contains(cat))
          .toList(growable: false);
    }
    return _sort(out, sort);
  }

  static List<AdminSupportRow> _sort(
    List<AdminSupportRow> rows,
    AdminSupportSort sort,
  ) {
    final out = List<AdminSupportRow>.from(rows);
    switch (sort) {
      case AdminSupportSort.newest:
        out.sort((a, b) {
          final ac = a.createdAt;
          final bc = b.createdAt;
          if (ac == null && bc == null) return 0;
          if (ac == null) return 1;
          if (bc == null) return -1;
          return bc.compareTo(ac);
        });
        break;
      case AdminSupportSort.oldest:
        out.sort((a, b) {
          final ac = a.createdAt;
          final bc = b.createdAt;
          if (ac == null && bc == null) return 0;
          if (ac == null) return 1;
          if (bc == null) return -1;
          return ac.compareTo(bc);
        });
        break;
      case AdminSupportSort.updated:
        out.sort((a, b) {
          final au = a.updatedAt ?? a.createdAt;
          final bu = b.updatedAt ?? b.createdAt;
          if (au == null && bu == null) return 0;
          if (au == null) return 1;
          if (bu == null) return -1;
          return bu.compareTo(au);
        });
        break;
    }
    return out;
  }
}

/// Maps admin actions to stored fields (dual-write for mixed schema).
Map<String, dynamic> adminSupportStatusPatch({
  required AdminSupportDisplayStatus target,
  required bool isDriverSchema,
}) {
  final now = FieldValue.serverTimestamp();
  HalhSupport? halh;
  String? status;
  String? workflow;

  switch (target) {
    case AdminSupportDisplayStatus.open:
    case AdminSupportDisplayStatus.newTicket:
      halh = HalhSupport.Open;
      status = 'open';
      workflow = '';
      break;
    case AdminSupportDisplayStatus.inProgress:
      halh = HalhSupport.Open;
      status = 'open';
      workflow = 'in_progress';
      break;
    case AdminSupportDisplayStatus.waitingUser:
      halh = HalhSupport.Open;
      status = 'open';
      workflow = 'waiting_user';
      break;
    case AdminSupportDisplayStatus.resolved:
      halh = HalhSupport.Resolved;
      status = 'resolved';
      workflow = '';
      break;
    case AdminSupportDisplayStatus.closed:
      halh = HalhSupport.Closed;
      status = 'closed';
      workflow = '';
      break;
    case AdminSupportDisplayStatus.unknown:
      break;
  }

  final patch = <String, dynamic>{
    if (halh != null) 'halh': halh.serialize(),
    if (status != null) 'status': status,
    'admin_workflow': workflow ?? '',
    'updated_at': now,
    if (target == AdminSupportDisplayStatus.resolved) 'resolved_at': now,
    if (target == AdminSupportDisplayStatus.closed) 'closed_at': now,
    // Heal driver tickets into legacy sort field when missing.
    if (isDriverSchema) 'data': now,
  };
  return patch;
}

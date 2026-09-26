import 'package:hive/hive.dart';
import '../../backend/models/ticket.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class TicketRepository {
  TicketRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<TicketModel>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/maintenance/maintenance/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final priorityStr = (m['priority'] ?? 'medium').toString().toLowerCase();
        final statusStr = (m['status'] ?? 'open').toString().toLowerCase();
        final catStr = (m['category'] ?? 'other').toString().toLowerCase();
        return TicketModel(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
          description: m['description']?.toString(),
          category: catStr.contains('plumbing')
              ? TicketCategory.plumbing
              : catStr.contains('electrical')
                  ? TicketCategory.electrical
                  : catStr.contains('cleaning')
                      ? TicketCategory.cleaning
                      : TicketCategory.other,
          roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? '',
          priority: priorityStr.contains('high') || priorityStr.contains('critical')
              ? TicketPriority.high
              : priorityStr.contains('low')
                  ? TicketPriority.low
                  : TicketPriority.medium,
          status: statusStr.contains('resolved')
              ? TicketStatus.resolved
              : statusStr.contains('progress')
                  ? TicketStatus.inProgress
                  : (statusStr.contains('cancel') || statusStr.contains('closed'))
                      ? TicketStatus.closed
                      : TicketStatus.open,
          costIncurred: double.tryParse(m['cost_incurred']?.toString() ?? '0') ?? 0,
          createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
          pgId: m['pg']?.toString() ?? pgId,
        );
      }).toList();
      await _settings.put('cache.tickets_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.tickets_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final priorityStr = (m['priority'] ?? 'medium').toString().toLowerCase();
          final statusStr = (m['status'] ?? 'open').toString().toLowerCase();
          final catStr = (m['category'] ?? 'other').toString().toLowerCase();
          return TicketModel(
            id: m['id']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
            description: m['description']?.toString(),
            category: catStr.contains('plumbing')
                ? TicketCategory.plumbing
                : catStr.contains('electrical')
                    ? TicketCategory.electrical
                    : catStr.contains('cleaning')
                        ? TicketCategory.cleaning
                        : TicketCategory.other,
            roomId: m['room']?.toString() ?? m['room_number']?.toString() ?? '',
            priority: priorityStr.contains('high') || priorityStr.contains('critical')
                ? TicketPriority.high
                : priorityStr.contains('low')
                    ? TicketPriority.low
                    : TicketPriority.medium,
            status: statusStr.contains('resolved')
                ? TicketStatus.resolved
                : statusStr.contains('progress')
                    ? TicketStatus.inProgress
                    : (statusStr.contains('cancel') || statusStr.contains('closed'))
                        ? TicketStatus.closed
                        : TicketStatus.open,
            costIncurred: double.tryParse(m['cost_incurred']?.toString() ?? '0') ?? 0,
            createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<TicketModel> createTicket(TicketModel ticket) async {
    final client = ApiClient(authStorage: _authStorage);
    final catStr = ticket.category == TicketCategory.plumbing
        ? 'plumbing'
        : ticket.category == TicketCategory.electrical
            ? 'electrical'
            : ticket.category == TicketCategory.cleaning
                ? 'cleaning'
                : 'other';
    final priorityStr = ticket.priority == TicketPriority.high
        ? 'high'
        : ticket.priority == TicketPriority.low
            ? 'low'
            : 'medium';
    final body = {
      'title': ticket.title,
      if (ticket.description != null) 'description': ticket.description,
      'category': catStr,
      if (ticket.roomId.isNotEmpty) 'room': ticket.roomId,
      'priority': priorityStr,
      if (ticket.costIncurred != null) 'cost_incurred': ticket.costIncurred,
      'pg': ticket.pgId,
    };
    final data = await client.post('/api/maintenance/maintenance/', body);
    final priorityStrResp = (data['priority'] ?? 'medium').toString().toLowerCase();
    final catStrResp = (data['category'] ?? 'other').toString().toLowerCase();
    final statusStrResp = (data['status'] ?? 'open').toString().toLowerCase();
    return TicketModel(
      id: data['id']?.toString() ?? ticket.id,
      title: data['title']?.toString() ?? ticket.title,
      description: data['description']?.toString() ?? ticket.description,
      category: catStrResp.contains('plumbing')
          ? TicketCategory.plumbing
          : catStrResp.contains('electrical')
              ? TicketCategory.electrical
              : catStrResp.contains('cleaning')
                  ? TicketCategory.cleaning
                  : TicketCategory.other,
      roomId: data['room']?.toString() ?? data['room_number']?.toString() ?? ticket.roomId,
      priority: priorityStrResp.contains('high') || priorityStrResp.contains('critical')
          ? TicketPriority.high
          : priorityStrResp.contains('low')
              ? TicketPriority.low
              : TicketPriority.medium,
      status: statusStrResp.contains('resolved')
          ? TicketStatus.resolved
          : statusStrResp.contains('progress')
              ? TicketStatus.inProgress
              : TicketStatus.open,
      costIncurred: double.tryParse(data['cost_incurred']?.toString() ?? '0') ?? ticket.costIncurred ?? 0,
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? ticket.createdAt,
      pgId: data['pg']?.toString() ?? ticket.pgId,
    );
  }

  Future<void> updateTicket(TicketModel ticket) async {
    final client = ApiClient(authStorage: _authStorage);
    final path = '/api/maintenance/maintenance/${ticket.id}/';
    String statusStr = 'open';
    if (ticket.status == TicketStatus.resolved) {
      statusStr = 'resolved';
    } else if (ticket.status == TicketStatus.inProgress) {
      statusStr = 'inProgress';
    } else if (ticket.status == TicketStatus.closed) {
      statusStr = 'cancelled';
    }
    final body = <String, dynamic>{
      if (ticket.title.isNotEmpty) 'title': ticket.title,
      'status': statusStr,
      if (ticket.description != null) 'description': ticket.description,
      if (ticket.costIncurred != null) 'cost_incurred': ticket.costIncurred,
    };
    await client.patch(path, body);
  }
}


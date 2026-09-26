import 'package:hive/hive.dart';
import '../../backend/models/expense.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class ExpenseRepository {
  ExpenseRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<Expense>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/expenses/expenses/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final catStr = (m['category'] ?? 'other').toString().toLowerCase();
        return Expense(
          id: m['id']?.toString() ?? '',
          category: catStr.contains('water') || catStr.contains('electricity')
              ? ExpenseCategory.water
              : catStr.contains('maintenance')
                  ? ExpenseCategory.maintenance
                  : ExpenseCategory.other,
          amount: double.tryParse(m['amount']?.toString() ?? '0') ?? 0,
          date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
          note: m['note']?.toString() ?? m['description']?.toString(),
          pgId: m['pg']?.toString() ?? pgId,
        );
      }).toList();
      await _settings.put('cache.expenses_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.expenses_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final catStr = (m['category'] ?? 'other').toString().toLowerCase();
          return Expense(
            id: m['id']?.toString() ?? '',
            category: catStr.contains('water') || catStr.contains('electricity')
                ? ExpenseCategory.water
                : catStr.contains('maintenance')
                    ? ExpenseCategory.maintenance
                    : ExpenseCategory.other,
            amount: double.tryParse(m['amount']?.toString() ?? '0') ?? 0,
            date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
            note: m['note']?.toString() ?? m['description']?.toString(),
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    final client = ApiClient(authStorage: _authStorage);
    final catStr = expense.category == ExpenseCategory.water
        ? 'water'
        : expense.category == ExpenseCategory.electricity
            ? 'electricity'
            : expense.category == ExpenseCategory.maintenance
                ? 'maintenance'
                : 'other';
    final body = {
      'category': catStr,
      'amount': expense.amount,
      'date': expense.date.toIso8601String().split('T').first,
      if (expense.note != null) 'note': expense.note,
      'pg': expense.pgId,
    };
    final data = await client.post('/api/expenses/expenses/', body);
    final catStrResp = (data['category'] ?? 'other').toString().toLowerCase();
    return Expense(
      id: data['id']?.toString() ?? expense.id,
      category: catStrResp.contains('water') || catStrResp.contains('electricity')
          ? ExpenseCategory.water
          : catStrResp.contains('maintenance')
              ? ExpenseCategory.maintenance
              : ExpenseCategory.other,
      amount: double.tryParse(data['amount']?.toString() ?? '${expense.amount}') ?? expense.amount,
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? expense.date,
      note: data['note']?.toString() ?? data['description']?.toString() ?? expense.note,
      pgId: data['pg']?.toString() ?? expense.pgId,
    );
  }
}


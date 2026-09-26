import 'package:hive/hive.dart';
import '../../backend/models/meal.dart';
import '../core/api_client.dart';
import '../core/storage/auth_storage.dart';

class MealRepository {
  MealRepository(this._settings, this._authStorage);
  final Box<dynamic> _settings;
  final AuthStorage _authStorage;

  Future<List<MealModel>> fetchForPg(String pgId) async {
    try {
      final client = ApiClient(authStorage: _authStorage);
      final data = await client.get('/api/meals/meals/?pg=$pgId');
      final list = (data['results'] ?? data['value'] ?? <dynamic>[]) as List<dynamic>;
      final result = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final typeStr = (m['meal_type'] ?? 'breakfast').toString().toLowerCase();
        return MealModel(
          id: m['id']?.toString() ?? '',
          tenantId: m['tenant']?.toString() ?? '',
          date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
          mealType: typeStr.contains('lunch')
              ? MealType.lunch
              : typeStr.contains('dinner')
                  ? MealType.dinner
                  : MealType.breakfast,
          attended: m['attended'] == true || m['attended'] == 'true' || m['attended'] == '1',
          isExtra: m['is_extra'] == true || m['is_extra'] == 'true' || m['is_extra'] == '1',
          extraCharge: double.tryParse(m['extra_charge']?.toString() ?? '0') ?? 0,
          pgId: m['pg']?.toString() ?? pgId,
        );
      }).toList();
      await _settings.put('cache.meals_$pgId', list);
      return result;
    } catch (_) {
      final cached = _settings.get('cache.meals_$pgId');
      if (cached is List) {
        return cached.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final typeStr = (m['meal_type'] ?? 'breakfast').toString().toLowerCase();
          return MealModel(
            id: m['id']?.toString() ?? '',
            tenantId: m['tenant']?.toString() ?? '',
            date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
            mealType: typeStr.contains('lunch')
                ? MealType.lunch
                : typeStr.contains('dinner')
                    ? MealType.dinner
                    : MealType.breakfast,
            attended: m['attended'] == true || m['attended'] == 'true' || m['attended'] == '1',
            isExtra: m['is_extra'] == true || m['is_extra'] == 'true' || m['is_extra'] == '1',
            extraCharge: double.tryParse(m['extra_charge']?.toString() ?? '0') ?? 0,
            pgId: m['pg']?.toString() ?? pgId,
          );
        }).toList();
      }
      return [];
    }
  }

  Future<MealModel> createMeal(MealModel meal) async {
    final client = ApiClient(authStorage: _authStorage);
    final typeStr = meal.mealType == MealType.lunch
        ? 'lunch'
        : meal.mealType == MealType.dinner
            ? 'dinner'
            : 'breakfast';
    final body = {
      'tenant': meal.tenantId,
      'date': meal.date.toIso8601String().split('T').first,
      'meal_type': typeStr,
      'attended': meal.attended,
      'is_extra': meal.isExtra,
      if (meal.extraCharge != null) 'extra_charge': meal.extraCharge,
      'pg': meal.pgId,
    };
    final data = await client.post('/api/meals/meals/', body);
    final typeStrResp = (data['meal_type'] ?? 'breakfast').toString().toLowerCase();
    return MealModel(
      id: data['id']?.toString() ?? meal.id,
      tenantId: data['tenant']?.toString() ?? meal.tenantId,
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? meal.date,
      mealType: typeStrResp.contains('lunch')
          ? MealType.lunch
          : typeStrResp.contains('dinner')
              ? MealType.dinner
              : MealType.breakfast,
      attended: data['attended'] == true || data['attended'] == 'true' || data['attended'] == '1',
      isExtra: data['is_extra'] == true || data['is_extra'] == 'true' || data['is_extra'] == '1',
      extraCharge: double.tryParse(data['extra_charge']?.toString() ?? '0') ?? meal.extraCharge ?? 0,
      pgId: data['pg']?.toString() ?? meal.pgId,
    );
  }
}


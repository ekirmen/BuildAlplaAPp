import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/industrial_data_model.dart';

class DataService {
  final SupabaseClient _supabase;

  DataService(this._supabase);

  Future<List<IndustrialDataModel>> loadData() async {
    try {
      final response = await _supabase
          .from('industrial_data')
          .select()
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => IndustrialDataModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<(bool, int)> insertData(List<IndustrialDataModel> dataList) async {
    try {
      final records = dataList.map((data) => data.toJson()).toList();
      await _supabase.from('industrial_data').insert(records);
      return (true, records.length);
    } catch (e) {
      return (false, 0);
    }
  }

  Future<bool> saveAllData(List<IndustrialDataModel> dataList) async {
    try {
      // Delete all existing data
      await _supabase.from('industrial_data').delete().neq('id', 0);

      // Insert new data in chunks
      const chunkSize = 1000;
      final records = dataList.map((data) => data.toJson()).toList();

      for (var i = 0; i < records.length; i += chunkSize) {
        final end = (i + chunkSize < records.length) ? i + chunkSize : records.length;
        final chunk = records.sublist(i, end);
        await _supabase.from('industrial_data').insert(chunk);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAllData() async {
    try {
      await _supabase.from('industrial_data').delete().neq('id', 0);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOperatorGroups(Map<String, String> operatorGroupMap) async {
    try {
      for (final entry in operatorGroupMap.entries) {
        await _supabase
            .from('industrial_data')
            .update({'grupo': entry.value})
            .eq('operador', entry.key);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Analytics methods
  Map<String, double> getTotalMinutesByLine(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.linea] = (result[item.linea] ?? 0) + item.minutos;
    }
    return result;
  }

  Map<String, double> getTotalMinutesByOperator(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.operador] = (result[item.operador] ?? 0) + item.minutos;
    }
    return result;
  }

  Map<String, double> getTotalMinutesByGroup(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.grupo] = (result[item.grupo] ?? 0) + item.minutos;
    }
    return result;
  }

  Map<String, double> getTotalMinutesByPeriod(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.periodo] = (result[item.periodo] ?? 0) + item.minutos;
    }
    return result;
  }

  String getCriticalLine(List<IndustrialDataModel> data) {
    final lineMinutes = getTotalMinutesByLine(data);
    if (lineMinutes.isEmpty) return 'N/A';
    
    return lineMinutes.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<IndustrialDataModel> filterByPeriod(
    List<IndustrialDataModel> data,
    String period,
  ) {
    if (period == 'Todos') return data;
    return data.where((item) => item.periodo == period).toList();
  }

  List<IndustrialDataModel> filterByLine(
    List<IndustrialDataModel> data,
    String line,
  ) {
    if (line == 'Todas') return data;
    return data.where((item) => item.linea == line).toList();
  }

  List<String> getUniquePeriods(List<IndustrialDataModel> data) {
    final periods = data.map((item) => item.periodo).toSet().toList();
    periods.sort((a, b) => b.compareTo(a)); // Descending
    return periods;
  }

  List<String> getUniqueLines(List<IndustrialDataModel> data) {
    final lines = data.map((item) => item.linea).toSet().toList();
    lines.sort();
    return lines;
  }
}

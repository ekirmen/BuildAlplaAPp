import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config_model.dart';

class ConfigService {
  final SupabaseClient _supabase;

  ConfigService(this._supabase);

  Future<AppConfigModel> loadConfig() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select()
          .timeout(const Duration(seconds: 10));

      if (response.isEmpty) {
        return AppConfigModel.defaults();
      }

      final Map<String, dynamic> configMap = {};
      for (final row in response) {
        configMap[row['key']] = row['value'];
      }

      return AppConfigModel.fromJson(configMap);
    } catch (e) {
      return AppConfigModel.defaults();
    }
  }

  Future<bool> saveConfig(AppConfigModel config) async {
    try {
      final configJson = config.toJson();

      for (final entry in configJson.entries) {
        await _supabase.from('app_config').upsert({
          'key': entry.key,
          'value': entry.value,
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveConfigItem(String key, dynamic value) async {
    try {
      await _supabase.from('app_config').upsert({
        'key': key,
        'value': value,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

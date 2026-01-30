import 'package:flutter/foundation.dart';
import '../models/app_config_model.dart';
import '../services/config_service.dart';

class ConfigProvider with ChangeNotifier {
  final ConfigService _configService;

  AppConfigModel _config = AppConfigModel.defaults();
  bool _isLoading = false;

  ConfigProvider(this._configService);

  AppConfigModel get config => _config;
  bool get isLoading => _isLoading;

  List<String> get validLines => _config.validLines;
  List<String> get validShifts => _config.validShifts;
  List<String> get validProducts => _config.validProducts;
  List<String> get operatorNames => _config.operatorNames;
  List<OperatorConfig> get validOperators => _config.validOperators;

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    _config = await _configService.loadConfig();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveConfig(AppConfigModel newConfig) async {
    final success = await _configService.saveConfig(newConfig);
    if (success) {
      _config = newConfig;
      notifyListeners();
    }
    return success;
  }

  String getOperatorGroup(String operatorName) {
    return _config.getOperatorGroup(operatorName);
  }

  void updateLocalConfig(AppConfigModel newConfig) {
    _config = newConfig;
    notifyListeners();
  }
}

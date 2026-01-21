import 'package:flutter/foundation.dart';
import '../models/industrial_data_model.dart';
import '../services/data_service.dart';

class DataProvider with ChangeNotifier {
  final DataService _dataService;

  List<IndustrialDataModel> _allData = [];
  bool _isLoading = false;
  String? _errorMessage;

  DataProvider(this._dataService);

  List<IndustrialDataModel> get allData => _allData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allData = await _dataService.loadData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addData(IndustrialDataModel data) async {
    final (success, count) = await _dataService.insertData([data]);
    if (success) {
      await loadData();
    }
    return success;
  }

  Future<bool> addMultipleData(List<IndustrialDataModel> dataList) async {
    final (success, count) = await _dataService.insertData(dataList);
    if (success) {
      await loadData();
    }
    return success;
  }

  Future<bool> saveAllData(List<IndustrialDataModel> dataList) async {
    final success = await _dataService.saveAllData(dataList);
    if (success) {
      await loadData();
    }
    return success;
  }

  Future<bool> deleteAllData() async {
    final success = await _dataService.deleteAllData();
    if (success) {
      _allData = [];
      notifyListeners();
    }
    return success;
  }

  // Analytics getters
  Map<String, double> getTotalMinutesByLine() {
    return _dataService.getTotalMinutesByLine(_allData);
  }

  Map<String, double> getTotalMinutesByOperator() {
    return _dataService.getTotalMinutesByOperator(_allData);
  }

  Map<String, double> getTotalMinutesByGroup() {
    return _dataService.getTotalMinutesByGroup(_allData);
  }

  String getCriticalLine() {
    return _dataService.getCriticalLine(_allData);
  }

  List<String> getUniquePeriods() {
    return _dataService.getUniquePeriods(_allData);
  }

  List<String> getUniqueLines() {
    return _dataService.getUniqueLines(_allData);
  }

  List<IndustrialDataModel> filterByPeriod(String period) {
    return _dataService.filterByPeriod(_allData, period);
  }

  List<IndustrialDataModel> filterByLine(String line) {
    return _dataService.filterByLine(_allData, line);
  }

  double getTotalMinutes([List<IndustrialDataModel>? data]) {
    final dataToUse = data ?? _allData;
    return dataToUse.fold(0.0, (sum, item) => sum + item.minutos);
  }

  double getTotalHours([List<IndustrialDataModel>? data]) {
    return getTotalMinutes(data) / 60;
  }
}

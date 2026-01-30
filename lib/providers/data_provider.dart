import 'package:flutter/foundation.dart';
import '../models/industrial_data_model.dart';
import '../services/data_service.dart';
import '../services/log_service.dart';

class DataProvider with ChangeNotifier {
  final DataService _dataService;
  
  List<IndustrialDataModel> _allData = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const int _pageSize = 100;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  DataProvider(this._dataService);

  List<IndustrialDataModel> get allData => _allData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadData({bool refresh = true}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _allData.clear();
    }

    LogService().log('DataProvider: Loading data (Page $_currentPage, Refresh: $refresh)');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      
      final newData = await _dataService.loadData(from: from, to: to);
      LogService().log('DataProvider: Loaded ${newData.length} records');
      
      if (refresh) {
        _allData = newData;
      } else {
        _allData.addAll(newData);
      }

      if (newData.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      LogService().recordError(e, stack, reason: 'Error loading data');
      _errorMessage = 'Error cargando datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    if (_isLoading) return;

    LogService().log('DataProvider: Loading ALL data');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allData = await _dataService.loadAllData();
      LogService().log('DataProvider: Loaded ALL ${allData.length} records');
      
      _allData = allData;
      _hasMore = false; // We have everything
      _currentPage = (allData.length / _pageSize).ceil(); // Approximate

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      LogService().recordError(e, stack, reason: 'Error loading ALL data');
      _errorMessage = 'Error cargando todos los datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      
      final newData = await _dataService.loadData(from: from, to: to);
      _allData.addAll(newData);

      if (newData.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      // Si falla loading more, solo mostramos en consola, no bloqueamos UI
      print('Error loading more: $e');
      _isLoadingMore = false;
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

  Future<bool> updateData(IndustrialDataModel data) async {
    final success = await _dataService.updateData(data);
    if (success) {
      // Update local list
      final index = _allData.indexWhere((element) => element.id == data.id);
      if (index != -1) {
        _allData[index] = data;
        notifyListeners();
      } else {
        await loadData(); // Reload if not found (shouldn't happen)
      }
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

  List<IndustrialDataModel> getFilteredData({String? period, String? line}) {
    var data = _allData;
    if (period != null && period != 'Todos') {
      data = _dataService.filterByPeriod(data, period);
    }
    if (line != null && line != 'Todas') {
      data = _dataService.filterByLine(data, line);
    }
    return data;
  }

  List<String> getAvailablePeriods({String? lineFilter}) {
    var data = _allData;
    if (lineFilter != null && lineFilter != 'Todas') {
      data = _dataService.filterByLine(data, lineFilter);
    }
    return _dataService.getUniquePeriods(data);
  }

  List<String> getAvailableLines({String? periodFilter}) {
    var data = _allData;
    if (periodFilter != null && periodFilter != 'Todos') {
      data = _dataService.filterByPeriod(data, periodFilter);
    }
    return _dataService.getUniqueLines(data);
  }

  double getTotalMinutes([List<IndustrialDataModel>? data]) {
    final dataToUse = data ?? _allData;
    return dataToUse.fold(0.0, (sum, item) => sum + item.minutos);
  }

  double getTotalHours([List<IndustrialDataModel>? data]) {
    return getTotalMinutes(data) / 60;
  }
}

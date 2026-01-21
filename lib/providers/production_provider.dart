import 'package:flutter/material.dart';
import '../models/production_models.dart';
import '../services/production_service.dart';

class ProductionProvider extends ChangeNotifier {
  final ProductionService _service;

  List<RegistroProduccionModel> _registros = [];
  List<VelocidadConfigModel> _velocidades = [];
  bool _isLoading = false;
  String? _error;

  List<RegistroProduccionModel> get registros => _registros;
  List<VelocidadConfigModel> get velocidades => _velocidades;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductionProvider(this._service);

  Future<void> loadVelocidades() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _velocidades = await _service.getVelocidades();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProduccion(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _registros = await _service.getProduccionByDate(date);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProduccion(RegistroProduccionModel registro) async {
    try {
      await _service.saveProduccion(registro);
      // Recargar lista si es la misma fecha
      await loadProduccion(registro.fecha);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteProduccion(int id, DateTime currentDate) async {
    try {
      await _service.deleteProduccion(id);
      await loadProduccion(currentDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Obtener velocidad nominal para UI
  double getVelocidadNominal(String linea, String producto) {
    try {
      final config = _velocidades.firstWhere(
        (v) => v.linea == linea && v.producto == producto,
      );
      return config.velocidadNominal;
    } catch (e) {
      return 0.0;
    }
  }
}

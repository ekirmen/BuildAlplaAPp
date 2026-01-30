import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/production_models.dart';

class ProductionService {
  final SupabaseClient _supabase;

  ProductionService(this._supabase);

  // --- VELOCIDADES ---

  Future<List<VelocidadConfigModel>> getVelocidades() async {
    try {
      final response = await _supabase
          .from('config_velocidades')
          .select()
          .order('linea')
          .timeout(const Duration(seconds: 10));
      
      return (response as List)
          .map((json) => VelocidadConfigModel.fromJson(json))
          .toList();
    } catch (e) {
      // Si la tabla no existe o error, retorna lista vacía
      print('Error obteniendo velocidades: $e');
      return [];
    }
  }

  Future<void> saveVelocidad(VelocidadConfigModel velocidad) async {
    await _supabase.from('config_velocidades').upsert(velocidad.toJson());
  }
  
  // Buscar velocidad específica
  Future<double> getVelocidadNominal(String linea, String producto) async {
    try {
      final response = await _supabase
          .from('config_velocidades')
          .select('velocidad_nominal')
          .eq('linea', linea)
          .eq('producto', producto)
          .maybeSingle();

      if (response != null) {
        return (response['velocidad_nominal'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // --- PRODUCCIÓN ---

  Future<List<RegistroProduccionModel>> getProduccionByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('registro_produccion')
          .select()
          .eq('fecha', dateStr)
          .order('created_at');

      return (response as List)
          .map((json) => RegistroProduccionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error cargando producción: $e');
      return [];
    }
  }

  Future<void> saveProduccion(RegistroProduccionModel produccion) async {
    // Buscar si ya existe velocidad para guardar snapshot
    double vel = produccion.velocidadHora;
    if (vel == 0) {
      vel = await getVelocidadNominal(produccion.linea, produccion.producto);
    }
    
    // Crear mapa y actualizar velocidad si es necesario
    final data = produccion.toJson();
    if (vel > 0) {
      data['velocidad_hora'] = vel;
    }

    await _supabase.from('registro_produccion').upsert(data);
  }
  
  Future<void> deleteProduccion(int id) async {
    await _supabase.from('registro_produccion').delete().eq('id', id);
  }
}

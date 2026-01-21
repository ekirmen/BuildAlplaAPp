class VelocidadConfigModel {
  final int? id;
  final String linea;
  final String producto;
  final double velocidadNominal;

  VelocidadConfigModel({
    this.id,
    required this.linea,
    required this.producto,
    required this.velocidadNominal,
  });

  factory VelocidadConfigModel.fromJson(Map<String, dynamic> json) {
    return VelocidadConfigModel(
      id: json['id'],
      linea: json['linea'] ?? '',
      producto: json['producto'] ?? '',
      velocidadNominal: (json['velocidad_nominal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'linea': linea,
      'producto': producto,
      'velocidad_nominal': velocidadNominal,
    };
  }
}

class RegistroProduccionModel {
  final int? id;
  final DateTime fecha;
  final String turno;
  final String linea;
  final String producto;
  final double horasTurno;
  final double produccionReal;
  final String operador;
  final String grupo;
  final double velocidadHora; // Calculado o guardado snapshot

  RegistroProduccionModel({
    this.id,
    required this.fecha,
    required this.turno,
    required this.linea,
    required this.producto,
    this.horasTurno = 8.0,
    required this.produccionReal,
    required this.operador,
    this.grupo = 'Sin Grupo',
    this.velocidadHora = 0.0,
  });

  factory RegistroProduccionModel.fromJson(Map<String, dynamic> json) {
    return RegistroProduccionModel(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      turno: json['turno'] ?? '',
      linea: json['linea'] ?? '',
      producto: json['producto'] ?? '',
      horasTurno: (json['horas_turno'] as num?)?.toDouble() ?? 8.0,
      produccionReal: (json['produccion_real'] as num?)?.toDouble() ?? 0.0,
      operador: json['operador'] ?? '',
      grupo: json['grupo'] ?? 'Sin Grupo',
      velocidadHora: (json['velocidad_hora'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'turno': turno,
      'linea': linea,
      'producto': producto,
      'horas_turno': horasTurno,
      'produccion_real': produccionReal,
      'operador': operador,
      'grupo': grupo,
      'velocidad_hora': velocidadHora,
    };
  }
  
  // Cálculo de Eficiencia (OEE Performance simplificado)
  // Producción Esperada = Velocidad Nominal * Horas
  // Eficiencia = Producción Real / Producción Esperada
  double calcularEficiencia(double velocidadNominal) {
    if (velocidadNominal <= 0 || horasTurno <= 0) return 0.0;
    final produccionEsperada = velocidadNominal * horasTurno;
    return (produccionReal / produccionEsperada) * 100;
  }
}

class IndustrialDataModel {
  final String? id;
  final DateTime fecha;
  final String turno;
  final String linea;
  final String producto;
  final double minutos;
  final String causa;
  final String operador;
  final String grupo;

  IndustrialDataModel({
    this.id,
    required this.fecha,
    required this.turno,
    required this.linea,
    required this.producto,
    required this.minutos,
    required this.causa,
    required this.operador,
    required this.grupo,
  });

  factory IndustrialDataModel.fromJson(Map<String, dynamic> json) {
    return IndustrialDataModel(
      id: json['id']?.toString(),
      fecha: DateTime.parse(json['fecha']),
      turno: json['turno'] ?? '',
      linea: json['linea'] ?? '',
      producto: json['producto'] ?? '',
      minutos: (json['minutos'] ?? 0).toDouble(),
      causa: json['causa'] ?? '',
      operador: json['operador'] ?? '',
      grupo: json['grupo'] ?? 'Sin Grupo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'turno': turno,
      'linea': linea,
      'producto': producto,
      'minutos': minutos,
      'causa': causa,
      'operador': operador,
      'grupo': grupo,
    };
  }

  String get periodo => '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
  
  double get horas => minutos / 60;
}

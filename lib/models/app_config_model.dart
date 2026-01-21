class AppConfigModel {
  final List<String> validLines;
  final List<String> validShifts;
  final List<OperatorConfig> validOperators;
  final List<String> validProducts;

  AppConfigModel({
    required this.validLines,
    required this.validShifts,
    required this.validOperators,
    required this.validProducts,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      validLines: List<String>.from(json['valid_lines'] ?? []),
      validShifts: List<String>.from(json['valid_shifts'] ?? []),
      validOperators: (json['valid_operators'] as List?)
              ?.map((e) => OperatorConfig.fromJson(e))
              .toList() ??
          [],
      validProducts: List<String>.from(json['valid_products'] ?? []),
    );
  }

  factory AppConfigModel.defaults() {
    return AppConfigModel(
      validLines: ['L-7', 'L-8', 'L-17', 'Empaque'],
      validShifts: ['Día', 'Noche'],
      validOperators: [
        OperatorConfig(operador: 'Miguel Fuenmayor', grupo: 'A'),
        OperatorConfig(operador: 'José Manuel Gutiérrez', grupo: 'B'),
        OperatorConfig(operador: 'Luciano Truisi', grupo: 'A'),
        OperatorConfig(operador: 'José Chourio', grupo: 'B'),
      ],
      validProducts: ['Botella 500ml', 'Envase 1L'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid_lines': validLines,
      'valid_shifts': validShifts,
      'valid_operators': validOperators.map((e) => e.toJson()).toList(),
      'valid_products': validProducts,
    };
  }

  List<String> get operatorNames =>
      validOperators.map((e) => e.operador).toList();

  String getOperatorGroup(String operatorName) {
    final operator = validOperators.firstWhere(
      (op) => op.operador == operatorName,
      orElse: () => OperatorConfig(operador: operatorName, grupo: 'Sin Grupo'),
    );
    return operator.grupo;
  }
}

class OperatorConfig {
  final String operador;
  final String grupo;

  OperatorConfig({
    required this.operador,
    required this.grupo,
  });

  factory OperatorConfig.fromJson(dynamic json) {
    if (json is String) {
      return OperatorConfig(operador: json, grupo: 'Sin Grupo');
    }
    return OperatorConfig(
      operador: json['Operador'] ?? json['operador'] ?? '',
      grupo: json['Grupo'] ?? json['grupo'] ?? 'Sin Grupo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Operador': operador,
      'Grupo': grupo,
    };
  }
}

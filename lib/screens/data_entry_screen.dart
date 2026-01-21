import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../providers/config_provider.dart';
import '../models/industrial_data_model.dart';
import '../services/notification_service.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedShift;
  String? _selectedLine;
  String? _selectedProduct;
  String? _selectedOperator;
  final _minutesController = TextEditingController();
  final _causaController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _minutesController.dispose();
    _causaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final configProvider = context.read<ConfigProvider>();
    final dataProvider = context.read<DataProvider>();

    final grupo = configProvider.getOperatorGroup(_selectedOperator!);

    final newData = IndustrialDataModel(
      fecha: _selectedDate,
      turno: _selectedShift!,
      linea: _selectedLine!,
      producto: _selectedProduct!,
      minutos: double.parse(_minutesController.text),
      causa: _causaController.text,
      operador: _selectedOperator!,
      grupo: grupo,
    );

    final success = await dataProvider.addData(newData);

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (success) {
      // Mostrar notificación local
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Registro Exitoso',
        body: 'Se ha registrado una parada en la línea $_selectedLine (Grupo: $grupo)',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Guardado exitosamente (Grupo: $grupo)'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _minutesController.clear();
      _causaController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedShift = null;
        _selectedLine = null;
        _selectedProduct = null;
        _selectedOperator = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al guardar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();

    if (configProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '📝 Ingreso de Datos Diario',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Date picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha del Evento',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shift
                      DropdownButtonFormField<String>(
                        value: _selectedShift,
                        decoration: InputDecoration(
                          labelText: 'Turno',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        items: configProvider.validShifts.map((shift) {
                          return DropdownMenuItem(
                            value: shift,
                            child: Text(shift),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedShift = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Seleccione un turno';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Line
                      DropdownButtonFormField<String>(
                        value: _selectedLine,
                        decoration: InputDecoration(
                          labelText: 'Línea Afectada',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.factory),
                        ),
                        items: configProvider.validLines.map((line) {
                          return DropdownMenuItem(
                            value: line,
                            child: Text(line),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLine = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Seleccione una línea';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Product
                      DropdownButtonFormField<String>(
                        value: _selectedProduct,
                        decoration: InputDecoration(
                          labelText: 'Producto',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.inventory),
                        ),
                        items: configProvider.validProducts.map((product) {
                          return DropdownMenuItem(
                            value: product,
                            child: Text(product),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProduct = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Seleccione un producto';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Operator
                      DropdownButtonFormField<String>(
                        value: _selectedOperator,
                        decoration: InputDecoration(
                          labelText: 'Operador Responsable',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        items: configProvider.operatorNames.map((operator) {
                          final grupo = configProvider.getOperatorGroup(operator);
                          return DropdownMenuItem(
                            value: operator,
                            child: Text('$operator (Grupo $grupo)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedOperator = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Seleccione un operador';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Minutes
                      TextFormField(
                        controller: _minutesController,
                        decoration: InputDecoration(
                          labelText: 'Minutos de Parada',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese los minutos';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Causa
                      TextFormField(
                        controller: _causaController,
                        decoration: InputDecoration(
                          labelText: 'Causa / Motivo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese la causa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _handleSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? 'Guardando...' : '💾 Guardar Registro',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

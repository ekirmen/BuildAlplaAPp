import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/production_provider.dart';
import '../providers/config_provider.dart';
import '../models/production_models.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadVelocidades();
      context.read<ProductionProvider>().loadProduccion(_selectedDate);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (mounted) {
        context.read<ProductionProvider>().loadProduccion(_selectedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Producción'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer2<ProductionProvider, ConfigProvider>(
        builder: (context, prodProvider, configProvider, child) {
          if (prodProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prodProvider.registros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('No hay registros de producción para esta fecha.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Cambiar Fecha'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Selector de fecha
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Producción: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ),

              // Lista de Producción
              Expanded(
                child: ListView.builder(
                  itemCount: prodProvider.registros.length,
                  itemBuilder: (context, index) {
                    final registro = prodProvider.registros[index];
                    final velNominal = prodProvider.getVelocidadNominal(
                      registro.linea, 
                      registro.producto
                    );
                    final eficiencia = registro.calcularEficiencia(velNominal);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${registro.linea} - ${registro.turno}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getColorForEficiencia(eficiencia),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${eficiencia.toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Producto: ${registro.producto}'),
                            const SizedBox(height: 4),
                            Text('Operador: ${registro.operador}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Real: ${NumberFormat('#,###').format(registro.produccionReal)} u'),
                                if(velNominal > 0)
                                  Text('Target: ${NumberFormat('#,###').format(velNominal * registro.horasTurno)} u'),
                              ],
                            ),
                            if (velNominal == 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('⚠️ Sin velocidad configurada', 
                                  style: TextStyle(color: Colors.orange, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorForEficiencia(double ef) {
    if (ef >= 90) return Colors.green;
    if (ef >= 80) return Colors.orange;
    return Colors.red;
  }

  void _showAddDialog(BuildContext context) {
    // Implementar diálogo simple para agregar
    showDialog(
      context: context,
      builder: (ctx) => _AddProductionDialog(selectedDate: _selectedDate),
    );
  }
}

class _AddProductionDialog extends StatefulWidget {
  final DateTime selectedDate;
  const _AddProductionDialog({required this.selectedDate});

  @override
  State<_AddProductionDialog> createState() => _AddProductionDialogState();
}

class _AddProductionDialogState extends State<_AddProductionDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _linea;
  String? _turno;
  String? _producto;
  String? _operador;
  final _prodController = TextEditingController();
  final _horasController = TextEditingController(text: '8');

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigProvider>();
    
    return AlertDialog(
      title: const Text('Nuevo Registro'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Línea'),
                items: config.validLines.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _linea = v),
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Turno'),
                items: config.validShifts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _turno = v),
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Producto'),
                items: config.validProducts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _producto = v),
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Operador'),
                items: config.validOperators.map((o) => DropdownMenuItem(value: o.operador, child: Text(o.operador))).toList(),
                onChanged: (v) => setState(() => _operador = v as String?),
              ),
              TextFormField(
                controller: _prodController,
                decoration: const InputDecoration(labelText: 'Producción Real'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && _linea != null && _turno != null && _producto != null && _operador != null) {
              final prod = double.tryParse(_prodController.text) ?? 0;
              final horas = double.tryParse(_horasController.text) ?? 8;
              final grupo = context.read<ConfigProvider>().getOperatorGroup(_operador!);
              
              final nuevo = RegistroProduccionModel(
                fecha: widget.selectedDate,
                turno: _turno!,
                linea: _linea!,
                producto: _producto!,
                produccionReal: prod,
                horasTurno: horas,
                operador: _operador!,
                grupo: grupo,
              );
              
              await context.read<ProductionProvider>().saveProduccion(nuevo);
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

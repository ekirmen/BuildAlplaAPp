import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/industrial_data_model.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _selectedPeriod = 'Todos';
  String _selectedLine = 'Todas';

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataProvider.allData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay datos cargados',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final periods = ['Todos', ...dataProvider.getUniquePeriods()];
    final lines = ['Todas', ...dataProvider.getUniqueLines()];

    var filteredData = dataProvider.allData;
    if (_selectedPeriod != 'Todos') {
      filteredData = dataProvider.filterByPeriod(_selectedPeriod);
    }
    if (_selectedLine != 'Todas') {
      filteredData = dataProvider.filterByLine(_selectedLine);
    }

    return RefreshIndicator(
      onRefresh: () => dataProvider.loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filters
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Período',
                  value: _selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FilterDropdown(
                  label: 'Línea',
                  value: _selectedLine,
                  items: lines,
                  onChanged: (value) {
                    setState(() {
                      _selectedLine = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPIs
          _buildKPIs(filteredData, dataProvider),
          const SizedBox(height: 24),

          // Pie Chart - Distribution by Line
          _buildPieChartCard(
            title: 'Distribución por Línea',
            data: _getLineData(filteredData),
          ),
          const SizedBox(height: 24),

          // Bar Chart - Minutes by Group
          _buildBarChartCard(
            title: 'Minutos Totales por Grupo',
            data: _getGroupData(filteredData),
          ),
          const SizedBox(height: 24),

          // Bar Chart - Minutes by Operator
          _buildBarChartCard(
            title: 'Minutos por Operador',
            data: _getOperatorData(filteredData),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs(List<IndustrialDataModel> data, DataProvider provider) {
    final totalMinutes = provider.getTotalMinutes(data);
    final totalHours = provider.getTotalHours(data);
    final criticalLine = _getCriticalLine(data);

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: 'Tiempo Total',
            value: NumberFormat('#,##0').format(totalMinutes),
            unit: 'min',
            icon: Icons.timer,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KPICard(
            title: 'Horas Perdidas',
            value: NumberFormat('#,##0.0').format(totalHours),
            unit: 'hrs',
            icon: Icons.access_time,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KPICard(
            title: 'Línea Crítica',
            value: criticalLine,
            unit: '',
            icon: Icons.warning,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard({
    required String title,
    required Map<String, double> data,
  }) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final sections = data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final total = data.values.reduce((a, b) => a + b);
      final percentage = (item.value / total * 100);

      return PieChartSectionData(
        value: item.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 100,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.key,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard({
    required String title,
    required Map<String, double> data,
  }) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = sortedData.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedData.map((entry) {
              final percentage = (entry.value / maxValue);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Text(
                          NumberFormat('#,##0').format(entry.value),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getLineData(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.linea] = (result[item.linea] ?? 0) + item.minutos;
    }
    return result;
  }

  Map<String, double> _getGroupData(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.grupo] = (result[item.grupo] ?? 0) + item.minutos;
    }
    return result;
  }

  Map<String, double> _getOperatorData(List<IndustrialDataModel> data) {
    final Map<String, double> result = {};
    for (final item in data) {
      result[item.operador] = (result[item.operador] ?? 0) + item.minutos;
    }
    return result;
  }

  String _getCriticalLine(List<IndustrialDataModel> data) {
    final lineData = _getLineData(data);
    if (lineData.isEmpty) return 'N/A';
    
    return lineData.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/industrial_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/skeleton_loader.dart';
import '../services/export_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _selectedPeriod = 'Todos';
  String _selectedLine = 'Todas';
  final ScrollController _scrollController = ScrollController();
  
  Map<String, bool> _chartOrientations = {
    'Minutos Totales por Grupo': false,
    'Minutos por Operador': true,
    'Distribución por Línea': true, // true = Pie, false = Bar
  };

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      final provider = context.read<DataProvider>();
      // Always ensure we have ALL data for analytics
      if (provider.allData.isEmpty || provider.hasMore) {
        provider.loadAll();
      }
    });
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedPeriod = prefs.getString('filter_period') ?? 'Todos';
      _selectedLine = prefs.getString('filter_line') ?? 'Todas';
      
      // Load chart orientations
      _chartOrientations['Minutos Totales por Grupo'] = prefs.getBool('chart_orientation_group') ?? false;
      _chartOrientations['Minutos por Operador'] = prefs.getBool('chart_orientation_operator') ?? true;
      _chartOrientations['Distribución por Línea'] = prefs.getBool('chart_orientation_distribution') ?? true;
    });
  }

  Future<void> _toggleChartOrientation(String title, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !(_chartOrientations[title] ?? false);
    setState(() {
      _chartOrientations[title] = newValue;
    });
    await prefs.setBool(key, newValue);
  }

  Future<void> _saveFilter(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<DataProvider>();
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMore();
      }
    }
  }

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        // Reset period when using custom date range
        _selectedPeriod = 'Rango Fechas'; 
      });
      // Trigger reload with date filters?
      // For now, client side filtering or need to update provider to filter by date range
    }
  }
  
  void _showExportOptions(List<IndustrialDataModel> data) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar a CSV (Excel)'),
              onTap: () {
                Navigator.pop(ctx);
                ExportService().exportToCSV(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar a PDF'),
              onTap: () {
                Navigator.pop(ctx);
                ExportService().exportToPDF(data);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    if (dataProvider.isLoading && dataProvider.allData.isEmpty) {
      return const DashboardSkeleton();
    }
    
    // ... Error state ...
    if (dataProvider.errorMessage != null && dataProvider.allData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error cargando datos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dataProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => dataProvider.loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    // ... Empty state ...
    if (dataProvider.allData.isEmpty && !dataProvider.isLoading) {
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
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => dataProvider.loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ],
        ),
      );
    }

    final periods = ['Todos', 'Rango Fechas', ...dataProvider.getAvailablePeriods(lineFilter: _selectedLine)];
    final lines = ['Todas', ...dataProvider.getAvailableLines(periodFilter: _selectedPeriod)];

    // Apply filters locally (including date range)
    var filteredData = dataProvider.getFilteredData(
      period: _selectedPeriod == 'Rango Fechas' ? 'Todos' : _selectedPeriod,
      line: _selectedLine,
    );
    
    // Custom Date Range Filter
    if (_selectedPeriod == 'Rango Fechas' && _startDate != null && _endDate != null) {
      filteredData = filteredData.where((item) {
        return item.fecha.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
               item.fecha.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () => dataProvider.loadData(refresh: true),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen General',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar Reporte',
                onPressed: () => _showExportOptions(filteredData),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Período',
                  value: _selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    if (value == 'Rango Fechas') {
                       _pickDateRange();
                    } else {
                       setState(() {
                         _selectedPeriod = value!;
                          _startDate = null; 
                          _endDate = null;
                       });
                       _saveFilter('filter_period', value!);
                    }
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
                    _saveFilter('filter_line', value!);
                  },
                ),
              ),
            ],
          ),
          
          if (_selectedPeriod == 'Rango Fechas' && _startDate != null)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Chip(
                 label: Text('${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'),
                 onDeleted: () {
                   setState(() {
                     _selectedPeriod = 'Todos';
                     _startDate = null;
                     _endDate = null;
                   });
                 },
               ),
             ),
             
          const SizedBox(height: 24),

          // KPIs
          _buildKPIs(filteredData, dataProvider),
          const SizedBox(height: 24),

          // Distribution Chart
          _buildDistributionChartCard(
            title: 'Distribución por Línea',
            data: _getLineData(filteredData),
            isPie: _chartOrientations['Distribución por Línea'] ?? true,
            onToggle: () => _toggleChartOrientation('Distribución por Línea', 'chart_orientation_distribution'),
          ),
          const SizedBox(height: 24),

          // Bar Chart Group
          _buildBarChartCard(
            title: 'Minutos Totales por Grupo',
            data: _getGroupData(filteredData),
            isVertical: _chartOrientations['Minutos Totales por Grupo'] ?? false,
            onToggle: () => _toggleChartOrientation('Minutos Totales por Grupo', 'chart_orientation_group'),
          ),
          const SizedBox(height: 24),

          // Bar Chart Operator
          _buildBarChartCard(
            title: 'Minutos por Operador',
            data: _getOperatorData(filteredData),
            isVertical: _chartOrientations['Minutos por Operador'] ?? true,
            onToggle: () => _toggleChartOrientation('Minutos por Operador', 'chart_orientation_operator'),
          ),
          
          if (dataProvider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            
           const SizedBox(height: 40),
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

  Widget _buildDistributionChartCard({
    required String title,
    required Map<String, double> data,
    required bool isPie,
    required VoidCallback onToggle,
  }) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(isPie ? Icons.bar_chart : Icons.pie_chart),
                onPressed: onToggle,
                tooltip: 'Cambiar gráfico',
              ),
            ],
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

    if (!isPie) {
       // Bar Chart implementation for distribution
      final sortedData = data.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topData = sortedData.take(10).toList();
      final maxValue = sortedData.first.value;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.pie_chart), 
                    onPressed: onToggle,
                    tooltip: 'Ver como pastel',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${topData[group.x.toInt()].key}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: NumberFormat('#,##0').format(rod.toY),
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                             if (index < 0 || index >= topData.length) return const SizedBox();
                             String name = topData[index].key.split(' ').first;
                             if(name.length > 4) name = '${name.substring(0, 3)}.';
                             
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: topData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: colors[entry.key % colors.length], // Use same colors as pie
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: onToggle,
                  tooltip: 'Ver como barras',
                ),
              ],
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
    required bool isVertical,
    required VoidCallback onToggle,
  }) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(isVertical ? Icons.view_column : Icons.view_list),
                onPressed: onToggle,
                tooltip: 'Cambiar vista',
              ),
            ],
          ),
        ),
      );
    }

    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topData = sortedData.take(10).toList();
    final maxValue = sortedData.first.value;

    if (isVertical) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.view_list), // Icon to switch to horizontal
                    onPressed: onToggle,
                    tooltip: 'Cambiar a lista',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${topData[group.x.toInt()].key}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: NumberFormat('#,##0').format(rod.toY),
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                             if (index < 0 || index >= topData.length) return const SizedBox();
                             // Truncate name for axis
                             String name = topData[index].key.split(' ').first;
                             if(name.length > 4) name = '${name.substring(0, 3)}.';
                             
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Hide Y axis for cleaner look
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: topData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: Colors.blue.shade400,
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: Colors.grey.shade100,
                            ), 
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart), // Icon to switch to vertical
                  onPressed: onToggle,
                  tooltip: 'Cambiar a gráfico',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topData.map((entry) {
              final percentage = (entry.value / maxValue);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/industrial_data_model.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String? _period1;
  String? _period2;

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final periods = dataProvider.getUniquePeriods();

    if (periods.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Se necesitan al menos 2 meses para comparar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    _period1 ??= periods.first;
    _period2 ??= periods.last;

    final data1 = dataProvider.filterByPeriod(_period1!);
    final data2 = dataProvider.filterByPeriod(_period2!);

    final minutes1 = dataProvider.getTotalMinutes(data1);
    final minutes2 = dataProvider.getTotalMinutes(data2);
    final delta = minutes2 - minutes1;
    final deltaPercent = minutes1 > 0 ? (delta / minutes1 * 100) : 0;
    final deltaEvents = data2.length - data1.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selectors
        Row(
          children: [
            Expanded(
              child: _PeriodSelector(
                label: '📅 Mes Base',
                value: _period1!,
                items: periods,
                onChanged: (value) {
                  setState(() {
                    _period1 = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PeriodSelector(
                label: '📅 Mes Objetivo',
                value: _period2!,
                items: periods,
                onChanged: (value) {
                  setState(() {
                    _period2 = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Comparison metrics
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Minutos $_period1',
                value: NumberFormat('#,##0').format(minutes1),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Minutos $_period2',
                value: NumberFormat('#,##0').format(minutes2),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Variación Minutos',
                value: '${delta >= 0 ? '+' : ''}${NumberFormat('#,##0').format(delta)}',
                subtitle: '${deltaPercent >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)}%',
                color: delta > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Variación Eventos',
                value: '${deltaEvents >= 0 ? '+' : ''}$deltaEvents',
                color: deltaEvents > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Line comparison
        _buildLineComparison(data1, data2),
        const SizedBox(height: 24),

        // Group comparison
        _buildGroupComparison(data1, data2),
      ],
    );
  }

  Widget _buildLineComparison(
    List<IndustrialDataModel> data1,
    List<IndustrialDataModel> data2,
  ) {
    final lines1 = _getLineData(data1);
    final lines2 = _getLineData(data2);

    final allLines = {...lines1.keys, ...lines2.keys}.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Variación por Línea',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...allLines.map((line) {
              final value1 = lines1[line] ?? 0;
              final value2 = lines2[line] ?? 0;
              final diff = value2 - value1;
              final diffPercent = value1 > 0 ? (diff / value1 * 100) : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ComparisonBar(
                            label: _period1!,
                            value: value1,
                            maxValue: value1 > value2 ? value1 : value2,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ComparisonBar(
                            label: _period2!,
                            value: value2,
                            maxValue: value1 > value2 ? value1 : value2,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: diff > 0 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${diff >= 0 ? '+' : ''}${NumberFormat('#,##0').format(diff)} (${diffPercent >= 0 ? '+' : ''}${diffPercent.toStringAsFixed(1)}%)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: diff > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildGroupComparison(
    List<IndustrialDataModel> data1,
    List<IndustrialDataModel> data2,
  ) {
    final groups1 = _getGroupData(data1);
    final groups2 = _getGroupData(data2);

    if (groups1.isEmpty && groups2.isEmpty) {
      return const SizedBox.shrink();
    }

    final allGroups = {...groups1.keys, ...groups2.keys}.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Variación por Grupo',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...allGroups.map((group) {
              final value1 = groups1[group] ?? 0;
              final value2 = groups2[group] ?? 0;
              final diff = value2 - value1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Grupo $group',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        NumberFormat('#,##0').format(value1),
                        style: GoogleFonts.poppins(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        NumberFormat('#,##0').format(value2),
                        style: GoogleFonts.poppins(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${diff >= 0 ? '+' : ''}${NumberFormat('#,##0').format(diff)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: diff > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
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
}

class _PeriodSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _PeriodSelector({
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${NumberFormat('#,##0').format(value)}',
          style: GoogleFonts.poppins(fontSize: 11),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }
}

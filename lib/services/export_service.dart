import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/industrial_data_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  
  Future<void> exportToCSV(List<IndustrialDataModel> data) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Fecha',
      'Turno',
      'Línea',
      'Producto',
      'Minutos',
      'Causa',
      'Operador',
      'Grupo'
    ]);

    // Data
    for (var item in data) {
      rows.add([
        item.fecha.toString().split(' ')[0],
        item.turno,
        item.linea,
        item.producto,
        item.minutos,
        item.causa,
        item.operador,
        item.grupo,
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/reporte_alpla_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvContent);

    await Share.shareXFiles([XFile(path)], text: 'Reporte CSV de AlplaApp');
  }

  Future<void> exportToPDF(List<IndustrialDataModel> data) async {
    final pdf = pw.Document();
    
    // Split data into chunks to avoid memory issues on huge PDF
    // For simplicity, we take first 500 rows or use multi-page table
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Reporte de Paradas - Alpla Dashboard"),
            ),
            pw.Paragraph(
              text: "Generado el: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
            ),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Fecha', 'Línea', 'Min', 'Causa', 'Operador'],
                ...data.map((item) => [
                  item.fecha.toString().split(' ')[0],
                  item.linea,
                  item.minutos.toString(),
                  item.causa.length > 20 ? '${item.causa.substring(0, 17)}...' : item.causa,
                  item.operador.split(' ')[0], // Solo primer nombre para ahorrar espacio
                ])
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/reporte_alpla_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(path)], text: 'Reporte PDF de AlplaApp');
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
// import 'package:permission_handler/permission_handler.dart'; // No suele ser necesario para getApplicationDocumentsDirectory en versiones modernas, pero open_file lo maneja.

class UpdateService {
  // ⚠️ CONFIGURA AQUÍ TU REPOSITORIO DE GITHUB
  static const String githubUser = 'ekirmen';
  static const String githubRepo = 'BuildAlplaAPp';
  
  Future<void> checkForUpdates(BuildContext context, {bool showNoUpdate = false}) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> release = json.decode(response.body);
        final String tagName = release['tag_name'] ?? '';
        final String latestVersion = tagName.replaceAll('v', ''); 

        if (_isNewer(latestVersion, currentVersion)) {
          final String? downloadUrl = _getApkAssetUrl(release['assets']);
          
          if (downloadUrl != null && context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, release['body'] ?? '');
          }
        } else if (showNoUpdate && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Sin novedades (App: v$currentVersion, GitHub: v$latestVersion)')),
          );
        }
      } else {
        if (showNoUpdate && context.mounted) {
          String errorMsg = 'Error HTTP ${response.statusCode}';
          if (response.statusCode == 404) errorMsg = 'Repositorio no encontrado o privado (404)';
          if (response.statusCode == 403) errorMsg = 'Límite de API excedido (403)';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $errorMsg'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isNewer(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map(int.parse).toList();
      List<int> currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String? _getApkAssetUrl(List<dynamic>? assets) {
    if (assets == null) return null;
    for (var asset in assets) {
      if (asset['name'].toString().endsWith('.apk')) {
        return asset['browser_download_url'];
      }
    }
    return null;
  }

  void _showUpdateDialog(BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🚀 Nueva versión v$version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se ha encontrado una actualización.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Novedades:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(notes.isEmpty ? 'Mejoras generales y correcciones.' : notes, 
                       style: const TextStyle(fontSize: 12),
                       maxLines: 4, 
                       overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Actualizar Ahora'),
            onPressed: () {
              Navigator.pop(context);
              _startInAppDownload(context, url, version);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startInAppDownload(BuildContext context, String url, String version) async {
    // 1. Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false, // No cerrar tocando fuera
      builder: (context) {
        return _DownloadProgressDialog(url: url, version: version);
      },
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String version;

  const _DownloadProgressDialog({required this.url, required this.version});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Iniciando descarga...';
  String _receivedBytes = '0 MB';
  String _totalBytes = '...';
  final CancelToken _cancelToken = CancelToken();
  bool _downloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      Directory? dir = await getExternalStorageDirectory(); 
      // Fallback si no hay external (ej. en algunos emuladores o configs)
      dir ??= await getApplicationSupportDirectory();
      
      final String savePath = '${dir.path}/update_${widget.version}.apk';

      await Dio().download(
        widget.url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _receivedBytes = _formatBytes(received);
              _totalBytes = _formatBytes(total);
              _status = 'Descargando: ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloading = false;
          _status = '¡Descarga completada!';
          _progress = 1.0;
        });
        
        Navigator.pop(context); // Cerrar diálogo
        _installApk(savePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: ${e.toString()}';
          _downloading = false;
        });
        // Esperar un poco para que el usuario lea el error o agregar botón de cerrar
        debugPrint('Error descarga: $e');
        if (CancelToken.isCancel(e as dynamic)) {
           // Cancelado por usuario
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
           );
           Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _installApk(String path) async {
    debugPrint('Intentando instalar desde: $path');
    
    final file = File(path);
    if (!file.existsSync()) {
      _showErrorDialog('El archivo descargado no se encuentra en:\n$path');
      return;
    }

    // Algunos dispositivos necesitan un pequeño delay para liberar el lock del archivo
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await OpenFile.open(path, type: "application/vnd.android.package-archive");
    debugPrint('Resultado instalación: ${result.message}');
    
    if (result.type != ResultType.done) {
       _showErrorDialog('No se pudo abrir el instalador:\n${result.message}\n\nTipo: ${result.type}');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Error de Instalación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    const int kb = 1024;
    const int mb = kb * 1024;
    return (bytes / mb).toStringAsFixed(2) + " MB";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizando...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 20),
          Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          if (_downloading)
            Text('$_receivedBytes / $_totalBytes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        if (_downloading)
          TextButton(
            onPressed: () {
              _cancelToken.cancel();
              Navigator.pop(context);
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

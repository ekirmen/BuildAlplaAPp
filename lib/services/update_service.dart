import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // ⚠️ CONFIGURA AQUÍ TU REPOSITORIO DE GITHUB
  static const String githubUser = 'ekirmen';
  static const String githubRepo = 'BuildAlplaAPp';
  
  // Ejemplo: 'JuanPerez', 'AlplaAppRepo'

  Future<void> checkForUpdates(BuildContext context, {bool showNoUpdate = false}) async {
    if (githubUser == 'TU_USUARIO_GITHUB' || githubRepo == 'TU_REPOSITORIO_GITHUB') {
      if (showNoUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Configura el repositorio de GitHub en update_service.dart')),
        );
      }
      return;
    }

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> release = json.decode(response.body);
        final String tagName = release['tag_name'] ?? '';
        final String latestVersion = tagName.replaceAll('v', ''); // Asumiendo formato "v1.0.0"

        if (_isNewer(latestVersion, currentVersion)) {
          final String? downloadUrl = _getApkAssetUrl(release['assets']);
          
          if (downloadUrl != null && context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, release['body'] ?? '');
          }
        } else if (showNoUpdate && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Ya tienes la última versión')),
          );
        }
      }
    } catch (e) {
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error buscando actualizaciones: $e')),
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
      // Si son iguales, no es nuevo.
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
      builder: (context) => AlertDialog(
        title: Text('🚀 Nueva versión disponible: $version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se ha encontrado una actualización. ¿Deseas descargarla?'),
            const SizedBox(height: 10),
            const Text('Novedades:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(notes, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Después'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(url);
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }
}

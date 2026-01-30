import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/config_provider.dart';
import '../providers/production_provider.dart';
import 'overview_screen.dart';
import 'comparison_screen.dart';
import 'data_entry_screen.dart';
import 'production_screen.dart';
import 'admin_screen.dart';
import '../widgets/settings_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/log_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtimeSubscription();
    _loadVersion();
    
    // Verificar actualizaciones automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${info.version}';
    });
  }
  
  void _setupRealtimeSubscription() {
    Supabase.instance.client
        .channel('public:industrial_data')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'industrial_data',
          callback: (payload) {
             final newRecord = payload.newRecord;
             final linea = newRecord['linea'] ?? 'Línea desconocida';
             final causa = newRecord['causa'] ?? 'Sin causa';
             final minutos = newRecord['minutos'] ?? 0;
             
             NotificationService().showNotification(
               id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
               title: '¡Nuevo Dato de Producción!',
               body: 'Línea $linea: $causa ($minutos min)',
             );
          },
        )
        .subscribe();
  }

  Future<void> _loadInitialData() async {
    final dataProvider = context.read<DataProvider>();
    final configProvider = context.read<ConfigProvider>();
    final productionProvider = context.read<ProductionProvider>();
    
    await Future.wait([
      // dataProvider.loadData() se maneja en OverviewScreen
      configProvider.loadConfig(),
      productionProvider.loadVelocidades(),
    ]);
  }

  List<_NavigationItem> _getNavigationItems(bool isAdmin, bool canEdit) {
    var items = <_NavigationItem>[
      const _NavigationItem(
        icon: Icons.dashboard,
        label: 'General',
        index: 0,
      ),
      const _NavigationItem(
        icon: Icons.compare_arrows,
        label: 'Comparar',
        index: 1,
      ),
      const _NavigationItem(
        icon: Icons.factory,
        label: 'Fábrica',
        index: 2,
      ),
    ];

    int adjustment = 3;

    if (canEdit) {
      items.add(
        _NavigationItem(
          icon: Icons.add_circle,
          label: 'Ingreso',
          index: adjustment,
        ),
      );
      adjustment++;
    }

    if (isAdmin) {
      items.add(
        _NavigationItem(
          icon: Icons.settings,
          label: 'Admin',
          index: adjustment,
        ),
      );
    }

    return items;
  }

  Widget _getScreen(int index, bool isAdmin, bool canEdit) {
    // Indices base
    if (index == 0) return const OverviewScreen();
    if (index == 1) return const ComparisonScreen();
    if (index == 2) return const ProductionScreen();

    // Indices dinámicos
    int currentIndex = 3;
    
    if (canEdit) {
      if (index == currentIndex) return const DataEntryScreen();
      currentIndex++;
    }

    if (isAdmin) {
      if (index == currentIndex) return const AdminScreen();
    }
    
    return const OverviewScreen();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = user.isAdmin;
    final canEdit = user.canEdit;
    final navigationItems = _getNavigationItems(isAdmin, canEdit);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alpla Dashboard',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_appVersion.isNotEmpty)
              Text(
                _appVersion,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Buscar Actualización',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buscando actualizaciones...')),
              );
              UpdateService().checkForUpdates(context, showNoUpdate: true);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user.role.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Está seguro que desea salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.logout();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _getScreen(_selectedIndex, isAdmin, canEdit),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                 final dataProvider = context.read<DataProvider>();
                 dataProvider.loadData(refresh: true);
              },
              child: const Icon(Icons.refresh),
              mini: true,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          LogService().log('Navigating to screen index: $index');
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: navigationItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupRealtimeSubscription();
    
    // Verificar actualizaciones automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
    });
  }
  
  void _setupRealtimeSubscription() {
    Supabase.instance.client
        .channel('public:users')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'users',
          callback: (payload) {
             final newUser = payload.newRecord;
             final username = newUser['username'] ?? 'Desconocido';
             
             NotificationService().showNotification(
               id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
               title: '¡Nuevo Usuario Realtime!',
               body: 'Se ha creado el usuario "$username" remotamente.',
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
      dataProvider.loadData(),
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
        label: 'Producción',
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
        title: Text(
          'Alpla Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
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

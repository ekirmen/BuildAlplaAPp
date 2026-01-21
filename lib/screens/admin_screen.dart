import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';
import '../models/app_config_model.dart';
import '../services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue.shade50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            tabs: const [
              Tab(icon: Icon(Icons.settings), text: 'Configuración'),
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.delete_forever), text: 'Datos'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ConfigTab(),
              _UsersTab(),
              _DataTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Configuration Tab
class _ConfigTab extends StatefulWidget {
  const _ConfigTab();

  @override
  State<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<_ConfigTab> {
  final _linesController = TextEditingController();
  final _shiftsController = TextEditingController();
  final _productsController = TextEditingController();
  
  List<OperatorConfig> _operators = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final configProvider = context.read<ConfigProvider>();
    final config = configProvider.config;

    _linesController.text = config.validLines.join('\n');
    _shiftsController.text = config.validShifts.join('\n');
    _productsController.text = config.validProducts.join('\n');
    _operators = List.from(config.validOperators);
  }

  @override
  void dispose() {
    _linesController.dispose();
    _shiftsController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final lines = _linesController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final shifts = _shiftsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final products = _productsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final newConfig = AppConfigModel(
      validLines: lines,
      validShifts: shifts,
      validOperators: _operators,
      validProducts: products,
    );

    final configProvider = context.read<ConfigProvider>();
    final success = await configProvider.saveConfig(newConfig);

    if (!mounted) return;

    if (success) {
      // Update operator groups in historical data
      final dataProvider = context.read<DataProvider>();
      final operatorGroupMap = Map.fromEntries(
        _operators.map((op) => MapEntry(op.operador, op.grupo)),
      );
      
      await dataProvider.loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '⚙️ Configuración de Listas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Lines
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏭 Líneas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _linesController,
                  decoration: const InputDecoration(
                    hintText: 'Una línea por renglón',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shifts
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🕒 Turnos',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _shiftsController,
                  decoration: const InputDecoration(
                    hintText: 'Un turno por renglón',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Products
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 Productos',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _productsController,
                  decoration: const InputDecoration(
                    hintText: 'Un producto por renglón',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Operators
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👤 Operadores y Grupos',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        setState(() {
                          _operators.add(
                            OperatorConfig(
                              operador: 'Nuevo Operador',
                              grupo: 'A',
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._operators.asMap().entries.map((entry) {
                  final index = entry.key;
                  final operator = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Operador',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: TextEditingController(text: operator.operador)
                              ..selection = TextSelection.collapsed(
                                offset: operator.operador.length,
                              ),
                            onChanged: (value) {
                              _operators[index] = OperatorConfig(
                                operador: value,
                                grupo: operator.grupo,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: operator.grupo,
                            decoration: const InputDecoration(
                              labelText: 'Grupo',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: ['A', 'B', 'C', 'D', 'Sin Grupo']
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _operators[index] = OperatorConfig(
                                  operador: operator.operador,
                                  grupo: value!,
                                );
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _operators.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Save button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            label: Text(
              '💾 Guardar Configuración',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Users Tab
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService(Supabase.instance.client);
      final users = await authService.getAllUsers();
      setState(() {
        _users = users.map((u) => u.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'viewer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('➕ Crear Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: ['admin', 'supervisor', 'viewer']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = AuthService(Supabase.instance.client);
              final (success, message) = await authService.createUser(
                username: usernameController.text,
                password: passwordController.text,
                role: selectedRole,
                name: nameController.text,
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );

              if (success) {
                // Notificación Local
                await NotificationService().showNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: 'Nuevo Usuario Creado',
                  body: 'El usuario ${usernameController.text} ha sido registrado correctamente.',
                );
                
                _loadUsers();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final usernameController = TextEditingController(text: user['username']);
    final passwordController = TextEditingController();
    final nameController = TextEditingController(text: user['name']);
    String selectedRole = user['role'] ?? 'viewer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Editar Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  enabled: false, // No se puede cambiar el username
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña (Opcional)',
                  hintText: 'Dejar vacío para mantener actual',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: ['admin', 'supervisor', 'viewer']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = AuthService(Supabase.instance.client);
              final (success, message) = await authService.updateUser(
                username: usernameController.text,
                name: nameController.text,
                role: selectedRole,
                newPassword: passwordController.text.isNotEmpty ? passwordController.text : null,
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );

              if (success) {
                _loadUsers();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👥 Gestión de Usuarios',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(
                    user['name'] ?? '',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('@${user['username']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          user['role']?.toUpperCase() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: user['role'] == 'admin'
                            ? Colors.red.shade100
                            : user['role'] == 'supervisor'
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditUserDialog(user),
                        tooltip: 'Editar Usuario',
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
  }
}

// Data Management Tab
class _DataTab extends StatelessWidget {
  const _DataTab();

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Advertencia'),
        content: const Text(
          '¿Está seguro que desea BORRAR TODOS LOS DATOS?\n\nEsta acción es IRREVERSIBLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('BORRAR TODO'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final dataProvider = context.read<DataProvider>();
    final success = await dataProvider.deleteAllData();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Datos borrados' : '❌ Error al borrar'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '📂 Gestión de Datos',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Registros',
                        value: dataProvider.allData.length.toString(),
                        icon: Icons.dataset,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Minutos',
                        value: dataProvider.getTotalMinutes().toStringAsFixed(0),
                        icon: Icons.timer,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Zona de Peligro',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteAllData(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('🚨 BORRAR TODOS LOS DATOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

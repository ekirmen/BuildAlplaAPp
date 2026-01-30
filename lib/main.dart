import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui'; // Para PlatformDispatcher
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/config_provider.dart';
import 'providers/production_provider.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/config_service.dart';
import 'services/production_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    
    // Configurar Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Error inicializando Firebase: $e");
  }

  // Inicializar notificaciones
  await NotificationService().init();

  bool supabaseInitialized = false;
  String? initError;

  try {
    // Configuración de Supabase - Alpla Dashboard
    await Supabase.initialize(
      url: 'https://fmreitafxucwejvwzjvp.supabase.co',
      anonKey: 'sb_secret_M2RnnzHuOgC4Q5e8N1MPCw_DYHWgvAA',
    );
    supabaseInitialized = true;
  } catch (e) {
    initError = e.toString();
    debugPrint('Error inicializando Supabase: $e');
  }

  runApp(AlplaApp(
    supabaseInitialized: supabaseInitialized,
    initError: initError,
  ));
}

class AlplaApp extends StatelessWidget {
  final bool supabaseInitialized;
  final String? initError;

  const AlplaApp({
    super.key,
    required this.supabaseInitialized,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    // Si Supabase no se inicializó, mostrar pantalla de error
    if (!supabaseInitialized) {
      return MaterialApp(
        title: 'Alpla Dashboard',
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(error: initError ?? 'Error desconocido'),
      );
    }

    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(supabase))..checkLoginStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => DataProvider(DataService(supabase)),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfigProvider(ConfigService(supabase)),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductionProvider(ProductionService(supabase)),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadTheme(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Alpla Dashboard',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(),
              appBarTheme: AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                color: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              inputDecorationTheme: InputDecorationTheme(
                 border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

// Pantalla de error si Supabase no se inicializa
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                'Error de Conexión',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo conectar a Supabase',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: SelectableText(
                  error,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifica tu conexión a internet\ny las credenciales de Supabase',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

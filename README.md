# Alpla Dashboard - Aplicación Flutter

Dashboard Industrial para gestión de paradas y eficiencia en Alpla de Venezuela.

## 🚀 Características

- ✅ **Autenticación segura** con hash de contraseñas
- 📊 **Dashboard interactivo** con gráficos y KPIs
- 📝 **Ingreso de datos** de paradas industriales
- 🆚 **Comparativo mensual** con análisis de variaciones
- 👥 **Gestión de usuarios** con roles (admin, supervisor, viewer)
- ⚙️ **Configuración flexible** de líneas, turnos, operadores y productos
- 📱 **Diseño responsive** optimizado para móviles

## 📋 Requisitos Previos

1. **Flutter SDK** (versión 3.3.0 o superior)
2. **Cuenta de Supabase** (gratuita)
3. **Android Studio** o **VS Code** con extensiones de Flutter

## 🔧 Configuración

### 1. Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Espera a que se inicialice (2-3 minutos)

### 2. Crear tablas en Supabase

En el SQL Editor de Supabase, ejecuta:

```sql
-- Tabla de usuarios
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  salt TEXT NOT NULL,
  role TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de datos industriales
CREATE TABLE industrial_data (
  id SERIAL PRIMARY KEY,
  fecha DATE NOT NULL,
  turno TEXT NOT NULL,
  linea TEXT NOT NULL,
  producto TEXT NOT NULL,
  minutos NUMERIC NOT NULL,
  causa TEXT NOT NULL,
  operador TEXT NOT NULL,
  grupo TEXT DEFAULT 'Sin Grupo',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de configuración
CREATE TABLE app_config (
  id SERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Insertar configuración por defecto
INSERT INTO app_config (key, value) VALUES
('valid_lines', '["L-7", "L-8", "L-17", "Empaque"]'),
('valid_shifts', '["Día", "Noche"]'),
('valid_products', '["Botella 500ml", "Envase 1L"]'),
('valid_operators', '[
  {"Operador": "Miguel Fuenmayor", "Grupo": "A"},
  {"Operador": "José Manuel Gutiérrez", "Grupo": "B"},
  {"Operador": "Luciano Truisi", "Grupo": "A"},
  {"Operador": "José Chourio", "Grupo": "B"}
]');
```

### 3. Configurar credenciales

1. En Supabase, ve a **Settings** → **API**
2. Copia tu **Project URL** y **anon/public key**
3. Abre `lib/main.dart` y reemplaza:

```dart
await Supabase.initialize(
  url: 'TU_SUPABASE_URL_AQUI',  // Pega tu URL aquí
  anonKey: 'TU_SUPABASE_ANON_KEY_AQUI',  // Pega tu key aquí
);
```

### 4. Instalar dependencias

```bash
flutter pub get
```

## 🏃‍♂️ Ejecutar la aplicación

### En modo desarrollo:
```bash
flutter run
```

### Para generar APK:
```bash
flutter build apk --release
```

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

## 👤 Usuario por defecto

- **Usuario:** `admin`
- **Contraseña:** `admin123`

## 📱 Estructura de la App

```
lib/
├── models/              # Modelos de datos
│   ├── user_model.dart
│   ├── industrial_data_model.dart
│   └── app_config_model.dart
├── services/            # Servicios de backend
│   ├── auth_service.dart
│   ├── data_service.dart
│   └── config_service.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   ├── data_provider.dart
│   └── config_provider.dart
├── screens/             # Pantallas
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── overview_screen.dart
│   ├── comparison_screen.dart
│   ├── data_entry_screen.dart
│   └── admin_screen.dart
└── main.dart            # Punto de entrada
```

## 🎨 Características de Diseño

- **Material Design 3** con tema personalizado
- **Google Fonts** (Poppins)
- **Gráficos interactivos** con fl_chart
- **Diseño responsive** para diferentes tamaños de pantalla
- **Colores corporativos** azul/blanco

## 🔐 Roles de Usuario

1. **Admin**: Acceso completo (configuración, usuarios, datos)
2. **Supervisor**: Puede ingresar datos y ver reportes
3. **Viewer**: Solo puede ver reportes

## 📊 Funcionalidades

### Vista General
- KPIs principales (tiempo total, horas perdidas, línea crítica)
- Gráfico de torta por línea
- Gráficos de barras por grupo y operador
- Filtros por período y línea

### Comparativo Mensual
- Comparación entre dos períodos
- Variación de minutos y eventos
- Análisis por línea y grupo

### Ingreso de Datos
- Formulario completo con validación
- Asignación automática de grupos
- Feedback visual de guardado

### Panel de Administración
- Configuración de listas (líneas, turnos, productos)
- Gestión de operadores y grupos
- Gestión de usuarios
- Eliminación de datos

## 🐛 Solución de Problemas

### Error de conexión a Supabase
- Verifica que las credenciales en `main.dart` sean correctas
- Asegúrate de tener conexión a internet
- Revisa que las tablas estén creadas en Supabase

### Error al compilar
```bash
flutter clean
flutter pub get
flutter run
```

## 📄 Licencia

Desarrollado para Corporación JP - Cliente: Alpla de Venezuela

## 🤝 Soporte

Para soporte técnico, contacta al equipo de desarrollo.

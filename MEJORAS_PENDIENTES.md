# Plan de Mejoras para AlplaApp (Roadmap to 100%)

Este documento detalla las áreas clave de mejora para llevar la aplicación a un nivel de producción robusto, eficiente y profesional ("100%").

## 1. Rendimiento y Estabilidad (Prioridad Alta)
- [x] **Paginación Inteligente**: Implementado "Infinite Scroll" con carga por bloques (Page Size: 100).
- [ ] **Modo Offline / Caché Local**: Implementar una base de datos local (ej. Hive) para caché.
- [ ] **Manejo de Conexión**: Agregar indicador de estado de conexión.
- [x] **Optimización de Gráficos**: Gráficos limitados a Top 10 para rendimiento estable.

## 2. Experiencia de Usuario (UI/UX)
- [x] **Skeleton Loading**: Implementado `DashboardSkeleton` con efecto shimmer.
- [x] **Feedback de Acciones**: Snackbars implementados en Admin y Production screens.
- [x] **Diseño Responsivo Refinado**: Uso de `Expanded` y `Flex` en layouts principales.
- [x] **Tema Oscuro**: Implementado sistema de temas (Light/Dark) con persistencia.

## 3. Funcionalidades Avanzadas
- [x] **Exportación de Reportes**: Exportación a CSV y PDF implementada en `OverviewScreen`.
- [x] **Filtros Avanzados**: Persistencia de filtros y DatePicker implementados.
- [ ] **Gestión de Perfil**: Permitir cambiar contraseña/avatar.
- [ ] **Notificaciones Granulares**: Configuración avanzada de alertas.

## 4. Calidad de Código y Mantenimiento
- [ ] **Tests Automatizados**:
    - *Unit Tests*: Para lógica de KPIs.
    - *Widget Tests*: Para pantallas principales.
- [ ] **Separación de Lógica**: Refactorizar lógica restante.
- [x] **Logs Centralizados**: Implementado `LogService` conectado a Crashlytics.

## 5. Seguridad
- [x] **Renovación de Sesión**: Verificación de sesión en `main.dart` y `AuthProvider`.
- [x] **Roles y Permisos**: Validaciones UI estrictas implementadas (FAB en Producción, Tabs en Home).

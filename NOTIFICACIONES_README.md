# Guía de Implementación: Notificaciones Push (Supabase + Firebase)

## 1. Arquitectura del Sistema
El sistema conecta tres componentes principales para enviar notificaciones en tiempo real a dispositivos Android, incluso cuando la App está cerrada.

```mermaid
[Supabase DB] --> (INSERT Trigger) --> [Webhook] --> [Supabase Edge Function] --> [Firebase Cloud Messaging] --> [Android App]
```

---

## 2. Supabase Edge Function (`push-notification`)
Esta función actúa como "Backend" para recibir el evento de base de datos y comunicarse con Firebase.

**Pasos de Despliegue:**
1. Crear una función en Supabase Dashboard llamada `push-notification`.
2. Copiar y pegar el siguiente código TypeScript.
3. **IMPORTANTE**: Reemplazar la sección `serviceAccount` con el contenido real de tu archivo JSON descargado de Firebase Console.

```typescript
// Importamos el servidor HTTP de Deno
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
// Importamos firebase-admin usando npm: para evitar errores de compilación
import admin from "npm:firebase-admin@11.11.1"

// --------------------------------------------------------
// CREDENCIALES DE SERVICIO (SERVICE ACCOUNT)
// --------------------------------------------------------
const serviceAccount = {
    "type": "service_account",
    "project_id": "TU_PROJECT_ID",
    "private_key_id": "...",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...",
    "client_email": "...",
    "client_id": "...",
    "auth_uri": "...",
    "token_uri": "...",
    "auth_provider_x509_cert_url": "...",
    "client_x509_cert_url": "..."
};

// Inicializamos Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

console.log("Firebase Admin Initialized!");

serve(async (req) => {
    try {
        // 1. Parseamos el cuerpo de la petición (Webhook de Supabase)
        const payload = await req.json();
        console.log("Webhook payload:", JSON.stringify(payload));

        // Validamos que sea un INSERT
        if (payload.type !== 'INSERT') {
            return new Response("Not an INSERT event", { status: 200 });
        }

        const record = payload.record;
        
        // 2. Extraemos los datos útiles
        const linea = record.linea || "Línea desconocida";
        const causa = record.causa || "Sin causa";
        const minutos = record.minutos || 0;

        // 3. Preparamos el mensaje
        const topic = "production_alerts";

        const message = {
            notification: {
                title: "¡Nuevo Dato de Producción!",
                body: `Línea ${linea}: ${causa} (${minutos} min)`,
            },
            topic: topic,
        };

        // 4. Enviamos a Firebase Cloud Messaging
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);

        return new Response(JSON.stringify({ success: true, messageId: response }), {
            headers: { "Content-Type": "application/json" },
        });

    } catch (error) {
        console.error("Error processing webhook:", error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
```

---

## 3. Configuración del Webhook (Trigger)
Esto configura a Supabase para que llame a la función cada vez que entra un dato.

**Configuración en Supabase Dashboard -> Database -> Webhooks:**

- **Name**: `push-trigger`
- **Table**: `public.industrial_data`
- **Events**: `INSERT` (marcado)
- **Type**: `Supabase Edge Function`
- **Method**: `POST`
- **Function**: Seleccionar `push-notification`
- **HTTP Headers**:
  - `Content-type`: `application/json`
  - `Authorization`: `Bearer TU_CLAVE_ANON_PUBLICA` (Supabase suele ponerla automática)

---

## 4. Código Flutter (App)

### Dependencias (`pubspec.yaml`)
```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
```

### Inicialización (`main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Error inicializando Firebase: $e");
  }

  // Inicializar notificaciones
  await NotificationService().init();
  
  // ... resto del código
}
```

### Servicio de Notificaciones (`notification_service.dart`)
```dart
// Handler de Segundo Plano (Fuera de la clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // ... Singleton pattern ...

  Future<void> init() async {
    // ... Configuración Local Notifications ...

    // Inicializar Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Solicitar permiso al usuario
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
    );

    // Registrar Handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Mostrar notificación local si la app está abierta
        if (message.notification != null) {
            showNotification(
                id: message.hashCode,
                title: message.notification?.title ?? 'Sin Título',
                body: message.notification?.body ?? 'Sin Cuerpo',
            );
        }
    });

    // SUSCRIPCIÓN AL TEMA (CRÍTICO)
    await messaging.subscribeToTopic('production_alerts');
  }
}
```

---

## 5. Configuración Android (`android/`)

### `android/build.gradle.kts` (Root)
```kotlin
plugins {
    // ...
    id("com.google.gms.google-services") version "4.4.4" apply false
}
```

### `android/app/build.gradle.kts` (App Module)
```kotlin
plugins {
    // ...
    id("com.google.gms.google-services")
}

dependencies {
    // ...
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}
```

### Archivo Obligatorio
El archivo `google-services.json` descargado de Firebase Console debe estar en:
`android/app/google-services.json`

---

## 6. Despliegue Manual (Supabase CLI Local)
Para evitar problemas de instalación global, usamos el ejecutable `supabase.exe` colocado en la raíz del proyecto.

### Archivos de Ayuda
- **`supabase.exe`**: La herramienta de línea de comandos (CLI).
- **`deploy_function.bat`**: Script que automatiza el proceso de login y deploy.

### Comando de Despliegue
Si necesitas actualizar la función manualmente desde la terminal:

```powershell
# 1. Iniciar sesión (solo la primera vez)
.\supabase.exe login

# 2. Desplegar la función (sin verificar JWT para evitar Docker en builds complejos)
.\supabase.exe functions deploy push-notification --project-ref vufrmuvkekcizmycdbur --no-verify-jwt
```

### Nota sobre Imports (Solución de Error de Bundle)
Para que el despliegue funcione sin Docker y no de errores de "Relative import path", es **crítico** usar el prefijo `npm:` en los imports de Deno:

```typescript
// ✅ CORRECTO: Permite a Supabase resolver dependencias nativas de Node
import admin from "npm:firebase-admin@11.11.1"

// ❌ INCORRECTO: Suele fallar al empaquetar si no se usa Docker
// import admin from "https://esm.sh/firebase-admin..."
```


// Importamos el servidor HTTP de Deno
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
// Importamos firebase-admin usando npm: para evitar errores de compilación
import admin from "npm:firebase-admin@11.11.1"

// --------------------------------------------------------
// CREDENCIALES DE SERVICIO (SERVICE ACCOUNT)
// --------------------------------------------------------
const serviceAccount = {
    "type": "service_account",
    "project_id": Deno.env.get("FIREBASE_PROJECT_ID"),
    "private_key_id": Deno.env.get("FIREBASE_PRIVATE_KEY_ID"),
    "private_key": Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, '\n'),
    "client_email": Deno.env.get("FIREBASE_CLIENT_EMAIL"),
    "client_id": Deno.env.get("FIREBASE_CLIENT_ID"),
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": Deno.env.get("FIREBASE_CLIENT_CERT_URL"),
    "universe_domain": "googleapis.com"
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

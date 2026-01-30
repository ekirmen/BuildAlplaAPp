import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { importPKCS8, SignJWT } from "https://deno.land/x/jose@v4.14.4/index.ts";

// --------------------------------------------------------------------------------------
// CREDENCIALES DE FIREBASE (INTEGRADAS PARA DESPLIEGUE MANUAL EN DASHBOARD)
// --------------------------------------------------------------------------------------
const serviceAccount = {
    "type": "service_account",
    "project_id": "alplaapp-notification",
    "private_key_id": "f1f6d2628db0839421311c4c8a506ad0cb58c5b4",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCmDpaZfdahMXWh\nNJcaQk6WCkCpOlgNeje8bS5MNcUm5WVluHKSoZfO/muIwrOqFKBKCTCnR7lmqCq1\nq2DyCmb+oKemTfLW0YPn1RxTHSOUKgd2SdamJ4kj+DwlyAyqBbzCe9qTD6MjamP9\nV8XRddNvoUdM7glLbrzwcmc5Sk8jAZdhgdE7ymyDG/qkN1rpipBdbjcVRz3H81/L\nS/6wQ2KnNk9eyzJFRfYEDk5KcPgR81Pq+me9GL+40Ln3wfYkgmQfzvF/EzBSEgPK\nM5wRN4re1LcAJgp9zWVxJJ6I5qnoy8IkCOZHb8dNhHCvk9+z5/TFyDb4ojU+9AcW\nGSzRGz9nAgMBAAECggEAJqcoqQvgpN7VabPLJGKg1k4GpR2el2yGgsbLSxQNEzO8\neYQIr1cL9jPEpi3kEkgA05r2B0orvtiQMH927oA7XzPYMl7ckuJsGM/DaxlSSc/K\nst8XJs/3HTdQEN9TC1SQjpiz1R2DtN+z7Km8szgBAnABH8gcw8FAG5wVqQFCEHyT\nJ8b5laIG2FEEjDr4vMTo/QzAiOjk/AuYmrduuw3Jqlx461xGR/3o2P7Xj5gNJNa3\nusXxGrvT27N9yc2ynWzGw+7LbTnl/5c7aGz/prz8hhkrh2hAwtl6g8WUtGKjQXMb\nuZ8Op64zCRgpyJz1UkCe7R+pnO8g6Nf5INbg/wNhaQKBgQDb4DcDsk/DkLjh0fdN\njWam/gEnpJ7+7+7P6mCMGRfUv6DP3+hxjEeQKINXXrlANxfPYOvLQkCFEoGdPaZM\n6qIwuxHOQd6M9sF6zb5irGpkmkzHNmzdJ7MjfshUsOzVp2Zp27pZpmsKTtWXOeyq\nX4xVU884+3u/wITOGktfJetPYwKBgQDBVsyvSWoSaXyj9+YfDUYQ197Pvl1VzUBP\nQ9ho93P4f1o8/mvHYV/7/EWQbfbnjKiX7indw8+tbOksg2jMTA9rnbPEggD7MvOV\nQlQp4BmrDq9HSw+mE6CjBdeSwmOolr1pHmP9xgHStH06nFr4unk9LX6kvEcZ87Ad\n3jfdT435LQKBgHzh+X1A/qrd/RRNtD+5C0/XvwIsLx4vWp1+yn1oFy//8y9+RkCP\n42mOiSLLqz48zGo9608T/x9V5oZPqK/RKHOzHKbgpK29zSCZ0QOsV/Vx6h/P2r81\nuDp13QS1RJ8JKFMBuPMIYY2GPyxYewI9qLAiHPWJaLz9dLC3II4XNHJvAoGAONkS\n2j+V5tAJjBTqHxtCDNXMd/0baI0vaZ8jVMnd2aVonSKaAkgJdwhYU/1hafgb4oBu\n4vweZnntnd8Nw3Rh3FzEbPVk4He805hrMtzn7zokI6xYb5a51vVyy35I21tnWi9L\na2T7SD81yzQKM7RwzaJA6KNLrL/QexfKCVLJBgkCgYEAqfNdjduASE0/hfQrr30g\nTtJGzK435nz1sJhe2UIG/IFUhgN4kADpHvEIzMZ6HOpM4TJrB2ya5xlEJMux9OlJ\n5YIQDsU18+PXX9HzCopf6Dh3gowx1zirYYScrukyS93EIKgzjuppkYDWTeiCttvS\nx+jbXnd85ieTdcz8pIkBV5s=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@alplaapp-notification.iam.gserviceaccount.com"
};

serve(async (req) => {
    try {
        const payload = await req.json();

        if (payload.type !== 'INSERT') {
            return new Response("Not an INSERT event", { status: 200 });
        }

        const record = payload.record;
        const linea = record.linea || "Línea desconocida";
        const causa = record.causa || "Sin causa";
        const minutos = record.minutos || 0;
        const topic = "production_alerts";

        // 1. Obtener Access Token de Google manualmente
        const accessToken = await getAccessToken(serviceAccount);

        // 2. Enviar mensaje a FCM vía REST API
        const projectId = serviceAccount.project_id;
        const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

        const messagePayload = {
            message: {
                topic: topic,
                notification: {
                    title: "¡Nuevo Dato de Producción!",
                    body: `Línea ${linea}: ${causa} (${minutos} min)`,
                },
            }
        };

        const res = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(messagePayload),
        });

        const json = await res.json();
        console.log("FCM Response:", json);

        return new Response(JSON.stringify(json), {
            headers: { "Content-Type": "application/json" },
        });

    } catch (error) {
        console.error("Error:", error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});

// Función Helper para firmar JWT y obtener token (OAuth2)
async function getAccessToken({ client_email, private_key }: { client_email: string, private_key: string }) {
    const alg = 'RS256';
    const pkcs8 = private_key;
    const privateKey = await importPKCS8(pkcs8, alg);

    const jwt = await new SignJWT({
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
    })
        .setProtectedHeader({ alg })
        .setIssuer(client_email)
        .setAudience('https://oauth2.googleapis.com/token')
        .setExpirationTime('1h')
        .setIssuedAt()
        .sign(privateKey);

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt,
        }),
    });

    const data = await res.json();
    return data.access_token;
}

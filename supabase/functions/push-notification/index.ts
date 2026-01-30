import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { importPKCS8, SignJWT } from "https://deno.land/x/jose@v4.14.4/index.ts";
import serviceAccount from "./service-account.json" assert { type: "json" };

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

    // 1. Obtener Access Token de Google manualmente (Sin librerías pesadas)
    const accessToken = await getAccessToken(serviceAccount);

    // 2. Enviar mensaje a FCM vía REST API
    const projectId = serviceAccount.project_id;
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // El cuerpo debe tener la estructura exacta de la API v1
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

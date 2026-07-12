// Vercel serverless function: proxies to Gemini API (bypasses CORS, keeps key server-side)
// Set GEMINI_API_KEY as a Vercel environment variable for production
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { model, contents } = req.body;
  if (!model || !contents) {
    return res.status(400).json({ error: "Missing required fields: model, contents" });
  }

  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    return res.status(500).json({ error: "GEMINI_API_KEY not configured on server" });
  }

  try {
    const resp = await fetch("https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + key, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents }),
    });

    const data = await resp.json();
    if (!resp.ok) {
      const msg = (data.error && data.error.message) || "Gemini API error " + resp.status;
      return res.status(resp.status).json({ error: msg });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message || "Failed to reach Gemini API" });
  }
}

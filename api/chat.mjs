// Vercel serverless function: proxies to Groq/OpenAI-compatible API (bypasses CORS)
// Set AI_API_KEY as a Vercel environment variable for production
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { endpoint, model, messages } = req.body;
  if (!endpoint || !model || !messages) {
    return res.status(400).json({ error: "Missing required fields: endpoint, model, messages" });
  }

  try {
    const headers = { "Content-Type": "application/json" };
    if (process.env.AI_API_KEY) headers["Authorization"] = "Bearer " + process.env.AI_API_KEY;

    const resp = await fetch(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify({ model, messages, stream: false }),
    });

    if (!resp.ok) {
      const text = await resp.text();
      return res.status(resp.status).json({ error: `API returned ${resp.status}: ${text}` });
    }

    const data = await resp.json();
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message || "Failed to reach AI service" });
  }
}

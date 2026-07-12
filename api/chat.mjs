// Vercel serverless function: proxies to Ollama API (bypasses CORS)
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { endpoint, model, messages, apiKey } = req.body;
  if (!endpoint || !model || !messages) {
    return res.status(400).json({ error: "Missing required fields: endpoint, model, messages" });
  }

  try {
    const headers = { "Content-Type": "application/json" };
    if (apiKey) headers["Authorization"] = "Bearer " + apiKey;

    const resp = await fetch(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify({ model, messages, stream: false }),
    });

    if (!resp.ok) {
      const text = await resp.text();
      return res.status(resp.status).json({ error: `Ollama returned ${resp.status}: ${text}` });
    }

    const data = await resp.json();
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message || "Failed to reach Ollama" });
  }
}

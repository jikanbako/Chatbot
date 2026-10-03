import type {
  AIRequest,
  AIResponse,
} from "@/lib/ai/types";

const OPENROUTER_URL =
  "https://openrouter.ai/api/v1/chat/completions";

export async function generateOpenRouterResponse(
  request: AIRequest
): Promise<AIResponse> {
  const apiKey = process.env.OPENROUTER_API_KEY;

  if (!apiKey) {
    throw new Error(
      "OPENROUTER_API_KEY is not configured."
    );
  }

  const model =
    request.model ||
    process.env.AI_DEFAULT_MODEL ||
    "openrouter/free";

  const startedAt = Date.now();

  const response = await fetch(OPENROUTER_URL, {
    method: "POST",

    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer":
        process.env.OPENROUTER_SITE_URL ||
        "http://localhost:3000",
      "X-Title":
        process.env.OPENROUTER_APP_NAME ||
        "AI Chatbot",
    },

    body: JSON.stringify({
      model,
      messages: request.messages,
      temperature: request.temperature ?? 0.7,
      max_tokens: request.maxTokens ?? 1000,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();

    throw new Error(
      `OpenRouter request failed (${response.status}): ${errorText}`
    );
  }

  const data = await response.json();

  const content =
    data?.choices?.[0]?.message?.content;

  if (
    typeof content !== "string" ||
    !content.trim()
  ) {
    throw new Error(
      "OpenRouter returned an empty or invalid response."
    );
  }

  const usage = data?.usage ?? {};

  return {
    content: content.trim(),

    model:
      data?.model ||
      model,

    provider: "openrouter",

    inputTokens:
      Number(usage?.prompt_tokens) || 0,

    outputTokens:
      Number(usage?.completion_tokens) || 0,

    totalTokens:
      Number(usage?.total_tokens) || 0,

    latencyMs:
      Date.now() - startedAt,
  };
}

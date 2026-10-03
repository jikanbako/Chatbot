"use client";

import { FormEvent, useState } from "react";
import styles from "./page.module.css";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [conversationId, setConversationId] =
    useState<string | null>(null);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function sendMessage(
    event: FormEvent<HTMLFormElement>
  ) {
    event.preventDefault();

    const message = input.trim();

    if (!message || loading) {
      return;
    }

    setError("");
    setInput("");

    const temporaryUserMessage: ChatMessage = {
      id: `temporary-user-${Date.now()}`,
      role: "user",
      content: message,
    };

    setMessages((current) => [
      ...current,
      temporaryUserMessage,
    ]);

    setLoading(true);

    try {
      const response = await fetch("/api/chat", {
        method: "POST",

        headers: {
          "Content-Type": "application/json",
        },

        body: JSON.stringify({
          conversationId,
          message,
        }),
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(
          data.error || "Unable to send message."
        );
      }

      setConversationId(data.conversationId);

      setMessages((current) => [
        ...current,
        {
          id: data.assistantMessage.id,
          role: "assistant",
          content: data.assistantMessage.content,
        },
      ]);
    } catch (error) {
      console.error(error);

      setError(
        error instanceof Error
          ? error.message
          : "Something went wrong."
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className={styles.page}>
      <section className={styles.chat}>
        <header className={styles.header}>
          <div>
            <h1>AI Chatbot</h1>
            <p>Your English & Hausa AI assistant</p>
          </div>
        </header>

        <div className={styles.messages}>
          {messages.length === 0 && (
            <div className={styles.empty}>
              <h2>How can I help you?</h2>

              <p>
                Ask me a question in English or Hausa.
              </p>
            </div>
          )}

          {messages.map((message) => (
            <div
              key={message.id}
              className={`${styles.message} ${
                message.role === "user"
                  ? styles.userMessage
                  : styles.assistantMessage
              }`}
            >
              <div className={styles.messageRole}>
                {message.role === "user"
                  ? "You"
                  : "AI"}
              </div>

              <div className={styles.messageContent}>
                {message.content}
              </div>
            </div>
          ))}

          {loading && (
            <div
              className={`${styles.message} ${styles.assistantMessage}`}
            >
              <div className={styles.messageRole}>
                AI
              </div>

              <div className={styles.messageContent}>
                Thinking...
              </div>
            </div>
          )}
        </div>

        <div className={styles.composer}>
          {error && (
            <div className={styles.error}>
              {error}
            </div>
          )}

          <form onSubmit={sendMessage}>
            <textarea
              value={input}
              onChange={(event) =>
                setInput(event.target.value)
              }
              placeholder="Message your AI assistant..."
              rows={2}
              disabled={loading}
            />

            <button
              type="submit"
              disabled={loading || !input.trim()}
            >
              {loading ? "Sending..." : "Send"}
            </button>
          </form>
        </div>
      </section>
    </main>
  );
}

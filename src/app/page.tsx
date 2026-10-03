import Link from "next/link";

export default function HomePage() {
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px",
      }}
    >
      <div style={{ textAlign: "center" }}>
        <h1>AI Chatbot</h1>

        <p>
          Your intelligent English and Hausa AI assistant.
        </p>

        <div
          style={{
            display: "flex",
            gap: "12px",
            justifyContent: "center",
            marginTop: "24px",
          }}
        >
          <Link href="/login">Sign in</Link>

          <Link href="/register">Create account</Link>
        </div>
      </div>
    </main>
  );
}

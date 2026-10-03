import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function ChatPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  return (
    <main style={{ padding: "32px" }}>
      <h1>AI Chat</h1>

      <p>
        Welcome,{" "}
        {user.user_metadata?.full_name || user.email || "User"}.
      </p>

      <p>Your authenticated chat interface will be built next.</p>
    </main>
  );
}

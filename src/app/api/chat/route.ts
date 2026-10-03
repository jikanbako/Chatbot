import { NextResponse } from "next/server";

import { createClient } from "@/lib/supabase/server";
import { generateAIResponse } from "@/lib/ai/orchestrator";

interface ChatRequestBody {
  conversationId?: string;
  message?: string;
}

export async function POST(request: Request) {
  try {
    const supabase = await createClient();

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error: "Authentication required.",
        },
        { status: 401 }
      );
    }

    let body: ChatRequestBody;

    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid JSON request.",
        },
        { status: 400 }
      );
    }

    const message = body.message?.trim();

    if (!message) {
      return NextResponse.json(
        {
          success: false,
          error: "Message is required.",
        },
        { status: 400 }
      );
    }

    if (message.length > 10000) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Message is too long. Please keep it under 10,000 characters.",
        },
        { status: 400 }
      );
    }

    let conversationId = body.conversationId;

    /*
     * --------------------------------------------------------
     * CREATE OR VERIFY CONVERSATION
     * --------------------------------------------------------
     */

    if (conversationId) {
      const { data: existingConversation, error } =
        await supabase
          .from("conversations")
          .select("id")
          .eq("id", conversationId)
          .eq("user_id", user.id)
          .single();

      if (error || !existingConversation) {
        return NextResponse.json(
          {
            success: false,
            error: "Conversation not found.",
          },
          { status: 404 }
        );
      }
    } else {
      const { data: newConversation, error } =
        await supabase
          .from("conversations")
          .insert({
            user_id: user.id,
            title:
              message.length > 60
                ? `${message.slice(0, 57)}...`
                : message,
          })
          .select("id")
          .single();

      if (error || !newConversation) {
        console.error(
          "Conversation creation error:",
          error
        );

        return NextResponse.json(
          {
            success: false,
            error: "Unable to create conversation.",
          },
          { status: 500 }
        );
      }

      conversationId = newConversation.id;
    }

    /*
     * --------------------------------------------------------
     * GET RECENT CONVERSATION HISTORY
     * --------------------------------------------------------
     */

    const { data: previousMessages, error: historyError } =
      await supabase
        .from("messages")
        .select("role, content")
        .eq("conversation_id", conversationId)
        .eq("user_id", user.id)
        .order("created_at", {
          ascending: true,
        })
        .limit(30);

    if (historyError) {
      console.error(
        "Conversation history error:",
        historyError
      );

      return NextResponse.json(
        {
          success: false,
          error: "Unable to load conversation history.",
        },
        { status: 500 }
      );
    }

    /*
     * --------------------------------------------------------
     * SAVE USER MESSAGE
     * --------------------------------------------------------
     */

    const { data: savedUserMessage, error: userMessageError } =
      await supabase
        .from("messages")
        .insert({
          conversation_id: conversationId,
          user_id: user.id,
          role: "user",
          content: message,
        })
        .select("id, created_at")
        .single();

    if (userMessageError || !savedUserMessage) {
      console.error(
        "User message error:",
        userMessageError
      );

      return NextResponse.json(
        {
          success: false,
          error: "Unable to save your message.",
        },
        { status: 500 }
      );
    }

    /*
     * --------------------------------------------------------
     * BUILD AI HISTORY
     * --------------------------------------------------------
     */

    const aiMessages = [
      ...(previousMessages ?? [])
        .filter(
          (item) =>
            item.role === "user" ||
            item.role === "assistant"
        )
        .map((item) => ({
          role: item.role as "user" | "assistant",
          content: item.content,
        })),

      {
        role: "user" as const,
        content: message,
      },
    ];

    /*
     * --------------------------------------------------------
     * GENERATE AI RESPONSE
     * --------------------------------------------------------
     */

    let aiResponse;

    try {
      aiResponse =
        await generateAIResponse(aiMessages);
    } catch (error) {
      console.error(
        "AI generation error:",
        error
      );

      return NextResponse.json(
        {
          success: false,
          error:
            "The AI service could not generate a response. Please try again.",
        },
        { status: 502 }
      );
    }

    /*
     * --------------------------------------------------------
     * SAVE ASSISTANT MESSAGE
     * --------------------------------------------------------
     */

    const { data: savedAssistantMessage, error: assistantError } =
      await supabase
        .from("messages")
        .insert({
          conversation_id: conversationId,
          user_id: user.id,
          role: "assistant",
          content: aiResponse.content,
          model: aiResponse.model,
          provider: aiResponse.provider,
          input_tokens: aiResponse.inputTokens,
          output_tokens: aiResponse.outputTokens,
          total_tokens: aiResponse.totalTokens,
          metadata: {
            latency_ms: aiResponse.latencyMs,
          },
        })
        .select("id, created_at")
        .single();

    if (assistantError || !savedAssistantMessage) {
      console.error(
        "Assistant message error:",
        assistantError
      );

      return NextResponse.json(
        {
          success: false,
          error:
            "The AI responded, but the response could not be saved.",
        },
        { status: 500 }
      );
    }

    /*
     * --------------------------------------------------------
     * SAVE USAGE
     * --------------------------------------------------------
     */

    await supabase
      .from("usage_records")
      .insert({
        user_id: user.id,
        conversation_id: conversationId,
        message_id: savedAssistantMessage.id,
        provider: aiResponse.provider,
        model: aiResponse.model,
        input_tokens: aiResponse.inputTokens,
        output_tokens: aiResponse.outputTokens,
        total_tokens: aiResponse.totalTokens,
        latency_ms: aiResponse.latencyMs,
      });

    /*
     * --------------------------------------------------------
     * UPDATE CONVERSATION
     * --------------------------------------------------------
     */

    await supabase
      .from("conversations")
      .update({
        updated_at: new Date().toISOString(),
      })
      .eq("id", conversationId)
      .eq("user_id", user.id);

    return NextResponse.json({
      success: true,

      conversationId,

      userMessage: {
        id: savedUserMessage.id,
        content: message,
        createdAt: savedUserMessage.created_at,
      },

      assistantMessage: {
        id: savedAssistantMessage.id,
        content: aiResponse.content,
        model: aiResponse.model,
        createdAt: savedAssistantMessage.created_at,
      },
    });
  } catch (error) {
    console.error(
      "Unexpected chat API error:",
      error
    );

    return NextResponse.json(
      {
        success: false,
        error: "An unexpected error occurred.",
      },
      { status: 500 }
    );
  }
}

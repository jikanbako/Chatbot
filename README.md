# AI Chatbot

A production-ready, bilingual AI chatbot platform supporting English and Hausa.

The system is designed around a modular AI architecture so that multiple AI models and providers can be used without tightly coupling the application to a single provider.

## Technology Stack

- Next.js 14.2.5
- React 18
- TypeScript
- Supabase
- PostgreSQL
- pgvector
- OpenRouter
- Zod
- Vercel
- GitHub

## Core Features

The platform is designed to support:

- Natural-language conversations
- English and Hausa
- Conversation context
- Long-term user memory
- Knowledge-base/RAG
- File uploads
- Document processing
- AI tool calling
- Web search
- Multiple AI models
- Automatic model fallback
- Usage tracking
- Conversation feedback
- Authentication
- Row Level Security
- WhatsApp integration
- Telegram integration
- Facebook Messenger integration
- Website chat
- Audit logging

## Architecture

The application uses a modular architecture:

```text
User
 |
 v
Frontend
 |
 v
Chat API
 |
 v
AI Orchestrator
 |
 +-------------------+
 |                   |
 v                   v
Memory              RAG
 |                   |
 +---------+---------+
           |
           v
         Tools
           |
           v
     Model Router
           |
           v
       OpenRouter
           |
    +------+------+------+
    |      |      |      |
    v      v      v      v
  Model  Model  Model  Fallback

Project Structure

ai-chatbot/
|
├── public/
|
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   └── health/
│   │   │       └── route.ts
│   │   │
│   │   ├── chat/
│   │   │   └── page.tsx
│   │   │
│   │   ├── login/
│   │   │   └── page.tsx
│   │   │
│   │   ├── register/
│   │   │   └── page.tsx
│   │   │
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   │
│   ├── components/
│   │   ├── auth/
│   │   ├── chat/
│   │   └── ui/
│   │
│   ├── hooks/
│   │
│   ├── lib/
│   │   ├── ai/
│   │   │   ├── orchestrator/
│   │   │   ├── providers/
│   │   │   │   └── openrouter/
│   │   │   ├── prompts/
│   │   │   ├── memory/
│   │   │   ├── rag/
│   │   │   ├── tools/
│   │   │   └── types/
│   │   │
│   │   ├── auth/
│   │   ├── db/
│   │   ├── supabase/
│   │   │   ├── client.ts
│   │   │   └── server.ts
│   │   ├── utils/
│   │   └── validation/
│   │
│   ├── types/
│   └── config/
|
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql
|
├── .env.example
├── .gitignore
├── next.config.ts
├── package.json
├── README.md
└── tsconfig.json

Environment Variables

Create a ".env.local" file in the project root.

NEXT_PUBLIC_APP_URL=http://localhost:3000

NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=

OPENROUTER_API_KEY=
OPENROUTER_SITE_URL=http://localhost:3000
OPENROUTER_APP_NAME=AI Chatbot

AI_DEFAULT_MODEL=
AI_FAST_MODEL=
AI_REASONING_MODEL=
AI_FALLBACK_MODEL=

APP_ENCRYPTION_KEY=

Never commit ".env.local" to GitHub.

Local Development

Install dependencies:

npm install

Start the development server:

npm run dev

The application will normally be available at:

http://localhost:3000

Production Build

Create a production build:

npm run build

Start the production server:

npm start

Health Check

The application contains a health endpoint:

GET /api/health

Expected response:

{
  "success": true,
  "service": "ai-chatbot",
  "status": "healthy"
}

Database

Supabase PostgreSQL is used as the main database.

The initial database schema is located at:

supabase/migrations/0001_initial_schema.sql

The database is designed for:

- Users
- Profiles
- Conversations
- Messages
- Conversation summaries
- Long-term memory
- Memory embeddings
- Files
- Knowledge documents
- Document chunks
- Feedback
- Tool calls
- AI usage
- External integrations
- Webhook events
- Audit logs

Security

Security is a core part of the architecture.

The application uses:

- Supabase Authentication
- PostgreSQL Row Level Security
- Server-side authentication
- Environment variables
- Zod validation
- Server-side AI API calls
- Tool authorization
- Audit logging

API keys must never be exposed to the browser.

AI Architecture

The application does not call OpenRouter directly from the frontend.

Instead:

Frontend
   |
   v
Chat API
   |
   v
AI Orchestrator
   |
   v
Provider Interface
   |
   v
OpenRouter
   |
   v
Selected AI Model

This allows additional AI providers to be added later without rebuilding the application.

Language Support

The chatbot is designed to automatically support:

- English
- Hausa
- Mixed English/Hausa conversations

The system should normally respond in the language used by the user unless the user explicitly requests another language.

Memory

The chatbot will eventually support two types of memory:

Conversation memory

Information needed to maintain the current conversation.

Long-term memory

Useful information that may remain relevant across future conversations.

Users should eventually be able to view, modify, and delete stored memories.

Knowledge Base

The knowledge-base system will use:

Documents
   |
   v
Text extraction
   |
   v
Chunking
   |
   v
Embeddings
   |
   v
pgvector
   |
   v
Semantic search
   |
   v
AI Orchestrator
   |
   v
Grounded response

The chatbot should distinguish between information retrieved from the knowledge base and information generated from the model's general knowledge.

AI Safety

The chatbot should:

- Avoid intentionally harmful assistance.
- Avoid illegal instructions.
- Avoid fabricating facts.
- Clearly communicate uncertainty.
- Ask clarifying questions when necessary.
- Protect private user information.
- Validate tool requests before execution.
- Never expose secret API keys.
- Avoid executing unauthorized actions.

Deployment

The intended production deployment is:

GitHub
   |
   v
Vercel
   |
   +---- Next.js application
   |
   +---- API routes

Supabase
   |
   +---- Authentication
   +---- PostgreSQL
   +---- pgvector
   +---- Storage

OpenRouter
   |
   +---- AI models

External Messaging Platforms

The architecture is designed to support:

- Website
- WhatsApp
- Telegram
- Facebook Messenger

Each platform will use an adapter/webhook layer so that external platforms do not directly interact with the internal AI implementation.

WhatsApp
Telegram
Messenger
Website
   |
   v
Message Gateway
   |
   v
Conversation Service
   |
   v
AI Orchestrator

Development Roadmap

Phase 1

Project foundation.

Phase 2

Supabase database and authentication.

Phase 3

OpenRouter provider integration.

Phase 4

First working AI chat.

Phase 5

Conversation history and context.

Phase 6

Long-term memory.

Phase 7

Knowledge base and RAG.

Phase 8

Tools and web search.

Phase 9

File and multimodal support.

Phase 10

Security, administration, analytics and monitoring.

Phase 11

WhatsApp, Telegram and Facebook Messenger.

Phase 12

Testing, optimization and production deployment.

Development Principle

The project should be built incrementally.

Each phase should be tested before moving to the next phase.

The system should favor:

- Clear architecture
- Strong security
- Maintainability
- Provider independence
- Reliable error handling
- Good user experience
- Accurate AI responses
- Transparent uncertainty
- Scalable infrastructure

:::

These files can now sit alongside the `package.json` and Supabase files we've already created.

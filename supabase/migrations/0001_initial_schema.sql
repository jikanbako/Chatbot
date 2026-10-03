-- ============================================================
-- AI CHATBOT - INITIAL DATABASE SCHEMA
-- ============================================================

create extension if not exists "vector";
create extension if not exists "pgcrypto";

-- ============================================================
-- PROFILES
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,

  full_name text,
  avatar_url text,

  preferred_language text not null default 'auto'
    check (preferred_language in ('auto', 'en', 'ha')),

  response_style text not null default 'balanced'
    check (response_style in ('concise', 'balanced', 'detailed')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- CONVERSATIONS
-- ============================================================

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  title text not null default 'New conversation',

  language text
    check (language in ('en', 'ha', 'mixed')),

  is_archived boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists conversations_user_id_idx
  on public.conversations(user_id);

create index if not exists conversations_updated_at_idx
  on public.conversations(updated_at desc);

-- ============================================================
-- MESSAGES
-- ============================================================

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),

  conversation_id uuid not null
    references public.conversations(id)
    on delete cascade,

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  role text not null
    check (role in ('user', 'assistant', 'system', 'tool')),

  content text not null,

  model text,

  provider text,

  input_tokens integer,
  output_tokens integer,
  total_tokens integer,

  tool_name text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_id_idx
  on public.messages(conversation_id);

create index if not exists messages_user_id_idx
  on public.messages(user_id);

create index if not exists messages_created_at_idx
  on public.messages(created_at);

-- ============================================================
-- CONVERSATION SUMMARIES
-- ============================================================

create table if not exists public.conversation_summaries (
  id uuid primary key default gen_random_uuid(),

  conversation_id uuid not null
    references public.conversations(id)
    on delete cascade,

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  summary text not null,

  message_count integer not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique(conversation_id)
);

-- ============================================================
-- LONG-TERM MEMORY
-- ============================================================

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  memory text not null,

  category text,

  importance smallint not null default 3
    check (importance between 1 and 5),

  source_conversation_id uuid
    references public.conversations(id)
    on delete set null,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists memories_user_id_idx
  on public.memories(user_id);

create index if not exists memories_active_idx
  on public.memories(user_id, is_active);

-- ============================================================
-- MEMORY EMBEDDINGS
-- ============================================================

create table if not exists public.memory_embeddings (
  id uuid primary key default gen_random_uuid(),

  memory_id uuid not null
    references public.memories(id)
    on delete cascade,

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  embedding vector(1536),

  created_at timestamptz not null default now(),

  unique(memory_id)
);

create index if not exists memory_embeddings_user_id_idx
  on public.memory_embeddings(user_id);

-- ============================================================
-- FILES
-- ============================================================

create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  conversation_id uuid
    references public.conversations(id)
    on delete set null,

  file_name text not null,
  storage_path text not null,
  mime_type text,
  file_size bigint,

  status text not null default 'uploaded'
    check (
      status in (
        'uploaded',
        'processing',
        'ready',
        'failed',
        'deleted'
      )
    ),

  error_message text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists files_user_id_idx
  on public.files(user_id);

create index if not exists files_conversation_id_idx
  on public.files(conversation_id);

-- ============================================================
-- KNOWLEDGE DOCUMENTS
-- ============================================================

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),

  user_id uuid
    references public.profiles(id)
    on delete cascade,

  file_id uuid
    references public.files(id)
    on delete cascade,

  title text not null,

  description text,

  source_type text not null default 'upload'
    check (
      source_type in (
        'upload',
        'website',
        'manual',
        'database'
      )
    ),

  source_url text,

  status text not null default 'pending'
    check (
      status in (
        'pending',
        'processing',
        'ready',
        'failed'
      )
    ),

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists documents_user_id_idx
  on public.documents(user_id);

-- ============================================================
-- DOCUMENT CHUNKS
-- ============================================================

create table if not exists public.document_chunks (
  id uuid primary key default gen_random_uuid(),

  document_id uuid not null
    references public.documents(id)
    on delete cascade,

  user_id uuid
    references public.profiles(id)
    on delete cascade,

  chunk_index integer not null,

  content text not null,

  embedding vector(1536),

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

create index if not exists document_chunks_document_id_idx
  on public.document_chunks(document_id);

create index if not exists document_chunks_user_id_idx
  on public.document_chunks(user_id);

-- ============================================================
-- FEEDBACK
-- ============================================================

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.profiles(id)
    on delete cascade,

  message_id uuid
    references public.messages(id)
    on delete cascade,

  rating text not null
    check (rating in ('positive', 'negative')),

  comment text,

  created_at timestamptz not null default now()
);

create index if not exists feedback_user_id_idx
  on public.feedback(user_id);

create index if not exists feedback_message_id_idx
  on public.feedback(message_id);

-- ============================================================
-- TOOL CALLS
-- ============================================================

create table if not exists public.tool_calls (
  id uuid primary key default gen_random_uuid(),

  user_id uuid
    references public.profiles(id)
    on delete cascade,

  conversation_id uuid
    references public.conversations(id)
    on delete cascade,

  message_id uuid
    references public.messages(id)
    on delete cascade,

  tool_name text not null,

  arguments jsonb not null default '{}'::jsonb,

  result jsonb,

  status text not null default 'requested'
    check (
      status in (
        'requested',
        'running',
        'completed',
        'failed',
        'denied'
      )
    ),

  error_message text,

  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists tool_calls_user_id_idx
  on public.tool_calls(user_id);

create index if not exists tool_calls_conversation_id_idx
  on public.tool_calls(conversation_id);

-- ============================================================
-- USAGE RECORDS
-- ============================================================

create table if not exists public.usage_records (
  id uuid primary key default gen_random_uuid(),

  user_id uuid
    references public.profiles(id)
    on delete set null,

  conversation_id uuid
    references public.conversations(id)
    on delete set null,

  message_id uuid
    references public.messages(id)
    on delete set null,

  provider text not null,

  model text not null,

  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  total_tokens integer not null default 0,

  estimated_cost numeric(12, 8) not null default 0,

  latency_ms integer,

  created_at timestamptz not null default now()
);

create index if not exists usage_records_user_id_idx
  on public.usage_records(user_id);

create index if not exists usage_records_created_at_idx
  on public.usage_records(created_at);

-- ============================================================
-- INTEGRATIONS
-- ============================================================

create table if not exists public.integrations (
  id uuid primary key default gen_random_uuid(),

  user_id uuid
    references public.profiles(id)
    on delete cascade,

  platform text not null
    check (
      platform in (
        'whatsapp',
        'telegram',
        'messenger',
        'website'
      )
    ),

  external_user_id text,

  metadata jsonb not null default '{}'::jsonb,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists integrations_platform_idx
  on public.integrations(platform);

create index if not exists integrations_external_user_idx
  on public.integrations(platform, external_user_id);

-- ============================================================
-- WEBHOOK EVENTS
-- ============================================================

create table if not exists public.webhook_events (
  id uuid primary key default gen_random_uuid(),

  platform text not null,

  external_event_id text not null,

  event_type text,

  payload jsonb not null default '{}'::jsonb,

  status text not null default 'received'
    check (
      status in (
        'received',
        'processing',
        'processed',
        'failed'
      )
    ),

  error_message text,

  created_at timestamptz not null default now(),
  processed_at timestamptz,

  unique(platform, external_event_id)
);

create index if not exists webhook_events_platform_idx
  on public.webhook_events(platform);

-- ============================================================
-- AUDIT LOGS
-- ============================================================

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),

  user_id uuid
    references public.profiles(id)
    on delete set null,

  action text not null,

  resource_type text,

  resource_id uuid,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

create index if not exists audit_logs_user_id_idx
  on public.audit_logs(user_id);

create index if not exists audit_logs_created_at_idx
  on public.audit_logs(created_at);

-- ============================================================
-- UPDATED_AT FUNCTION
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

drop trigger if exists profiles_updated_at on public.profiles;

create trigger profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();


drop trigger if exists conversations_updated_at on public.conversations;

create trigger conversations_updated_at
before update on public.conversations
for each row
execute function public.set_updated_at();


drop trigger if exists conversation_summaries_updated_at
on public.conversation_summaries;

create trigger conversation_summaries_updated_at
before update on public.conversation_summaries
for each row
execute function public.set_updated_at();


drop trigger if exists memories_updated_at on public.memories;

create trigger memories_updated_at
before update on public.memories
for each row
execute function public.set_updated_at();


drop trigger if exists files_updated_at on public.files;

create trigger files_updated_at
before update on public.files
for each row
execute function public.set_updated_at();


drop trigger if exists documents_updated_at on public.documents;

create trigger documents_updated_at
before update on public.documents
for each row
execute function public.set_updated_at();


drop trigger if exists integrations_updated_at
on public.integrations;

create trigger integrations_updated_at
before update on public.integrations
for each row
execute function public.set_updated_at();

-- ============================================================
-- NEW USER PROFILE
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    full_name
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    )
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.conversation_summaries enable row level security;
alter table public.memories enable row level security;
alter table public.memory_embeddings enable row level security;
alter table public.files enable row level security;
alter table public.documents enable row level security;
alter table public.document_chunks enable row level security;
alter table public.feedback enable row level security;
alter table public.tool_calls enable row level security;
alter table public.usage_records enable row level security;
alter table public.integrations enable row level security;
alter table public.audit_logs enable row level security;

-- ============================================================
-- PROFILE POLICIES
-- ============================================================

drop policy if exists profiles_select_own on public.profiles;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using (id = auth.uid());


drop policy if exists profiles_insert_own on public.profiles;

create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (id = auth.uid());


drop policy if exists profiles_update_own on public.profiles;

create policy profiles_update_own
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- ============================================================
-- CONVERSATION POLICIES
-- ============================================================

drop policy if exists conversations_select_own
on public.conversations;

create policy conversations_select_own
on public.conversations
for select
to authenticated
using (user_id = auth.uid());


drop policy if exists conversations_insert_own
on public.conversations;

create policy conversations_insert_own
on public.conversations
for insert
to authenticated
with check (user_id = auth.uid());


drop policy if exists conversations_update_own
on public.conversations;

create policy conversations_update_own
on public.conversations
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


drop policy if exists conversations_delete_own
on public.conversations;

create policy conversations_delete_own
on public.conversations
for delete
to authenticated
using (user_id = auth.uid());

-- ============================================================
-- MESSAGE POLICIES
-- ============================================================

drop policy if exists messages_select_own
on public.messages;

create policy messages_select_own
on public.messages
for select
to authenticated
using (user_id = auth.uid());


drop policy if exists messages_insert_own
on public.messages;

create policy messages_insert_own
on public.messages
for insert
to authenticated
with check (user_id = auth.uid());


drop policy if exists messages_delete_own
on public.messages;

create policy messages_delete_own
on public.messages
for delete
to authenticated
using (user_id = auth.uid());

-- ============================================================
-- MEMORY POLICIES
-- ============================================================

drop policy if exists memories_all_own
on public.memories;

create policy memories_all_own
on public.memories
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());


drop policy if exists memory_embeddings_all_own
on public.memory_embeddings;

create policy memory_embeddings_all_own
on public.memory_embeddings
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ============================================================
-- FILE POLICIES
-- ============================================================

drop policy if exists files_all_own
on public.files;

create policy files_all_own
on public.files
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ============================================================
-- DOCUMENT POLICIES
-- ============================================================

drop policy if exists documents_all_own
on public.documents;

create policy documents_all_own
on public.documents
for all
to authenticated
using (
  user_id is null
  or user_id = auth.uid()
)
with check (
  user_id is null
  or user_id = auth.uid()
);

-- ============================================================
-- DOCUMENT CHUNK POLICIES
-- ============================================================

drop policy if exists document_chunks_all_own
on public.document_chunks;

create policy document_chunks_all_own
on public.document_chunks
for all
to authenticated
using (
  user_id is null
  or user_id = auth.uid()
)
with check (
  user_id is null
  or user_id = auth.uid()
);

-- ============================================================
-- FEEDBACK POLICIES
-- ============================================================

drop policy if exists feedback_all_own
on public.feedback;

create policy feedback_all_own
on public.feedback
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ============================================================
-- TOOL CALL POLICIES
-- ============================================================

drop policy if exists tool_calls_select_own
on public.tool_calls;

create policy tool_calls_select_own
on public.tool_calls
for select
to authenticated
using (user_id = auth.uid());

-- ============================================================
-- USAGE POLICIES
-- ============================================================

drop policy if exists usage_records_select_own
on public.usage_records;

create policy usage_records_select_own
on public.usage_records
for select
to authenticated
using (user_id = auth.uid());

-- ============================================================
-- INTEGRATION POLICIES
-- ============================================================

drop policy if exists integrations_all_own
on public.integrations;

create policy integrations_all_own
on public.integrations
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ============================================================
-- AUDIT LOG POLICIES
-- ============================================================

drop policy if exists audit_logs_select_own
on public.audit_logs;

create policy audit_logs_select_own
on public.audit_logs
for select
to authenticated
using (user_id = auth.uid());

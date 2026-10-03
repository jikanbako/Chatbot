-- ============================================================
-- AI CHATBOT
-- SUPABASE STORAGE SECURITY POLICIES
-- ============================================================

-- ============================================================
-- USER FILES
-- ============================================================

drop policy if exists "Users can view their own files"
on storage.objects;

create policy "Users can view their own files"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'user-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can upload their own files"
on storage.objects;

create policy "Users can upload their own files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'user-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can update their own files"
on storage.objects;

create policy "Users can update their own files"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'user-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'user-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can delete their own files"
on storage.objects;

create policy "Users can delete their own files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'user-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


-- ============================================================
-- AVATARS
-- ============================================================

drop policy if exists "Users can view their own avatar"
on storage.objects;

create policy "Users can view their own avatar"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can upload their own avatar"
on storage.objects;

create policy "Users can upload their own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can update their own avatar"
on storage.objects;

create policy "Users can update their own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can delete their own avatar"
on storage.objects;

create policy "Users can delete their own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


-- ============================================================
-- KNOWLEDGE BASE
-- ============================================================

drop policy if exists "Users can view their own knowledge files"
on storage.objects;

create policy "Users can view their own knowledge files"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'knowledge-base'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can upload their own knowledge files"
on storage.objects;

create policy "Users can upload their own knowledge files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'knowledge-base'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can update their own knowledge files"
on storage.objects;

create policy "Users can update their own knowledge files"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'knowledge-base'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'knowledge-base'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);


drop policy if exists "Users can delete their own knowledge files"
on storage.objects;

create policy "Users can delete their own knowledge files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'knowledge-base'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

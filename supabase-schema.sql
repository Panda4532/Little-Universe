-- ============================================================
-- Little Universe — Supabase schema
-- Run this ONCE in your Supabase project: Dashboard → SQL Editor → New query
-- → paste this whole file → Run.
-- ============================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- gifts: one row per gift. owner_id links to Supabase's built-in
-- auth.users — no separate "users" table needed, since the name
-- the person typed at signup is stored in auth user_metadata.
-- ------------------------------------------------------------
create table if not exists public.gifts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default '',
  dob date,
  unknown_year boolean not null default false,
  occasion text not null default 'birthday',
  theme text not null default 'birthday',
  messages jsonb not null default '{"main":"","love":"","story":"","dreams":""}',
  little jsonb not null default '{"nickname":"","joke":"","memory":"","habit":"","phrase":"","owe":""}',
  music_url text not null default '',
  music_file_url text not null default '',
  music_path text,
  bg_intensity text not null default 'balanced',
  published boolean not null default false,
  views integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gifts enable row level security;

create policy "owners manage their own gifts"
  on public.gifts for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "anyone can view a published gift"
  on public.gifts for select
  using (published = true);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists gifts_set_updated_at on public.gifts;
create trigger gifts_set_updated_at
  before update on public.gifts
  for each row execute procedure public.set_updated_at();

-- Lets an anonymous recipient's view count go up without granting
-- them any other access to the row.
create or replace function public.increment_gift_views(gift_id uuid)
returns void as $$
begin
  update public.gifts set views = views + 1
  where id = gift_id and published = true;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.increment_gift_views(uuid) to anon, authenticated;

-- ------------------------------------------------------------
-- gift_photos: ordered photos belonging to a gift
-- ------------------------------------------------------------
create table if not exists public.gift_photos (
  id uuid primary key default gen_random_uuid(),
  gift_id uuid not null references public.gifts(id) on delete cascade,
  url text not null,
  path text,
  caption text default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.gift_photos enable row level security;

create policy "owners manage photos on their own gifts"
  on public.gift_photos for all
  using (exists (select 1 from public.gifts g where g.id = gift_id and g.owner_id = auth.uid()))
  with check (exists (select 1 from public.gifts g where g.id = gift_id and g.owner_id = auth.uid()));

create policy "anyone can view photos of a published gift"
  on public.gift_photos for select
  using (exists (select 1 from public.gifts g where g.id = gift_id and g.published = true));

-- Explicit table grants (Supabase normally sets these up automatically for
-- new projects, but this makes the requirement explicit and safe to re-run).
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.gifts to authenticated;
grant select on public.gifts to anon;
grant select, insert, update, delete on public.gift_photos to authenticated;
grant select on public.gift_photos to anon;

-- ------------------------------------------------------------
-- Storage: one public bucket for photos + uploaded soundtracks.
-- Public READ is required so a recipient with no account, on any
-- device, can load the images/audio. WRITE is restricted to the
-- authenticated owner, inside a folder named after their user id.
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('gift-media', 'gift-media', true)
on conflict (id) do nothing;

create policy "public read access to gift media"
  on storage.objects for select
  using (bucket_id = 'gift-media');

create policy "authenticated users upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'gift-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "authenticated users delete their own files"
  on storage.objects for delete
  using (
    bucket_id = 'gift-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ChatConnect: Guidance Counselor side.
-- Run this once in the Supabase dashboard → SQL Editor (or `supabase db push`).
--
-- Tables:
--   profiles           one row per auth user, with role 'student' | 'counselor'
--   appointments       student booking requests, handled by counselors
--   crisis_alerts      raised when Kai chat detects a crisis (keyword or AI)
--   counselor_threads  one chat thread per student with the Guidance Office
--   counselor_messages messages inside a thread
--
-- Access rules (RLS): students only ever see their own rows; counselors see
-- everyone's. Nobody can make themselves a counselor from the app — promote
-- an account by hand (see the bottom of this file).

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- profiles
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text not null,
  full_name   text not null default '',
  student_id  text,
  course      text,
  role        text not null default 'student'
              check (role in ('student', 'counselor')),
  created_at  timestamptz not null default now()
);

-- security definer so policies can call it without recursing into
-- profiles' own RLS.
create or replace function public.is_counselor()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'counselor'
  );
$$;

-- Every new auth user gets a student profile. Role is never read from
-- sign-up metadata, so a client can't sign itself up as a counselor.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, student_id, course)
  values (
    new.id,
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''),
             split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'student_id',
    new.raw_user_meta_data ->> 'course'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own" on public.profiles
  for select using (id = auth.uid());

drop policy if exists "profiles: counselors read all" on public.profiles;
create policy "profiles: counselors read all" on public.profiles
  for select using (public.is_counselor());

-- Students need counselor names for the chat header.
drop policy if exists "profiles: read counselors" on public.profiles;
create policy "profiles: read counselors" on public.profiles
  for select using (auth.uid() is not null and role = 'counselor');
-- No insert/update/delete policies: the trigger creates rows, and roles
-- are changed only from the SQL editor.

-- Shared updated_at helper.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ------------------------------------------------------------ appointments
create table if not exists public.appointments (
  id                  uuid primary key default gen_random_uuid(),
  student_id          uuid not null references public.profiles (id) on delete cascade,
  type                text not null check (type in ('academic', 'personal', 'crisis')),
  subject             text not null,
  description         text,
  preferred_at        timestamptz not null,
  status              text not null default 'pending'
                      check (status in ('pending', 'confirmed', 'declined')),
  counselor_note      text,
  handled_by          uuid references public.profiles (id),
  calendar_event_link text,
  meet_link           text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index if not exists appointments_student_idx on public.appointments (student_id);

drop trigger if exists appointments_touch on public.appointments;
create trigger appointments_touch before update on public.appointments
  for each row execute function public.touch_updated_at();

alter table public.appointments enable row level security;

drop policy if exists "appointments: read own or counselor" on public.appointments;
create policy "appointments: read own or counselor" on public.appointments
  for select using (student_id = auth.uid() or public.is_counselor());

drop policy if exists "appointments: students request" on public.appointments;
create policy "appointments: students request" on public.appointments
  for insert with check (
    student_id = auth.uid()
    and status = 'pending'
    and handled_by is null
    and counselor_note is null
  );

drop policy if exists "appointments: counselors handle" on public.appointments;
create policy "appointments: counselors handle" on public.appointments
  for update using (public.is_counselor()) with check (public.is_counselor());

-- ----------------------------------------------------------- crisis_alerts
-- source: 'keyword' = kai-backend's hardcoded filter (hard signal, SOS shown)
--         'ai'      = Gemini's is_crisis judgment (soft signal)
create table if not exists public.crisis_alerts (
  id             uuid primary key default gen_random_uuid(),
  student_id     uuid not null references public.profiles (id) on delete cascade,
  source         text not null check (source in ('keyword', 'ai')),
  excerpt        text check (char_length(excerpt) <= 500),
  status         text not null default 'new'
                 check (status in ('new', 'acknowledged', 'contacted', 'resolved')),
  counselor_note text,
  handled_by     uuid references public.profiles (id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists crisis_alerts_status_idx on public.crisis_alerts (status, created_at desc);

drop trigger if exists crisis_alerts_touch on public.crisis_alerts;
create trigger crisis_alerts_touch before update on public.crisis_alerts
  for each row execute function public.touch_updated_at();

alter table public.crisis_alerts enable row level security;

-- Students can raise an alert about themselves but can't read alerts back.
drop policy if exists "alerts: students raise own" on public.crisis_alerts;
create policy "alerts: students raise own" on public.crisis_alerts
  for insert with check (
    student_id = auth.uid() and status = 'new' and handled_by is null
  );

drop policy if exists "alerts: counselors read" on public.crisis_alerts;
create policy "alerts: counselors read" on public.crisis_alerts
  for select using (public.is_counselor());

drop policy if exists "alerts: counselors handle" on public.crisis_alerts;
create policy "alerts: counselors handle" on public.crisis_alerts
  for update using (public.is_counselor()) with check (public.is_counselor());

-- ------------------------------------------------------- counselor chat
create table if not exists public.counselor_threads (
  id                   uuid primary key default gen_random_uuid(),
  student_id           uuid not null unique references public.profiles (id) on delete cascade,
  last_message_at      timestamptz not null default now(),
  last_message_preview text,
  last_sender_id       uuid references public.profiles (id),
  created_at           timestamptz not null default now()
);

alter table public.counselor_threads enable row level security;

drop policy if exists "threads: read own or counselor" on public.counselor_threads;
create policy "threads: read own or counselor" on public.counselor_threads
  for select using (student_id = auth.uid() or public.is_counselor());

drop policy if exists "threads: open own or counselor" on public.counselor_threads;
create policy "threads: open own or counselor" on public.counselor_threads
  for insert with check (student_id = auth.uid() or public.is_counselor());

create table if not exists public.counselor_messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.counselor_threads (id) on delete cascade,
  sender_id  uuid not null references public.profiles (id),
  body       text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index if not exists counselor_messages_thread_idx
  on public.counselor_messages (thread_id, created_at);

alter table public.counselor_messages enable row level security;

drop policy if exists "messages: read in own thread or counselor" on public.counselor_messages;
create policy "messages: read in own thread or counselor" on public.counselor_messages
  for select using (
    exists (
      select 1 from public.counselor_threads t
      where t.id = thread_id
        and (t.student_id = auth.uid() or public.is_counselor())
    )
  );

drop policy if exists "messages: send as self" on public.counselor_messages;
create policy "messages: send as self" on public.counselor_messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.counselor_threads t
      where t.id = thread_id
        and (t.student_id = auth.uid() or public.is_counselor())
    )
  );

-- Keep each thread's preview fresh for the counselor's chat list.
create or replace function public.bump_thread()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update public.counselor_threads
     set last_message_at = new.created_at,
         last_message_preview = left(new.body, 140),
         last_sender_id = new.sender_id
   where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists counselor_messages_bump on public.counselor_messages;
create trigger counselor_messages_bump after insert on public.counselor_messages
  for each row execute function public.bump_thread();

-- ---------------------------------------------------------------- realtime
-- Lets the app receive inserts/updates live (RLS still applies).
do $$
declare t text;
begin
  foreach t in array array['appointments', 'crisis_alerts', 'counselor_threads', 'counselor_messages']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ------------------------------------------------------ making a counselor
-- 1. Create the account: Dashboard → Authentication → Users → Add user.
-- 2. Then run (with the counselor's email):
--
--   update public.profiles
--      set role = 'counselor', full_name = 'Ms. Aurine'
--    where email = 'counselor@wvsu.edu.ph';

-- ChatConnect: second sign-in step for counselors (staff school ID).
-- Run after 20261108000000_counselor_side.sql.
--
-- After email + password, a counselor must enter their WVSU staff school ID
-- (e.g. 001325). The ID is stored only as a bcrypt hash in a table the app
-- can't read, and checked by verify_staff_id(). Counselor access in every
-- RLS policy (is_counselor()) also requires that the *current login session*
-- passed this check, so skipping the screen in the app gets a counselor
-- nothing.
--
-- IDs are compared trimmed and upper-case (letters, digits, dashes; 3–20).
-- 5 wrong tries in a row lock verification for 15 minutes.

-- ------------------------------------------------------------------ tables
create table if not exists public.staff_ids (
  user_id          uuid primary key references public.profiles (id) on delete cascade,
  id_hash          text not null,
  failed_attempts  int not null default 0,
  locked_until     timestamptz,
  updated_at       timestamptz not null default now()
);

-- One row per login session that passed the staff ID check.
create table if not exists public.staff_id_sessions (
  session_id   uuid primary key,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  verified_at  timestamptz not null default now()
);

-- RLS on with no policies: the app can't read or write these directly.
alter table public.staff_ids enable row level security;
alter table public.staff_id_sessions enable row level security;

-- Supabase puts the login session's id in every access token.
create or replace function public.current_session_id()
returns uuid
language sql stable
as $$
  select nullif(auth.jwt() ->> 'session_id', '')::uuid;
$$;

create or replace function public.normalize_staff_id(raw text)
returns text
language sql immutable
as $$
  select upper(btrim(coalesce(raw, '')));
$$;

-- ------------------------------------------------- counselor access check
-- Same as before, plus: this login session must have passed the staff ID
-- check.
create or replace function public.is_counselor()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
      from public.profiles p
      join public.staff_id_sessions s
        on s.user_id = p.id
       and s.session_id = public.current_session_id()
     where p.id = auth.uid() and p.role = 'counselor'
  );
$$;

-- -------------------------------------------------------- staff ID check
-- Returns one of: 'ok', 'wrong', 'locked', 'no_id', 'not_counselor'.
create or replace function public.verify_staff_id(p_staff_id text)
returns text
language plpgsql security definer set search_path = public, extensions
as $$
declare
  rec public.staff_ids%rowtype;
  sid uuid := public.current_session_id();
begin
  if auth.uid() is null or sid is null or not exists (
    select 1 from public.profiles where id = auth.uid() and role = 'counselor'
  ) then
    return 'not_counselor';
  end if;

  select * into rec from public.staff_ids where user_id = auth.uid() for update;
  if not found then
    return 'no_id';
  end if;

  if rec.locked_until is not null and rec.locked_until > now() then
    return 'locked';
  end if;

  if rec.id_hash = crypt(public.normalize_staff_id(p_staff_id), rec.id_hash) then
    update public.staff_ids
       set failed_attempts = 0, locked_until = null
     where user_id = auth.uid();
    insert into public.staff_id_sessions (session_id, user_id)
    values (sid, auth.uid())
    on conflict (session_id) do update set verified_at = now();
    return 'ok';
  end if;

  update public.staff_ids
     set failed_attempts = failed_attempts + 1,
         locked_until = case when failed_attempts + 1 >= 5
                             then now() + interval '15 minutes' end
   where user_id = auth.uid();
  return case when rec.failed_attempts + 1 >= 5 then 'locked' else 'wrong' end;
end;
$$;

revoke all on function public.verify_staff_id(text) from public, anon;
grant execute on function public.verify_staff_id(text) to authenticated;

-- Has this login session already passed the staff ID check? (So a page
-- reload doesn't ask again.)
create or replace function public.staff_id_verified()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.staff_id_sessions
     where session_id = public.current_session_id() and user_id = auth.uid()
  );
$$;

revoke all on function public.staff_id_verified() from public, anon;
grant execute on function public.staff_id_verified() to authenticated;

-- ------------------------------------ recording a counselor's staff ID
-- Admin only (SQL editor). Also clears any lockout.
--
--   select public.set_staff_id('counselor@wvsu.edu.ph', '001325');
create or replace function public.set_staff_id(p_email text, p_staff_id text)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  uid uuid;
  clean text := public.normalize_staff_id(p_staff_id);
begin
  if clean !~ '^[A-Z0-9-]{3,20}$' then
    raise exception 'Staff school ID must be 3–20 letters, digits or dashes';
  end if;
  select id into uid from public.profiles
   where lower(email) = lower(p_email) and role = 'counselor';
  if uid is null then
    raise exception 'No counselor account with email %', p_email;
  end if;
  insert into public.staff_ids (user_id, id_hash)
  values (uid, crypt(clean, gen_salt('bf')))
  on conflict (user_id) do update
    set id_hash = excluded.id_hash,
        failed_attempts = 0,
        locked_until = null,
        updated_at = now();
end;
$$;

-- Not callable from the app at all.
revoke all on function public.set_staff_id(text, text) from public, anon, authenticated;

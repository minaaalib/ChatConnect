-- ChatConnect: create a test counselor + student account in one go.
-- Paste into Supabase → SQL Editor → New query. Edit the 5 values below
-- first, then Run. Safe to run again (existing accounts are skipped).
-- Don't save real passwords in this file.

do $$
declare
  -- Type each value between $v$ and $v$ (apostrophes are fine there).
  counselor_email    text := $v$counselor@example.com$v$;   -- ← change
  counselor_password text := $v$ChangeMe123!$v$;            -- ← change
  student_email      text := $v$student@example.com$v$;     -- ← change
  student_password   text := $v$ChangeMe123!$v$;            -- ← change
  staff_school_id    text := $v$001325$v$;
  acct record;
  uid  uuid;
begin
  for acct in
    select * from (values
      (counselor_email, counselor_password, 'Ms. Aurine', null::text, null::text),
      (student_email, student_password, 'Juan Dela Cruz', '2025-12345', 'BS Information Technology')
    ) as v(email, pw, full_name, student_id, course)
  loop
    if exists (select 1 from auth.users where lower(email) = lower(acct.email)) then
      raise notice 'Account % already exists, skipped', acct.email;
      continue;
    end if;

    uid := gen_random_uuid();
    -- The handle_new_user trigger makes the matching public.profiles row.
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new
    ) values (
      '00000000-0000-0000-0000-000000000000', uid, 'authenticated',
      'authenticated', lower(acct.email),
      extensions.crypt(acct.pw, extensions.gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object(
        'full_name', acct.full_name,
        'student_id', acct.student_id,
        'course', acct.course
      ),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (
      provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      uid::text, uid,
      jsonb_build_object('sub', uid::text, 'email', lower(acct.email), 'email_verified', true),
      'email', now(), now(), now()
    );
  end loop;

  -- Accounts made before the tables existed have no profile yet: add one.
  insert into public.profiles (id, email)
  select u.id, u.email from auth.users u
   where not exists (select 1 from public.profiles p where p.id = u.id);

  update public.profiles
     set role = 'counselor', full_name = 'Ms. Aurine'
   where lower(email) = lower(counselor_email);

  perform public.set_staff_id(counselor_email, staff_school_id);
end $$;

-- Check the result.
select email, full_name, role, student_id, course
  from public.profiles
 order by role, email;

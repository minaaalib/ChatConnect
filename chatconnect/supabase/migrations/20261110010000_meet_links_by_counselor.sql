-- ChatConnect: only counselors set Google Meet / Calendar links.
-- Run after 20261108000000_counselor_side.sql.
--
-- The counselor web app creates the Meet when confirming an appointment.
-- Students' new requests must not carry a link of their own (a student
-- could otherwise put any URL behind the counselor's "Join" button).

drop policy if exists "appointments: students request" on public.appointments;
create policy "appointments: students request" on public.appointments
  for insert with check (
    student_id = auth.uid()
    and status = 'pending'
    and handled_by is null
    and counselor_note is null
    and meet_link is null
    and calendar_event_link is null
  );

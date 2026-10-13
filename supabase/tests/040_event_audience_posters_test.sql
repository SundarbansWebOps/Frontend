-- pgTAP: event audience, posters and RC house-wide approval (migration event_audience_posters).
-- Self-contained: builds its own fixtures and runs inside begin … rollback. Ids start with b4.
begin;
select no_plan();

create temp table fx (k text primary key, id uuid, email text, region text);
insert into fx values
  ('sa1', 'b4000000-0000-4000-8000-000000000001', '99f9400001@ds.study.iitm.ac.in', 'region_01'),
  ('sa2', 'b4000000-0000-4000-8000-000000000002', '99f9400002@ds.study.iitm.ac.in', 'region_01'),
  ('rc1', 'b4000000-0000-4000-8000-000000000003', '99f9400003@ds.study.iitm.ac.in', 'region_01'),
  ('rc2', 'b4000000-0000-4000-8000-000000000004', '99f9400004@ds.study.iitm.ac.in', 'region_02');
grant select on fx to authenticated, service_role;

insert into public.member_roster (email, full_name, phone, region_id, added_by)
  select fx.email, 'Fixture ' || fx.k, null, (select id from public.regions where code = fx.region),
         (select user_id from public.super_admin_allowlist limit 1)
  from fx;
-- First Google sign-in (the sign-up trigger accepts only the Google provider).
insert into auth.users (id, email, aud, role, raw_app_meta_data)
  select fx.id, fx.email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from fx;
insert into public.super_admin_allowlist (user_id, label)
  select id, 'test ' || k from fx where k in ('sa1', 'sa2');
insert into public.admin_assignments (member_id, position, region_id, assigned_by)
  select fx.id, 'rc', (select id from public.regions where code = fx.region), (select id from fx where k = 'sa1')
  from fx where k in ('rc1', 'rc2');

-- ── RC: own region directly ─────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b4000000-0000-4000-8000-000000000003","role":"authenticated"}';

select lives_ok($$ insert into public.events (name, starts_at, ends_at, region_id, published_at, is_public)
                   values ('Patna quiz', now() + interval '2 days', now() + interval '3 days',
                           (select id from public.regions where code = 'region_01'), now(), true) $$,
  'RC publishes a Public event for their own region');
select lives_ok($$ insert into public.events (name, starts_at, ends_at, region_id, published_at)
                   values ('Patna members meet', now() + interval '2 days', now() + interval '3 days',
                           (select id from public.regions where code = 'region_01'), now()) $$,
  'RC publishes a members-only event for their own region');
select throws_ok($$ insert into public.events (name, starts_at, ends_at, region_id)
                   values ('Delhi quiz', now() + interval '2 days', now() + interval '3 days',
                           (select id from public.regions where code = 'region_02')) $$,
  '42501', null, 'RC cannot create an event for another region');
select throws_ok($$ insert into public.events (name, starts_at, ends_at, region_id, image_url)
                   values ('Bad poster', now() + interval '2 days', now() + interval '3 days',
                           (select id from public.regions where code = 'region_01'), 'https://evil.example/x.png') $$,
  '23514', null, 'posters must come from the house Cloudinary account');

-- ── RC: house-wide needs a Super Admin ──────────────────────────────────────
select lives_ok($$ insert into public.events (name, starts_at, ends_at, is_public)
                   values ('House fest', now() + interval '5 days', now() + interval '6 days', true) $$,
  'RC drafts a house-wide event');
select throws_ok($$ insert into public.events (name, starts_at, ends_at, published_at)
                   values ('House fest 2', now() + interval '5 days', now() + interval '6 days', now()) $$,
  '42501', null, 'RC cannot create a published house-wide event');
select throws_ok($$ update public.events set published_at = now() where name = 'House fest' $$,
  '42501', null, 'RC cannot publish a house-wide draft directly');
select lives_ok($$ update public.events set description = 'Food and music' where name = 'House fest' $$,
  'RC edits their own house-wide draft');
select lives_ok($$ select public.request_event_publish((select id from public.events where name = 'House fest')) $$,
  'RC asks a Super Admin to publish it');
select throws_ok($$ select public.request_event_publish((select id from public.events where name = 'House fest')) $$,
  '23505', null, 'only one pending publish request per event');
select throws_ok($$ update public.events set description = 'Changed' where name = 'House fest' $$,
  'PT409', null, 'the draft is frozen while a Super Admin reviews it');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b4000000-0000-4000-8000-000000000004","role":"authenticated"}';
select is_empty($$ select 1 from public.events where name = 'House fest' $$,
  'another RC cannot see someone else''s house-wide draft');
select throws_ok($$ select public.request_event_publish((select id from public.events where name = 'Patna quiz')) $$,
  '42501', null, 'an RC cannot ask to publish an event they did not draft as house-wide');
reset role;

-- Poster signing check (the Edge Function's database step), run as the service role.
set local role service_role;
select lives_ok($$ select public.svc_event_image_target('b4000000-0000-4000-8000-000000000003',
                     (select id from public.events where name = 'Patna quiz')) $$,
  'the RC may upload a poster for their region''s event');
select throws_ok($$ select public.svc_event_image_target('b4000000-0000-4000-8000-000000000004',
                     (select id from public.events where name = 'Patna quiz')) $$,
  '42501', null, 'another region''s RC may not');
select throws_ok($$ select public.svc_event_image_target('b4000000-0000-4000-8000-000000000003',
                     (select id from public.events where name = 'House fest')) $$,
  'PT409', null, 'no poster changes while the draft waits for approval');
select lives_ok($$ select public.svc_event_image_target('b4000000-0000-4000-8000-000000000001',
                     (select id from public.events where name = 'House fest')) $$,
  'a Super Admin may upload for any event');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b4000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$ select public.approve_request((select id from public.approval_requests
                    where type = 'event_publish' and status = 'pending'
                      and target_event_id = (select id from public.events where name = 'House fest'))) $$,
  'a Super Admin approves the house-wide event');
select ok((select published_at is not null from public.events where name = 'House fest'),
  'the approved event is published');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b4000000-0000-4000-8000-000000000003","role":"authenticated"}';
update public.events set description = 'After approval' where name = 'House fest';
select results_eq($$ select description from public.events where name = 'House fest' $$,
  $$ values ('Food and music'::text) $$, 'once published, the RC can no longer edit the house-wide event');
reset role;

-- ── Public listing ──────────────────────────────────────────────────────────
set local role anon;
select ok(exists (select 1 from jsonb_array_elements(public.list_public_events()) x
                  where x ->> 'name' = 'Patna quiz' and x ->> 'stage' = 'upcoming'),
  'an upcoming Public event is on the public page');
select ok(exists (select 1 from jsonb_array_elements(public.list_public_events()) x
                  where x ->> 'name' = 'House fest'),
  'the approved Public house-wide event is on the public page');
select ok(not exists (select 1 from jsonb_array_elements(public.list_public_events()) x
                      where x ->> 'name' = 'Patna members meet'),
  'a members-only upcoming event is not on the public page');
select ok((select count(*) from jsonb_array_elements(public.list_public_events()) x
           where x ->> 'stage' = 'past') >= 43, 'the archive is still listed');
select is_empty($$ select 1 from public.events where name = 'Patna members meet' $$,
  'signed-out visitors cannot read members-only upcoming events');
reset role;

select * from finish();
rollback;

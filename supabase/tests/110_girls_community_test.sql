-- pgTAP: Girls members-only community (migration 20261023120000_girls_community).
-- Synthetic identities only (ids start with b6100000, codes 99f961xxxx). Everything rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('b6100000-0000-4000-8000-000000000098', '99f9610098', '99f9610098@ds.study.iitm.ac.in', 1);
create temp table gc(k text primary key, id uuid, email text);
insert into gc values
 ('sa', 'b6100000-0000-4000-8000-000000000001', '99f9610001@ds.study.iitm.ac.in'),
 ('gh', 'b6100000-0000-4000-8000-000000000002', '99f9610002@ds.study.iitm.ac.in'),
 ('th', 'b6100000-0000-4000-8000-000000000003', '99f9610003@ds.study.iitm.ac.in'),
 ('rc', 'b6100000-0000-4000-8000-000000000004', '99f9610004@ds.study.iitm.ac.in'),
 ('gm', 'b6100000-0000-4000-8000-000000000005', '99f9610005@ds.study.iitm.ac.in'),
 ('pm', 'b6100000-0000-4000-8000-000000000006', '99f9610006@ds.study.iitm.ac.in');
grant select on gc to authenticated, anon;
insert into public.member_roster(email, region_id, added_by)
select email, 1, 'b6100000-0000-4000-8000-000000000098' from gc;
-- Pending student: on the house roster, not signed in yet.
insert into public.member_roster(email, region_id, added_by)
values ('99f9610050@ds.study.iitm.ac.in', 1, 'b6100000-0000-4000-8000-000000000098');
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from gc;
insert into public.super_admin_allowlist(user_id, label) select id, 'Test SA girls' from gc where k = 'sa';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'head', null, (select id from public.communities where code = 'girls'), (select id from gc where k = 'sa') from gc where k = 'gh';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'head', null, (select id from public.communities where code = 'technical'), (select id from gc where k = 'sa') from gc where k = 'th';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'rc', 1, null, (select id from gc where k = 'sa') from gc where k = 'rc';

-- ── The community ───────────────────────────────────────────────────────────
select ok((select members_only and name = 'Girls' from public.communities where code = 'girls'), 'girls row exists and is members-only');
select ok((select not members_only from public.communities where code = 'technical'), 'technical stays house-wide');
set local role anon;
select is((select members_only from public.communities where code = 'girls'), true, 'members_only is readable by signed-out visitors');
reset role;

-- ── Super Admin manages the list ────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.add_community_members((select id from public.communities where code = 'girls'),
  array['  99F9610005@DS.study.iitm.ac.in ', '99f9610005@ds.study.iitm.ac.in', 'not-an-email', '', '   ',
        '99f9610050@ds.study.iitm.ac.in', 'outsider.person@ds.study.iitm.ac.in']),
  '{"added":3,"already":0,"invalid":["not-an-email"],"not_in_house":["outsider.person@ds.study.iitm.ac.in"]}'::jsonb,
  'Super Admin adds: trims, lowercases, dedupes, reports invalid and not-in-house');
select is(public.add_community_members((select id from public.communities where code = 'girls'),
  array['99f9610005@ds.study.iitm.ac.in', 'outsider.person@ds.study.iitm.ac.in']),
  '{"added":0,"already":2,"invalid":[],"not_in_house":[]}'::jsonb, 'adding again counts already-listed emails');
select throws_ok($$select public.add_community_members((select id from public.communities where code = 'technical'), array['99f9610006@ds.study.iitm.ac.in'])$$,
  '22023', null, 'a house-wide community has no list');
select throws_ok($$select public.add_community_members((select id from public.communities where code = 'girls'), array[]::text[])$$,
  '22023', null, 'an empty batch is rejected');
select throws_ok($$select public.add_community_members((select id from public.communities where code = 'girls'),
  (select array_agg('x' || g || '@ds.study.iitm.ac.in') from generate_series(1, 2001) g))$$,
  '22023', null, 'more than 2000 emails is rejected');
select lives_ok($$select public.remove_community_member((select id from public.communities where code = 'girls'), ' Outsider.Person@ds.study.iitm.ac.in')$$,
  'Super Admin removes an email');
select throws_ok($$select public.remove_community_member((select id from public.communities where code = 'girls'), 'outsider.person@ds.study.iitm.ac.in')$$,
  'P0002', null, 'removing an email that is not listed is not-found');
select throws_ok($$select public.remove_community_member((select id from public.communities where code = 'girls'), null)$$,
  '22023', null, 'removing needs an email');
select is((select jsonb_agg(x->>'email' order by ord) from jsonb_array_elements(public.list_community_members((select id from public.communities where code = 'girls'))) with ordinality t(x, ord)),
  '["99f9610005@ds.study.iitm.ac.in","99f9610050@ds.study.iitm.ac.in"]'::jsonb, 'Super Admin lists emails ordered by email');
select is((select x->'member'->>'member_code' from jsonb_array_elements(public.list_community_members((select id from public.communities where code = 'girls'))) x where x->>'email' = '99f9610005@ds.study.iitm.ac.in'),
  '99f9610005', 'signed-in list member carries basic member data');
select is((select x - 'added_at' from jsonb_array_elements(public.list_community_members((select id from public.communities where code = 'girls'))) x where x->>'email' = '99f9610050@ds.study.iitm.ac.in'),
  '{"email":"99f9610050@ds.study.iitm.ac.in","member":null,"on_roster":true}'::jsonb, 'pending student: no member, on roster');
reset role;

select is((select count(*)::int from public.community_members where community_id = (select id from public.communities where code = 'girls')), 2, 'two emails stored');
select is((select count(*)::int from public.audit_log where action = 'community_member.add' and actor_id = 'b6100000-0000-4000-8000-000000000001'), 2, 'each add batch writes one audit row');
select is((select new_values from public.audit_log where action = 'community_member.add' and actor_id = 'b6100000-0000-4000-8000-000000000001' order by id limit 1) - 'community_id',
  '{"added":3,"already":0,"invalid":1,"not_in_house":1}'::jsonb, 'add audit carries counts only, no emails');
select is((select count(*)::int from public.audit_log where action = 'community_member.remove' and actor_id = 'b6100000-0000-4000-8000-000000000001'), 1, 'remove is audited');

-- ── Girls Head reads, never writes ──────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(jsonb_array_length(public.list_community_members((select id from public.communities where code = 'girls'))), 2, 'Girls Head lists their community');
select is((select count(*)::int from public.community_members), 2, 'Girls Head reads the list table');
select throws_ok($$select public.add_community_members((select id from public.communities where code = 'girls'), array['99f9610006@ds.study.iitm.ac.in'])$$,
  '42501', null, 'Girls Head cannot add');
select throws_ok($$select public.remove_community_member((select id from public.communities where code = 'girls'), '99f9610005@ds.study.iitm.ac.in')$$,
  '42501', null, 'Girls Head cannot remove');
select throws_ok($$insert into public.community_members(community_id, email) values ((select id from public.communities where code = 'girls'), '99f9610006@ds.study.iitm.ac.in')$$,
  '42501', null, 'Girls Head cannot write the table directly');
select throws_ok($$delete from public.community_members$$, '42501', null, 'Girls Head cannot delete from the table directly');
reset role;

-- ── Everyone else reads nothing ─────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.list_community_members((select id from public.communities where code = 'girls'))$$, '42501', null, 'Technical Head cannot list Girls');
select is_empty($$select 1 from public.community_members$$, 'Technical Head reads no list rows');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000004","role":"authenticated"}';
select throws_ok($$select public.list_community_members((select id from public.communities where code = 'girls'))$$, '42501', null, 'RC cannot list Girls');
select is_empty($$select 1 from public.community_members$$, 'RC reads no list rows');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000005","role":"authenticated"}';
select throws_ok($$select public.list_community_members((select id from public.communities where code = 'girls'))$$, '42501', null, 'a listed member cannot list');
select is_empty($$select 1 from public.community_members$$, 'a listed member reads no list rows');
reset role;
set local role anon;
select throws_ok($$select public.list_community_members(1::smallint)$$, '42501', null, 'anon cannot call the list RPC');
reset role;

-- ── Content fixtures ────────────────────────────────────────────────────────
create temp table gcx(k text primary key, id uuid);
insert into gcx values
 ('girls_up',   'b6100000-0000-4000-8000-0000000000e1'),
 ('girls_past', 'b6100000-0000-4000-8000-0000000000e2'),
 ('tech_past',  'b6100000-0000-4000-8000-0000000000e3'),
 ('tech_up',    'b6100000-0000-4000-8000-0000000000e4'),
 ('girls_event_form', 'b6100000-0000-4000-8000-0000000000f1'),
 ('girls_group_form', 'b6100000-0000-4000-8000-0000000000f2'),
 ('tech_form',        'b6100000-0000-4000-8000-0000000000f3'),
 ('girls_notice', 'b6100000-0000-4000-8000-0000000000a1'),
 ('tech_notice',  'b6100000-0000-4000-8000-0000000000a2');
grant select on gcx to authenticated, anon;
insert into public.events(id, name, community_id, starts_at, ends_at, published_at, created_by, updated_by)
select x.id, x.k, (select id from public.communities where code = case when x.k like 'girls%' then 'girls' else 'technical' end),
       case when x.k like '%past' then now() - interval '2 days' else now() + interval '1 day' end,
       case when x.k like '%past' then now() - interval '1 day' else now() + interval '2 days' end,
       now() - interval '1 minute', (select id from gc where k = 'sa'), (select id from gc where k = 'sa')
from gcx x where x.k in ('girls_up', 'girls_past', 'tech_past', 'tech_up');
insert into public.lounge_forms(id, title, event_id, published_at, created_by)
values ('b6100000-0000-4000-8000-0000000000f1', 'Girls event registration', 'b6100000-0000-4000-8000-0000000000e1', now() - interval '1 minute', (select id from gc where k = 'sa'));
insert into public.lounge_forms(id, title, community_id, form_kind, group_label, published_at, created_by)
values ('b6100000-0000-4000-8000-0000000000f2', 'Girls group', (select id from public.communities where code = 'girls'), 'group', 'Girls WhatsApp', now() - interval '1 minute', (select id from gc where k = 'sa')),
       ('b6100000-0000-4000-8000-0000000000f3', 'Tech group', (select id from public.communities where code = 'technical'), 'group', 'Tech WhatsApp', now() - interval '1 minute', (select id from gc where k = 'sa'));
insert into private.lounge_form_invites(form_id, invite_url)
values ('b6100000-0000-4000-8000-0000000000f2', 'https://chat.whatsapp.com/GirlsTest123'),
       ('b6100000-0000-4000-8000-0000000000f3', 'https://chat.whatsapp.com/TechTest123');
insert into public.announcements(id, title, body, community_id, starts_at, published_at, created_by)
values ('b6100000-0000-4000-8000-0000000000a1', 'Girls notice', 'For the list', (select id from public.communities where code = 'girls'), now() - interval '1 minute', now() - interval '1 minute', (select id from gc where k = 'sa')),
       ('b6100000-0000-4000-8000-0000000000a2', 'Tech notice', 'For everyone', (select id from public.communities where code = 'technical'), now() - interval '1 minute', now() - interval '1 minute', (select id from gc where k = 'sa'));

-- ── A listed member sees and uses Girls content ─────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000005","role":"authenticated"}';
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e1'), 'listed member sees the upcoming Girls event');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e2'), 'listed member sees the past Girls event in the lounge');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_forms()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000f1'), 'listed member sees the Girls event form');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_forms()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000f2'), 'listed member sees the Girls group form');
select ok(exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a1'), 'listed member sees the Girls notice');
select is((select count(*)::int from public.events where id in ('b6100000-0000-4000-8000-0000000000e1', 'b6100000-0000-4000-8000-0000000000e2')), 2, 'listed member selects Girls events directly');
select is((select count(*)::int from public.lounge_forms where id in ('b6100000-0000-4000-8000-0000000000f1', 'b6100000-0000-4000-8000-0000000000f2')), 2, 'listed member selects Girls forms directly');
select is((select count(*)::int from public.announcements where id = 'b6100000-0000-4000-8000-0000000000a1'), 1, 'listed member selects the Girls notice directly');
select lives_ok($$select public.set_my_notice_state('b6100000-0000-4000-8000-0000000000a1', true, true)$$, 'listed member reads and dismisses the Girls notice');
select lives_ok($$select public.submit_lounge_form('b6100000-0000-4000-8000-0000000000f1', '{}'::jsonb)$$, 'listed member registers for the Girls event');
select is((select count(*)::int from public.event_registrations where event_id = 'b6100000-0000-4000-8000-0000000000e1' and member_id = auth.uid()), 1, 'registration recorded');
select lives_ok($$select public.submit_lounge_form('b6100000-0000-4000-8000-0000000000f2', '{}'::jsonb)$$, 'listed member submits the Girls group form');
select is(public.get_lounge_form_invite('b6100000-0000-4000-8000-0000000000f2'), 'https://chat.whatsapp.com/GirlsTest123', 'listed member gets the Girls invite');
reset role;

-- ── A member not on the list sees and uses nothing ──────────────────────────
-- Simulate a response left over from an earlier listing, so the invite path is checked on its own.
insert into public.form_responses(form_id, member_id, submitted_email, field_schema, answers)
values ('b6100000-0000-4000-8000-0000000000f2', 'b6100000-0000-4000-8000-000000000006', '99f9610006@ds.study.iitm.ac.in', '[]'::jsonb, '{}'::jsonb);
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000006","role":"authenticated"}';
select ok(not exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' in ('b6100000-0000-4000-8000-0000000000e1', 'b6100000-0000-4000-8000-0000000000e2')), 'non-listed member sees no Girls event, upcoming or past');
select ok(not exists(select 1 from jsonb_array_elements(public.list_lounge_forms()) x where x->>'id' in ('b6100000-0000-4000-8000-0000000000f1', 'b6100000-0000-4000-8000-0000000000f2')), 'non-listed member sees no Girls form, even one they answered');
select ok(not exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a1'), 'non-listed member sees no Girls notice');
select is_empty($$select 1 from public.events where id in ('b6100000-0000-4000-8000-0000000000e1', 'b6100000-0000-4000-8000-0000000000e2')$$, 'non-listed member selects no Girls event');
select is_empty($$select 1 from public.lounge_forms where id in ('b6100000-0000-4000-8000-0000000000f1', 'b6100000-0000-4000-8000-0000000000f2')$$, 'non-listed member selects no Girls form');
select is_empty($$select 1 from public.announcements where id = 'b6100000-0000-4000-8000-0000000000a1'$$, 'non-listed member selects no Girls notice');
select throws_ok($$select public.set_my_notice_state('b6100000-0000-4000-8000-0000000000a1')$$, '42501', null, 'non-listed member cannot mark the Girls notice');
select throws_ok($$select public.submit_lounge_form('b6100000-0000-4000-8000-0000000000f1', '{}'::jsonb)$$, '42501', null, 'non-listed member cannot register for the Girls event');
select throws_ok($$select public.submit_lounge_form('b6100000-0000-4000-8000-0000000000f2', '{}'::jsonb)$$, '42501', null, 'non-listed member cannot submit the Girls group form');
select is(public.get_lounge_form_invite('b6100000-0000-4000-8000-0000000000f2'), null, 'non-listed member gets no Girls invite');
select throws_ok($$select public.submit_community_registration((select id from public.communities where code = 'girls'), '{}'::jsonb)$$, '42501', null, 'non-listed member cannot self-join the Girls community');
-- Technical content stays house-wide.
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e4'), 'non-listed member still sees the Technical event');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_forms()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000f3'), 'non-listed member still sees the Technical form');
select ok(exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a2'), 'non-listed member still sees the Technical notice');
select lives_ok($$select public.submit_lounge_form('b6100000-0000-4000-8000-0000000000f3', '{}'::jsonb)$$, 'non-listed member submits the Technical form');
select is(public.get_lounge_form_invite('b6100000-0000-4000-8000-0000000000f3'), 'https://chat.whatsapp.com/TechTest123', 'non-listed member gets the Technical invite');
reset role;

-- RC and another community's Head see no Girls content either.
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000004","role":"authenticated"}';
select is_empty($$select 1 from public.events where id = 'b6100000-0000-4000-8000-0000000000e1'$$, 'RC selects no Girls event');
select ok(not exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a1'), 'RC sees no Girls notice');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000003","role":"authenticated"}';
select is_empty($$select 1 from public.lounge_forms where id = 'b6100000-0000-4000-8000-0000000000f2'$$, 'Technical Head selects no Girls form');
reset role;

-- ── Never in the public archive ─────────────────────────────────────────────
set local role anon;
select ok(not exists(select 1 from public.list_public_past_events() where id = 'b6100000-0000-4000-8000-0000000000e2'), 'past Girls event absent from list_public_past_events');
select ok(exists(select 1 from public.list_public_past_events() where id = 'b6100000-0000-4000-8000-0000000000e3'), 'past Technical event still in list_public_past_events');
select ok(not exists(select 1 from jsonb_array_elements(public.list_public_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e2'), 'past Girls event absent from list_public_events');
select ok(exists(select 1 from jsonb_array_elements(public.list_public_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e3'), 'past Technical event still in list_public_events');
select is_empty($$select 1 from public.public_events where id = 'b6100000-0000-4000-8000-0000000000e2'$$, 'past Girls event absent from public_events');
select is_empty($$select 1 from public.events where id = 'b6100000-0000-4000-8000-0000000000e2'$$, 'anon selects no past Girls event');
select isnt_empty($$select 1 from public.events where id = 'b6100000-0000-4000-8000-0000000000e3'$$, 'anon still selects the past Technical event');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000005","role":"authenticated"}';
select ok(not exists(select 1 from public.list_public_past_events() where id = 'b6100000-0000-4000-8000-0000000000e2'), 'the public archive excludes Girls events even for listed members');
reset role;

-- ── is_public can never expose a Girls event ────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$update public.events set is_public = true where id = 'b6100000-0000-4000-8000-0000000000e1'$$,
  '22023', 'Members-only community events cannot be public', 'even a Super Admin cannot make a Girls event public');
reset role;
select throws_ok($$insert into public.events(name, community_id, starts_at, ends_at, is_public, created_by, updated_by)
  values ('Girls public', (select id from public.communities where code = 'girls'), now() + interval '1 day', now() + interval '2 days', true,
          'b6100000-0000-4000-8000-000000000001', 'b6100000-0000-4000-8000-000000000001')$$,
  '22023', null, 'a service write cannot insert a public Girls event');

-- ── Girls Head still organizes ──────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$insert into public.events(name, community_id, starts_at, ends_at, published_at)
  values ('Girls head meetup', (select id from public.communities where code = 'girls'), now() + interval '3 days', now() + interval '4 days', now())$$,
  'Girls Head creates and publishes a Girls event');
select throws_ok($$insert into public.events(name, community_id, starts_at, ends_at, published_at, is_public)
  values ('Girls head public', (select id from public.communities where code = 'girls'), now() + interval '3 days', now() + interval '4 days', now(), true)$$,
  '22023', null, 'Girls Head cannot create a public Girls event');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'name' = 'Girls head meetup' and (x->>'can_manage')::boolean), 'Girls Head sees and manages the new event');
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000e1'), 'Girls Head sees the Girls event without being on the list');
select lives_ok($$select public.save_announcement(jsonb_build_object('id','b6100000-0000-4000-8000-0000000000a3','title','Girls head notice','body','From the Head','community_id',(select id from public.communities where code = 'girls')))$$,
  'Girls Head saves a Girls notice');
select lives_ok($$select public.set_announcement_published('b6100000-0000-4000-8000-0000000000a3', true)$$, 'Girls Head publishes the Girls notice');
select is((select published_at is not null from public.announcements where id = 'b6100000-0000-4000-8000-0000000000a3'), true, 'the Girls notice is published');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000005","role":"authenticated"}';
select ok(exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a3'), 'listed member sees the Head''s notice');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000006","role":"authenticated"}';
select ok(not exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a3'), 'non-listed member does not see the Head''s notice');
select is_empty($$select 1 from public.events where name = 'Girls head meetup'$$, 'non-listed member does not see the Head''s event');
reset role;
-- Technical Head still publishes a public Technical event.
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000003","role":"authenticated"}';
select lives_ok($$insert into public.events(name, community_id, starts_at, ends_at, published_at, is_public)
  values ('Tech public night', (select id from public.communities where code = 'technical'), now() + interval '3 days', now() + interval '4 days', now(), true)$$,
  'Technical Head still creates a public Technical event');
reset role;
set local role anon;
select ok(exists(select 1 from jsonb_array_elements(public.list_public_events()) x where x->>'name' = 'Tech public night'), 'the public Technical event is listed publicly');
reset role;

-- ── Removal takes effect at once ────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.remove_community_member((select id from public.communities where code = 'girls'), '99f9610005@ds.study.iitm.ac.in')$$, 'Super Admin removes the listed member');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"b6100000-0000-4000-8000-000000000005","role":"authenticated"}';
select ok(not exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id' = 'b6100000-0000-4000-8000-0000000000a1'), 'removed member no longer sees the Girls notice');
select is(public.get_lounge_form_invite('b6100000-0000-4000-8000-0000000000f2'), null, 'removed member no longer gets the Girls invite');
reset role;

select * from finish();
rollback;

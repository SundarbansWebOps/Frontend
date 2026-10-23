-- pgTAP: community tags, join forms, tag-removal requests and the Students list
-- (migration 20261023202050_community_tags). Synthetic identities only (ids start with c1200000,
-- codes 99f962xxxx). Everything rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('c1200000-0000-4000-8000-000000000098', '99f9620098', '99f9620098@ds.study.iitm.ac.in', 1);
create temp table ct(k text primary key, id uuid, email text, region smallint);
insert into ct values
 ('sa', 'c1200000-0000-4000-8000-000000000001', '99f9620001@ds.study.iitm.ac.in', 1),
 ('th', 'c1200000-0000-4000-8000-000000000002', '99f9620002@ds.study.iitm.ac.in', 1),
 ('eh', 'c1200000-0000-4000-8000-000000000003', '99f9620003@ds.study.iitm.ac.in', 1),
 ('rc', 'c1200000-0000-4000-8000-000000000004', '99f9620004@ds.study.iitm.ac.in', 1),
 ('s1', 'c1200000-0000-4000-8000-000000000005', '99f9620005@ds.study.iitm.ac.in', 1),
 ('s2', 'c1200000-0000-4000-8000-000000000006', '99f9620006@ds.study.iitm.ac.in', 2),
 ('s4', 'c1200000-0000-4000-8000-000000000007', '99f9620007@ds.study.iitm.ac.in', 1);
grant select on ct to authenticated, anon;
insert into public.member_roster(email, region_id, added_by) select email, region, 'c1200000-0000-4000-8000-000000000098' from ct;
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from ct;
update public.members set full_name = 'Tara Techwala', phone = '+919876543210' where id = 'c1200000-0000-4000-8000-000000000005';
-- Not signed in yet: on the roster only.
insert into public.member_roster(email, full_name, region_id, added_by)
values ('99f9620050@ds.study.iitm.ac.in', 'Rosie Roster', 2, 'c1200000-0000-4000-8000-000000000098');
insert into public.super_admin_allowlist(user_id, label) select id, 'Test SA tags' from ct where k = 'sa';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'head', null, (select id from public.communities where code = 'technical'), (select id from ct where k = 'sa') from ct where k = 'th';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'co_head', null, (select id from public.communities where code = 'esports'), (select id from ct where k = 'sa') from ct where k = 'eh';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'rc', 1, null, (select id from ct where k = 'sa') from ct where k = 'rc';
insert into public.community_members(community_id, email, added_by)
values ((select id from public.communities where code = 'girls'), '99f9620007@ds.study.iitm.ac.in', 'c1200000-0000-4000-8000-000000000001');

-- ── Community content reaches the whole house, Girls excepted ───────────────
insert into public.events(id, name, community_id, starts_at, ends_at, published_at, created_by, updated_by)
values ('c1200000-0000-4000-8000-0000000000e1', 'Esports night', (select id from public.communities where code = 'esports'),
        now() + interval '1 day', now() + interval '2 days', now() - interval '1 minute', 'c1200000-0000-4000-8000-000000000001', 'c1200000-0000-4000-8000-000000000001');
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000006","role":"authenticated"}';
select ok(exists(select 1 from jsonb_array_elements(public.list_lounge_events()) x where x->>'id' = 'c1200000-0000-4000-8000-0000000000e1'),
  'an untagged student in another region sees the E-Sports event');
reset role;

-- ── Join forms ──────────────────────────────────────────────────────────────
-- A Super Admin publishes them; their Head edits and reviews them from here on.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1200000-0000-4000-8000-0000000000f1','title','Join Technical',
  'community_id',(select id from public.communities where code = 'technical'),'published_at',now() - interval '1 minute','joins_community',true))$$,
  'Super Admin publishes a Technical join form');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1200000-0000-4000-8000-0000000000f2','title','Technical survey',
  'community_id',(select id from public.communities where code = 'technical'),'published_at',now() - interval '1 minute'))$$,
  'Super Admin publishes an ordinary Technical form');
reset role;
select is((select joins_community from public.lounge_forms where id = 'c1200000-0000-4000-8000-0000000000f1'), true, 'the switch is stored');
select is((select joins_community from public.lounge_forms where id = 'c1200000-0000-4000-8000-0000000000f2'), false, 'the switch defaults off');
select throws_ok($$update public.lounge_forms set joins_community = true, community_id = null where id = 'c1200000-0000-4000-8000-0000000000f2'$$,
  '23514', null, 'a join form needs a community');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000005","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('c1200000-0000-4000-8000-0000000000f1', '{}'::jsonb)$$, 's1 answers the join form');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000006","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('c1200000-0000-4000-8000-0000000000f1', '{}'::jsonb)$$, 's2 answers the join form');
select lives_ok($$select public.submit_lounge_form('c1200000-0000-4000-8000-0000000000f2', '{}'::jsonb)$$, 's2 answers the ordinary form');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response(r.id, 'approved', r.submitted_at) from public.form_responses r
  where r.form_id = 'c1200000-0000-4000-8000-0000000000f1' and r.member_id = 'c1200000-0000-4000-8000-000000000005'$$, 'Head approves s1 on the join form');
select lives_ok($$select public.review_form_response(r.id, 'rejected', r.submitted_at, 'Not this term') from public.form_responses r
  where r.form_id = 'c1200000-0000-4000-8000-0000000000f1' and r.member_id = 'c1200000-0000-4000-8000-000000000006'$$, 'Head rejects s2 on the join form');
select lives_ok($$select public.review_form_response(r.id, 'approved', r.submitted_at) from public.form_responses r
  where r.form_id = 'c1200000-0000-4000-8000-0000000000f2'$$, 'Head approves s2 on the ordinary form');
reset role;
select is((select added_by from public.community_members where community_id = (select id from public.communities where code = 'technical') and email = '99f9620005@ds.study.iitm.ac.in'),
  'c1200000-0000-4000-8000-000000000002'::uuid, 'approval on a join form tags the student, by the reviewer');
select is((select count(*)::int from public.community_members where email = '99f9620006@ds.study.iitm.ac.in'), 0, 'rejection and ordinary forms add no tag');

-- Turning the switch on later tags responses already approved; a save without the key keeps it.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1200000-0000-4000-8000-0000000000f2','title','Technical survey',
  'community_id',(select id from public.communities where code = 'technical'),'published_at',now() - interval '1 minute','joins_community',true))$$,
  'Head turns the ordinary form into a join form');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1200000-0000-4000-8000-0000000000f2','title','Technical survey, renamed',
  'community_id',(select id from public.communities where code = 'technical'),'published_at',now() - interval '1 minute'))$$,
  'Head saves it again without the switch');
reset role;
select is((select count(*)::int from public.community_members where community_id = (select id from public.communities where code = 'technical') and email = '99f9620006@ds.study.iitm.ac.in'), 1,
  'turning the switch on tags the already-approved response');
select is((select joins_community from public.lounge_forms where id = 'c1200000-0000-4000-8000-0000000000f2'), true, 'a save without the key keeps the switch');

-- ── Super Admin tags directly ───────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.add_community_members((select id from public.communities where code = 'technical'),
  array['99f9620050@ds.study.iitm.ac.in', '99f9620005@ds.study.iitm.ac.in', 'stranger@ds.study.iitm.ac.in']),
  '{"added":1,"already":1,"invalid":[],"not_in_house":["stranger@ds.study.iitm.ac.in"]}'::jsonb,
  'any community takes tags; emails outside the house are skipped');
reset role;
select is((select count(*)::int from public.community_members where email = 'stranger@ds.study.iitm.ac.in'), 0, 'the outsider was not stored');

-- ── One Students list ───────────────────────────────────────────────────────
create temp table tid as select (select id from public.communities where code = 'technical') as tech, (select id from public.communities where code = 'girls') as girls;
grant select on tid to authenticated;
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((select jsonb_agg(r->>'email' order by r->>'email') from jsonb_array_elements(public.list_students(p_community => (select tech from tid))->'rows') r),
  '["99f9620005@ds.study.iitm.ac.in","99f9620006@ds.study.iitm.ac.in","99f9620050@ds.study.iitm.ac.in"]'::jsonb, 'Super Admin filters by community, members and roster together');
select is((select r - 'joined_at' from jsonb_array_elements(public.list_students(p_query => '99f9620050')->'rows') r),
  jsonb_build_object('kind','roster','id',null,'email','99f9620050@ds.study.iitm.ac.in','member_code',null,'full_name','Rosie Roster','preferred_name',null,
    'phone',null,'gender',null,'region_id',2,'account_status','not_signed_in','communities',jsonb_build_array((select tech from tid))),
  'email search finds a roster student, with their tags');
select is((public.list_students(p_query => 'rosie')->>'total')::int, 0, 'a name search does not reach roster students');
select is((select r->>'email' from jsonb_array_elements(public.list_students(p_query => 'tara tech')->'rows') r), '99f9620005@ds.study.iitm.ac.in', 'name search finds a signed-in student');
select is((select r->>'email' from jsonb_array_elements(public.list_students(p_query => '98765 43210')->'rows') r), '99f9620005@ds.study.iitm.ac.in', 'a spaced phone number matches');
select is((select r->>'email' from jsonb_array_elements(public.list_students(p_query => '99f9620005')->'rows') r), '99f9620005@ds.study.iitm.ac.in', 'roll number search finds a signed-in student');
select ok((select bool_and(r->>'kind' = 'roster') from jsonb_array_elements(public.list_students(p_status => 'not_signed_in')->'rows') r), 'not_signed_in lists roster rows only');
select is((select r->'communities' from jsonb_array_elements(public.list_students(p_query => '99f9620007')->'rows') r), jsonb_build_array((select girls from tid)), 'Super Admin sees Girls tags');
select throws_ok($$select public.list_students(p_query => 'ta')$$, '22023', null, 'search needs three characters');
select lives_ok($$select public.list_students(p_status => 'deleted')$$, 'Super Admin lists deleted students');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((select jsonb_agg(r->>'email' order by r->>'email') from jsonb_array_elements(public.list_students()->'rows') r),
  '["99f9620005@ds.study.iitm.ac.in","99f9620006@ds.study.iitm.ac.in","99f9620050@ds.study.iitm.ac.in"]'::jsonb, 'Technical Head sees only Technical students');
select is((select r->>'phone' from jsonb_array_elements(public.list_students()->'rows') r where r->>'email' = '99f9620005@ds.study.iitm.ac.in'), '+919876543210', 'Head sees phone numbers');
select throws_ok($$select public.list_students(p_status => 'deleted')$$, '22023', null, 'only a Super Admin lists deleted students');
select throws_ok($$select public.list_students(p_community => (select girls from tid))$$, '42501', null, 'Technical Head cannot filter by Girls');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000004","role":"authenticated"}';
select ok((select bool_and((r->>'region_id')::int = 1) from jsonb_array_elements(public.list_students()->'rows') r), 'RC sees only their region');
select ok(not exists(select 1 from jsonb_array_elements(public.list_students()->'rows') r where r->>'email' in ('99f9620006@ds.study.iitm.ac.in', '99f9620050@ds.study.iitm.ac.in')), 'RC does not see other regions, tagged or not');
select is((select r->'communities' from jsonb_array_elements(public.list_students()->'rows') r where r->>'email' = '99f9620007@ds.study.iitm.ac.in'), '[]'::jsonb, 'RC does not see Girls tags');
select is((select r->'communities' from jsonb_array_elements(public.list_students()->'rows') r where r->>'email' = '99f9620005@ds.study.iitm.ac.in'), jsonb_build_array((select tech from tid)), 'RC sees other tags');
select throws_ok($$select public.list_students(p_community => (select girls from tid))$$, '42501', null, 'RC cannot filter by Girls');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000006","role":"authenticated"}';
select throws_ok($$select public.list_students()$$, '42501', null, 'a student cannot list students');
reset role;

-- ── Removal goes through Requests ───────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620005@ds.study.iitm.ac.in', '  ')$$, '22023', null, 'a removal needs a reason');
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620007@ds.study.iitm.ac.in', 'Left')$$, 'P0002', null, 'an untagged email is not found');
select lives_ok($$select public.request_community_tag_removal((select tech from tid), ' 99F9620005@ds.study.iitm.ac.in ', 'Left the community')$$, 'Head asks to remove a signed-in student');
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620005@ds.study.iitm.ac.in', 'Again')$$, '23505', null, 'one pending removal per tag');
select lives_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620050@ds.study.iitm.ac.in', 'Wrong list')$$, 'Head asks to remove a roster student');
select lives_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620006@ds.study.iitm.ac.in', 'Moved away')$$, 'Head asks for a second signed-in student');
select is((select count(*)::int from jsonb_array_elements(public.admin_dashboard_requests('pending')->'rows') r where r->>'type' = 'community_tag_removal'), 3, 'Head reads their own requests');
select throws_ok($$delete from public.community_members$$, '42501', null, 'Head cannot delete tags directly');
reset role;
select is((select target_member_id from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620005@ds.study.iitm.ac.in'),
  'c1200000-0000-4000-8000-000000000005'::uuid, 'a signed-in student is the request target');
select is((select target_member_id from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620050@ds.study.iitm.ac.in'),
  'c1200000-0000-4000-8000-000000000002'::uuid, 'a roster student falls back to the requester');
select is((select target_snapshot->'member'->>'full_name' from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620050@ds.study.iitm.ac.in'),
  'Rosie Roster', 'the roster name is in the snapshot');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620005@ds.study.iitm.ac.in', 'Not mine')$$, '42501', null, 'another community''s Co-Head cannot ask');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000004","role":"authenticated"}';
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620005@ds.study.iitm.ac.in', 'Not mine')$$, '42501', null, 'an RC cannot ask');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1200000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.request_community_tag_removal((select tech from tid), '99f9620005@ds.study.iitm.ac.in', 'x')$$, '42501', null, 'a Super Admin removes directly instead');
select lives_ok($$select public.approve_request(id) from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620005@ds.study.iitm.ac.in'$$, 'Super Admin approves the removal');
select lives_ok($$select public.reject_request(id, 'Keep them') from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620006@ds.study.iitm.ac.in'$$, 'Super Admin rejects another');
select lives_ok($$select public.remove_community_member((select tech from tid), '99f9620050@ds.study.iitm.ac.in')$$, 'Super Admin removes the roster tag meanwhile');
select throws_ok($$select public.approve_request(id) from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620050@ds.study.iitm.ac.in'$$, 'PT409', null, 'approving a removal already done is a conflict');
reset role;
select is((select count(*)::int from public.community_members where community_id = (select tech from tid) and email = '99f9620005@ds.study.iitm.ac.in'), 0, 'approved removal deletes the tag');
select is((select count(*)::int from public.community_members where community_id = (select tech from tid) and email = '99f9620006@ds.study.iitm.ac.in'), 1, 'rejected removal keeps the tag');
select is((select status::text || '/' || (executed_at is not null)::text from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620005@ds.study.iitm.ac.in'), 'approved/true', 'the request is approved and executed');
select is((select count(*)::int from public.audit_log where action = 'request.approve' and target_id = (select id::text from public.approval_requests where type = 'community_tag_removal' and requested_change->>'email' = '99f9620005@ds.study.iitm.ac.in')), 1, 'approval is audited');

select * from finish();
rollback;

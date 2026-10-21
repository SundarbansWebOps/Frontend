-- Synthetic identities only. Every fixture rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, full_name, preferred_name, phone, gender, region_id, cohort)
values
 ('e1000000-0000-4000-8000-000000000098', '99f1920098', '99f1920098@ds.study.iitm.ac.in', 'Lookup adder', null, null, null, 1, '99F1'),
 ('e1000000-0000-4000-8000-000000000002', '99f1920002', '99f1920002@ds.study.iitm.ac.in', 'Lookup coordinator', null, null, null, 1, '99F1'),
 ('e1000000-0000-4000-8000-000000000003', '99f1920003', '99f1920003@ds.study.iitm.ac.in', 'Lookup head', null, null, null, 1, '99F1'),
 ('e1000000-0000-4000-8000-000000000004', '99f1920004', '99f1920004@ds.study.iitm.ac.in', 'Lookup co-head', null, null, null, 1, '99F1'),
 ('e1000000-0000-4000-8000-000000000005', '99f1920005', '99f1920005@ds.study.iitm.ac.in', 'Lookup plain', null, null, null, 2, '99F1'),
 ('e1000000-0000-4000-8000-000000000006', '99f1920006', '99f1920006@ds.study.iitm.ac.in', 'Far student', 'Faraway', '+919000000006', 'F', 2, '99F1'),
 ('e1000000-0000-4000-8000-000000000007', '99f1920007', '99f1920007@ds.study.iitm.ac.in', 'Lookup past head', null, null, null, 1, '99F1');

-- The allowlist references auth.users, so the Super Admin signs up through the roster claim.
insert into public.member_roster(email, full_name, region_id, added_by)
values ('99f1920001@ds.study.iitm.ac.in', 'Lookup super', 1, 'e1000000-0000-4000-8000-000000000098');
insert into auth.users(id, email, aud, role, raw_app_meta_data)
values ('e1000000-0000-4000-8000-000000000001', '99f1920001@ds.study.iitm.ac.in', 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb);
insert into public.super_admin_allowlist(user_id, label) values ('e1000000-0000-4000-8000-000000000001', 'Lookup fixture');
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
values
 ('e1000000-0000-4000-8000-000000000002', 'rc', 1, null, 'e1000000-0000-4000-8000-000000000001'),
 ('e1000000-0000-4000-8000-000000000003', 'head', null, (select id from public.communities where code = 'technical'), 'e1000000-0000-4000-8000-000000000001'),
 ('e1000000-0000-4000-8000-000000000004', 'co_head', null, (select id from public.communities where code = 'cultural'), 'e1000000-0000-4000-8000-000000000001');
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by, ended_at)
values ('e1000000-0000-4000-8000-000000000007', 'head', null, (select id from public.communities where code = 'esports'), 'e1000000-0000-4000-8000-000000000001', now());
-- Far student holds a position in a region the lookups below cross into.
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
values ('e1000000-0000-4000-8000-000000000006', 'rc', 2, null, 'e1000000-0000-4000-8000-000000000001');

insert into public.member_roster(email, full_name, phone, gender, region_id, added_by)
values ('waiting.person@ds.study.iitm.ac.in', 'Waiting Person', '+919000000099', 'M', 2, 'e1000000-0000-4000-8000-000000000098');

insert into public.lounge_forms(id, title, form_kind, group_label, created_by, published_at)
values ('e1000000-0000-4000-8000-0000000000f1', 'Lookup group form', 'group', 'Group A', 'e1000000-0000-4000-8000-000000000098', now());
insert into public.form_responses(form_id, member_id, submitted_email, field_schema, answers)
values ('e1000000-0000-4000-8000-0000000000f1', 'e1000000-0000-4000-8000-000000000006', '99f1920006@ds.study.iitm.ac.in', '[]'::jsonb, '{}'::jsonb);

-- Region 1 RC looks at a student in region 2: crossing scope is the point of the feature.
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->>'found', 'true', 'RC finds a student from another region');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->>'source', 'student', 'Signed-in person is a student');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->>'phone', '+919000000006', 'Phone is returned to every admin role');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->>'preferred_name', 'Faraway', 'Preferred name is returned');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->>'roll_number', '99f1920006', 'Roll number is returned');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->>'region_name', (select name from public.regions where id = 2), 'Region name is returned');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->'position'->>'position', 'rc', 'Current position is returned');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->'forms'->0->>'group_label', 'Group A', 'Form context carries the group label');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->'forms'->0->>'form_title', 'Lookup group form', 'Form context carries the form title');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'pending', 'null'::jsonb, 'A student has no pending block');
select is(public.admin_lookup_email('  99F1920006@DS.Study.IITM.ac.in ')->>'found', 'true', 'Lookup trims and ignores case');
select is(public.admin_lookup_email('99f1920005@ds.study.iitm.ac.in')->'student'->'position', 'null'::jsonb, 'No position for a plain student');
select is(public.admin_lookup_email('99f1920005@ds.study.iitm.ac.in')->'student'->'forms', '[]'::jsonb, 'No forms for a student without responses');
select is(public.admin_lookup_email('99f1920007@ds.study.iitm.ac.in')->'student'->'position', 'null'::jsonb, 'An ended position is not current');

select is(public.admin_lookup_email('WAITING.person@ds.study.iitm.ac.in')->>'source', 'pending', 'Roster-only email is pending');
select is(public.admin_lookup_email('waiting.person@ds.study.iitm.ac.in')->'pending'->>'phone', '+919000000099', 'Pending phone is returned');
select is(public.admin_lookup_email('waiting.person@ds.study.iitm.ac.in')->'pending'->>'cohort', null, 'Cohort is empty when the email has none');
select is(public.admin_lookup_email('waiting.person@ds.study.iitm.ac.in')->'pending'->'added_by'->>'full_name', 'Lookup adder', 'Pending row names who added it');
select is(public.admin_lookup_email('waiting.person@ds.study.iitm.ac.in')->'student', 'null'::jsonb, 'Pending has no student block');

select is(public.admin_lookup_email('nobody@ds.study.iitm.ac.in')->>'found', 'false', 'Unknown email is not found');
select is(public.admin_lookup_email('nobody@ds.study.iitm.ac.in')->>'source', null, 'Unknown email has no source');
select is(public.admin_lookup_email('99f192000@ds.study.iitm.ac.in')->>'found', 'false', 'A partial email never matches');
select throws_ok($$select public.admin_lookup_email('99f1920006')$$, '22023', 'Enter a full email address', 'A non-email is rejected');
select throws_ok($$select public.admin_lookup_email('')$$, '22023', 'Enter a full email address', 'Empty input is rejected');
select throws_ok($$select public.admin_lookup_email(null)$$, '22023', 'Enter a full email address', 'Null input is rejected');
select throws_ok($$select public.admin_lookup_email('%@%')$$, '22023', 'Enter a full email address', 'Wildcards are not an email');
reset role;

-- Roster and member at once returns both blocks (members.email unique, roster email primary key).
insert into public.member_roster(email, full_name, phone, region_id, added_by)
values ('99f1920005@ds.study.iitm.ac.in', 'Stale roster row', '+919000000098', 1, 'e1000000-0000-4000-8000-000000000098');
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.admin_lookup_email('99f1920005@ds.study.iitm.ac.in')->>'source', 'student', 'Student wins as the source');
select is(public.admin_lookup_email('99f1920005@ds.study.iitm.ac.in')->'pending'->>'full_name', 'Stale roster row', 'Both blocks are returned');
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->'student'->>'is_super_admin', 'false', 'Super Admin flag is false for others');
select is(public.admin_lookup_email('99f1920001@ds.study.iitm.ac.in')->'student'->>'is_super_admin', 'true', 'Super Admin flag is true for Super Admins');
reset role;

-- Head and Co-Head
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000003","role":"authenticated"}';
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->>'found', 'true', 'Head can look up across regions');
select is(public.admin_lookup_email('99f1920002@ds.study.iitm.ac.in')->'student'->'position'->>'position', 'rc', 'Position shows the coordinator');
select is(public.admin_lookup_email('99f1920003@ds.study.iitm.ac.in')->'student'->'position'->>'community_name', 'Technical', 'Community name is returned for a head');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000004","role":"authenticated"}';
select is(public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')->>'found', 'true', 'Co-Head can look up');
reset role;

-- Audit trail: every lookup leaves a row, found or not.
select ok((select count(*) from public.audit_log where action = 'member.lookup') >= 20, 'Lookups are audited');
select is((select new_values->>'found' from public.audit_log where action = 'member.lookup'
  and actor_id = 'e1000000-0000-4000-8000-000000000004' order by id desc limit 1), 'true', 'Audit row records the result');
select is((select target_id from public.audit_log where action = 'member.lookup'
  and actor_id = 'e1000000-0000-4000-8000-000000000004' order by id desc limit 1), 'e1000000-0000-4000-8000-000000000006', 'Audit row targets the student');
select is((select new_values->>'email' from public.audit_log where action = 'member.lookup'
  and actor_id = 'e1000000-0000-4000-8000-000000000004' order by id desc limit 1), '99f1920006@ds.study.iitm.ac.in', 'Audit row records the searched email');

-- Denied: ordinary member, ended head, suspended admin, anon.
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000005","role":"authenticated"}';
select throws_ok($$select public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')$$, '42501', 'Admin access is required', 'Ordinary members are denied');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000007","role":"authenticated"}';
select throws_ok($$select public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')$$, '42501', 'Admin access is required', 'A former head is denied');
reset role;
update public.members set account_status = 'suspended' where id = 'e1000000-0000-4000-8000-000000000003';
set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')$$, '42501', 'Admin access is required', 'A suspended head is denied');
reset role;
set local role anon;
select throws_ok($$select public.admin_lookup_email('99f1920006@ds.study.iitm.ac.in')$$, '42501', null, 'Anonymous callers have no execute grant');
reset role;

select * from finish();
rollback;

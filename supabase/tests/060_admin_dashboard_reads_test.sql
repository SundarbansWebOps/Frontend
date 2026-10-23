-- Synthetic identities only. Every fixture rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('ad190000-0000-4000-8000-000000000098', '99f1910098', '99f1910098@ds.study.iitm.ac.in', 1);
create temp table desk_people(id uuid, email text, full_name text, region_id smallint);
insert into desk_people values
 ('ad190000-0000-4000-8000-000000000001', '99f1910001@ds.study.iitm.ac.in', 'Desk approver', 1),
 ('ad190000-0000-4000-8000-000000000002', '99f1910002@ds.study.iitm.ac.in', 'Desk coordinator', 1),
 ('ad190000-0000-4000-8000-000000000003', '99f1910003@ds.study.iitm.ac.in', 'Desk student', 1),
 ('ad190000-0000-4000-8000-000000000004', '99f1910004@ds.study.iitm.ac.in', 'Other region student', 2),
 ('ad190000-0000-4000-8000-000000000005', '99f1910005@ds.study.iitm.ac.in', 'Desk head', 1);
insert into public.member_roster(email, full_name, region_id, added_by)
select email, full_name, region_id, 'ad190000-0000-4000-8000-000000000098' from desk_people;
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from desk_people;
insert into public.super_admin_allowlist(user_id, label) values ('ad190000-0000-4000-8000-000000000001', 'Desk fixture');
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
values ('ad190000-0000-4000-8000-000000000002', 'rc', 1, null, 'ad190000-0000-4000-8000-000000000001'),
 ('ad190000-0000-4000-8000-000000000005', 'head', null, 1, 'ad190000-0000-4000-8000-000000000001');
insert into public.member_roster(email, full_name, region_id, added_by)
values ('99f1910010@ds.study.iitm.ac.in', 'Waiting here', 1, 'ad190000-0000-4000-8000-000000000001'),
 ('99f1910011@ds.study.iitm.ac.in', 'Waiting elsewhere', 2, 'ad190000-0000-4000-8000-000000000001');

set local role authenticated;
set local request.jwt.claims = '{"sub":"ad190000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.request_member_update('ad190000-0000-4000-8000-000000000003', '{"full_name":"Desk new name"}', 'Spelling correction')$$, 'RC files a student change');
select is((public.admin_dashboard_summary()->'regions'->0->>'id')::int, 1, 'RC sees their own region');
select is(jsonb_array_length(public.admin_dashboard_summary()->'regions'), 1, 'RC cannot read another region aggregate');
select is((public.admin_dashboard_summary()->'counts'->>'roster')::int, 1, 'Awaiting first sign-in counts roster rows');
select is((public.admin_dashboard_requests()->'rows'->0->>'can_decide')::boolean, false, 'RC cannot approve their own student change');
select is(public.admin_dashboard_requests()->'rows'->0->'target'->>'full_name', 'Desk student', 'Request includes the recorded student identity');
select is(public.admin_dashboard_requests()->'rows'->0->'target_snapshot'->'member'->>'full_name', 'Desk student', 'Before values come from the request snapshot');
select is((public.admin_dashboard_summary()->'queue'->>'waiting')::int, 1, 'RC sees their request waiting on a Super Admin');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"ad190000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((public.admin_dashboard_requests()->'rows'->0->>'can_decide')::boolean, true, 'A different Super Admin can decide');
select lives_ok($$select public.approve_request((public.admin_dashboard_requests()->'rows'->0->>'id')::uuid)$$, 'Existing approval applies the change');
select lives_ok($$select public.request_member_update('ad190000-0000-4000-8000-000000000003', '{"full_name":"Desk final name"}', 'Second correction')$$, 'Super Admin files another change');
select is((public.admin_dashboard_requests()->'rows'->0->>'can_decide')::boolean, false, 'Super Admin cannot decide their own change');
select is(jsonb_array_length(public.admin_dashboard_requests()->'rows'->0->'history'), 1, 'History includes the earlier decision');
select is(public.admin_dashboard_requests('decided')->'rows'->0->>'status', 'approved', 'Decided queue includes approvals');
select throws_ok($$select public.admin_dashboard_requests('invalid')$$, '22023', 'Invalid request filter', 'Invalid filters fail');
select is((public.admin_dashboard_summary()->'counts'->>'roster')::int, 2, 'Super Admin sees both regions');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"ad190000-0000-4000-8000-000000000005","role":"authenticated"}';
select is(public.admin_dashboard_summary()->'counts', 'null'::jsonb, 'Head receives no student counts');
select is(jsonb_array_length(public.admin_dashboard_summary()->'regions'), 0, 'Head receives no region totals');
select is(jsonb_array_length(public.admin_dashboard_summary()->'requests'), 0, 'Head receives no request identities');
select is(jsonb_array_length(public.admin_dashboard_requests()->'rows'), 0, 'Head reads only their own requests');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"ad190000-0000-4000-8000-000000000004","role":"authenticated"}';
select throws_ok($$select public.admin_dashboard_summary()$$, '42501', 'Admin access is required', 'Ordinary members cannot read dashboard aggregates');
reset role;
update public.members set account_status = 'suspended' where id = 'ad190000-0000-4000-8000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"ad190000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.admin_dashboard_summary()$$, '42501', 'Admin access is required', 'Suspended RC loses aggregate access');
reset role;
set local role anon;
select throws_ok($$select public.admin_dashboard_summary()$$, '42501', null, 'Anonymous callers have no execute grant');
reset role;
select * from finish();
rollback;

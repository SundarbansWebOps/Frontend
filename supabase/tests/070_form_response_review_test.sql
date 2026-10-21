-- Form response review: permissions, reason rules, undo, resubmit-after-reject, caller-only status.
-- Synthetic identities only. Every fixture rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('fa700000-0000-4000-8000-000000000098', '99f7000098', '99f7000098@ds.study.iitm.ac.in', 1);
create temp table rv_people(id uuid, email text, full_name text, region_id smallint);
insert into rv_people values
 ('fa700000-0000-4000-8000-000000000001', '99f7000001@ds.study.iitm.ac.in', 'Review super', 1),
 ('fa700000-0000-4000-8000-000000000002', '99f7000002@ds.study.iitm.ac.in', 'Review coordinator', 1),
 ('fa700000-0000-4000-8000-000000000003', '99f7000003@ds.study.iitm.ac.in', 'Student one', 1),
 ('fa700000-0000-4000-8000-000000000004', '99f7000004@ds.study.iitm.ac.in', 'Student two', 1),
 ('fa700000-0000-4000-8000-000000000005', '99f7000005@ds.study.iitm.ac.in', 'Other region student', 2),
 ('fa700000-0000-4000-8000-000000000006', '99f7000006@ds.study.iitm.ac.in', 'Community head', 1),
 ('fa700000-0000-4000-8000-000000000007', '99f7000007@ds.study.iitm.ac.in', 'Other coordinator', 2);
insert into public.member_roster(email, full_name, region_id, added_by)
select email, full_name, region_id, 'fa700000-0000-4000-8000-000000000098' from rv_people;
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from rv_people;
insert into public.super_admin_allowlist(user_id, label) values ('fa700000-0000-4000-8000-000000000001', 'Review fixture');
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
values ('fa700000-0000-4000-8000-000000000002', 'rc', 1, null, 'fa700000-0000-4000-8000-000000000001'),
 ('fa700000-0000-4000-8000-000000000007', 'rc', 2, null, 'fa700000-0000-4000-8000-000000000001'),
 ('fa700000-0000-4000-8000-000000000006', 'head', null, 1, 'fa700000-0000-4000-8000-000000000001');

set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','fa710000-0000-4000-8000-000000000001','title','Region sign-up','region_id',1,'published_at',now() - interval '1 hour',
 'fields',jsonb_build_array(jsonb_build_object('key','name','label','Name','type','text','required',true))))$$, 'RC saves a region form');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','fa710000-0000-4000-8000-000000000002','title','Region group','region_id',1,'published_at',now() - interval '1 hour',
 'form_kind','group','group_label','Patna','invite_url','https://chat.whatsapp.com/ReviewInvite1',
 'fields',jsonb_build_array(jsonb_build_object('key','name','label','Name','type','text','required',true))))$$, 'RC saves a group form with an invite');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"S One"}')$$, 'student one submits');
select is((select review_status from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000001'), 'pending', 'a new response is pending');
select is(public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"S One"}')->>'invite_url', 'https://chat.whatsapp.com/ReviewInvite1', 'group form reveals the invite on submit');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"S Two"}')$$, 'student two submits');
reset role;
-- Make arrival order deterministic: student one first.
update public.form_responses set submitted_at = now() - interval '2 hours' where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000001';
update public.form_responses set submitted_at = now() - interval '1 hour' where member_id='fa700000-0000-4000-8000-000000000004' and form_id='fa710000-0000-4000-8000-000000000001';
create temp table rv_ids as select member_id, id from public.form_responses where form_id='fa710000-0000-4000-8000-000000000001';
grant select on rv_ids to authenticated;

-- Permissions
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved')$$, '42501', null, 'a student cannot approve even their own response');
select throws_ok($$select public.export_form_responses('fa710000-0000-4000-8000-000000000001')$$, '42501', null, 'a student cannot export responses');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000007","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved')$$, '42501', null, 'another region RC cannot review');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000006","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved')$$, '42501', null, 'a community head cannot review a region form');
reset role;

-- Reason rules, approve, undo
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected')$$, '22023', null, 'rejection needs a reason');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected','   ')$$, '22023', null, 'a blank reason is refused');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',repeat('x',501))$$, '22023', null, 'a 501 character reason is refused');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'maybe')$$, '22023', null, 'unknown status is refused');
select throws_ok($$select public.review_form_response(gen_random_uuid(),'approved')$$, '42501', null, 'an unknown response is refused');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved','ignored')->>'review_reason', null, 'approval stores no reason');
select is((select review_status||':'||(reviewed_by='fa700000-0000-4000-8000-000000000002')::text from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')), 'approved:true', 'approval records the reviewer');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'pending')->>'review_status', 'pending', 'undo returns to pending');
select is((select reviewed_by::text||reviewed_at::text from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')), null, 'undo clears reviewer and time');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected','  Wrong region  ')->>'review_reason', 'Wrong region', 'rejection trims and stores the reason');
reset role;
select ok(exists(select 1 from public.audit_log where action='form.review' and target_id=(select id::text from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'review is audited');
select throws_ok($$update public.form_responses set review_status='rejected', review_reason=null where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000001'$$, '23514', null, 'table check refuses a rejection without a reason');
select throws_ok($$update public.form_responses set review_reason='stale' where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000001'$$, '23514', null, 'table check refuses a reason on a non-rejection');

-- Export
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((public.export_form_responses('fa710000-0000-4000-8000-000000000001')->0->>'serial')::int, 1, 'export serial 1 is the first received');
select is(public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'review_status', 'rejected', 'export carries review status');
select is(public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'reviewer_email', '99f7000002@ds.study.iitm.ac.in', 'export carries reviewer email');
select is(public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'member_full_name', 'Student two', 'export carries the member name');
select is((public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'serial')::int, 2, 'serial 2 is the second received');
reset role;

-- list_lounge_forms exposes only the caller's own status
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select is((select f->>'review_status' from jsonb_array_elements(public.list_lounge_forms()) f where f->>'id'='fa710000-0000-4000-8000-000000000001'), 'pending', 'student one sees their own pending status');
select is((select f->>'review_reason' from jsonb_array_elements(public.list_lounge_forms()) f where f->>'id'='fa710000-0000-4000-8000-000000000001'), null, 'student one does not see the other rejection reason');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select is((select f->>'review_reason' from jsonb_array_elements(public.list_lounge_forms()) f where f->>'id'='fa710000-0000-4000-8000-000000000001'), 'Wrong region', 'student two sees their own rejection reason');
select is((select f->>'review_status' from jsonb_array_elements(public.list_lounge_forms()) f where f->>'id'='fa710000-0000-4000-8000-000000000001'), 'rejected', 'student two sees rejected');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000005","role":"authenticated"}';
select is((select f->>'review_status' from jsonb_array_elements(public.list_lounge_forms()) f where f->>'id'='fa710000-0000-4000-8000-000000000001'), null, 'an unsubmitted student has no status');
reset role;

-- Resubmit after rejection replaces in place; pending and approved stay untouched
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"S Two fixed"}')$$, 'a rejected student resubmits');
reset role;
select is((select count(*)::int from public.form_responses where form_id='fa710000-0000-4000-8000-000000000001'), 2, 'resubmit does not add a row');
select is((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000004' and form_id='fa710000-0000-4000-8000-000000000001'), (select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'), 'the same response row is reused');
select is((select answers->>'name'||':'||review_status||':'||coalesce(review_reason,'-')||':'||coalesce(reviewed_by::text,'-') from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'S Two fixed:pending:-:-', 'answers replaced and review reset');
select ok((select submitted_at > now() - interval '5 minutes' from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'submitted_at refreshed');
select ok(exists(select 1 from public.audit_log where action='form.resubmit' and target_id=(select id::text from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'resubmit is audited');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"Pending change"}')$$, 'resubmitting while pending is accepted as a no-op');
reset role;
select is((select answers->>'name' from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'S Two fixed', 'a pending response is unchanged by resubmit');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'approved')$$, 'Super Admin approves');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"Approved change"}')$$, 'resubmitting while approved is accepted as a no-op');
reset role;
select is((select answers->>'name'||':'||review_status from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'S Two fixed:approved', 'an approved response is unchanged by resubmit');

-- Group form: rejection and resubmit keep the invite behaviour
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'),'rejected','Not a Sundarbans House member')$$, 'RC rejects a group application');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select is(public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"S One corrected"}')->>'invite_url', 'https://chat.whatsapp.com/ReviewInvite1', 'group resubmit still returns the invite');
reset role;

-- Suspended reviewer
update public.members set account_status = 'suspended' where id = 'fa700000-0000-4000-8000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved')$$, '42501', null, 'a suspended RC cannot review');
reset role;
set local role anon;
select throws_ok($$select public.review_form_response(gen_random_uuid(),'approved')$$, '42501', null, 'anonymous callers have no execute grant');
reset role;
select * from finish();
rollback;

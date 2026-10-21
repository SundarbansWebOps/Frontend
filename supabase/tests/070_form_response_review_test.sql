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
-- The version a reviewer loaded: coalesce(resubmitted_at, submitted_at).
create function pg_temp.rv_exp(p uuid) returns timestamptz language sql security definer set search_path='' as $$
 select coalesce(resubmitted_at, submitted_at) from public.form_responses where id = p $$;
grant execute on function pg_temp.rv_exp(uuid) to authenticated, anon;

-- Permissions
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')))$$, '42501', null, 'a student cannot approve even their own response');
select throws_ok($$select public.export_form_responses('fa710000-0000-4000-8000-000000000001')$$, '42501', null, 'a student cannot export responses');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000007","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')))$$, '42501', null, 'another region RC cannot review');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000006","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')))$$, '42501', null, 'a community head cannot review a region form');
reset role;

-- Reason rules, approve, undo
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')))$$, '22023', null, 'rejection needs a reason');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')),'   ')$$, '22023', null, 'a blank reason is refused');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')),repeat('x',501))$$, '22023', null, 'a 501 character reason is refused');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'maybe',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')))$$, '22023', null, 'unknown status is refused');
select throws_ok($$select public.review_form_response(gen_random_uuid(),'approved',pg_temp.rv_exp(gen_random_uuid()))$$, '42501', null, 'an unknown response is refused');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')),'ignored')->>'review_reason', null, 'approval stores no reason');
select is((select review_status||':'||(reviewed_by='fa700000-0000-4000-8000-000000000002')::text from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')), 'approved:true', 'approval records the reviewer');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'pending',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')))->>'review_status', 'pending', 'undo returns to pending');
select is((select reviewed_by::text||reviewed_at::text from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')), null, 'undo clears reviewer and time');
select is(public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')),'  Wrong region  ')->>'review_reason', 'Wrong region', 'rejection trims and stores the reason');
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
select ok((select submitted_at < now() - interval '30 minutes' and resubmitted_at > now() - interval '5 minutes' from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'submitted_at keeps the first-received time and resubmitted_at records the resend');
select is((select resubmitted_at from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')), null, 'resubmitted_at is null until a resubmit');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select is((public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'serial')::int, 2, 'serial is unchanged after a resubmit');
select is(public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'member_full_name', 'Student two', 'the resubmitted response keeps its place in arrival order');
select ok(public.export_form_responses('fa710000-0000-4000-8000-000000000001')->1->>'resubmitted_at' is not null, 'export carries resubmitted_at');
reset role;
select ok(exists(select 1 from public.audit_log where action='form.resubmit' and target_id=(select id::text from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'resubmit is audited');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"Pending change"}')$$, 'resubmitting while pending is accepted as a no-op');
reset role;
select is((select answers->>'name' from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'S Two fixed', 'a pending response is unchanged by resubmit');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')))$$, 'Super Admin approves');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000001','{"name":"Approved change"}')$$, 'resubmitting while approved is accepted as a no-op');
reset role;
select is((select answers->>'name'||':'||review_status from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'S Two fixed:approved', 'an approved response is unchanged by resubmit');

-- Group form: rejection and resubmit keep the invite behaviour
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'),'rejected',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002')),'Not a Sundarbans House member')$$, 'RC rejects a group application');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.get_lounge_form_invite('fa710000-0000-4000-8000-000000000002')$$, '42501', null, 'a rejected response does not unlock the invite');
select is(public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"S One corrected"}')->>'invite_url', 'https://chat.whatsapp.com/ReviewInvite1', 'group resubmit still returns the invite');
select is(public.get_lounge_form_invite('fa710000-0000-4000-8000-000000000002'), 'https://chat.whatsapp.com/ReviewInvite1', 'the invite is available again once the response is pending');
reset role;

-- Stale review: a decision on a version the reviewer never saw is refused and changes nothing.
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',now() - interval '99 days','Stale')$$, 'PT409', 'This response changed since you loaded it. Refresh and review again.', 'a stale expected_at is refused');
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004'),'rejected',null,'No version')$$, 'PT409', null, 'a missing expected_at is refused');
reset role;
select is((select review_status||':'||coalesce(review_reason,'-') from public.form_responses where id=(select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000004')), 'approved:-', 'a refused stale review leaves the row unchanged');
-- The real race: the reviewer loaded the rejected group response, the member then resubmits.
-- (now() is fixed inside this transaction, so give the loaded version an earlier resend time.)
update public.form_responses set resubmitted_at = now() - interval '3 hours' where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'),'rejected',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002')),'Typo in name')$$, 'RC rejects the group response the reviewer then holds open');
reset role;
create temp table rv_loaded as select pg_temp.rv_exp(id) as at from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002';
grant select on rv_loaded to authenticated;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"S One again"}')$$, 'member resubmits after the reviewer loaded the list');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'),'approved',(select at from rv_loaded))$$, 'PT409', null, 'approving the version loaded before a resubmit is refused');
reset role;
select is((select review_status from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'), 'pending', 'the resubmitted response stays pending');

-- Self-review: a manager cannot decide their own response; a Super Admin can.
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"RC own"}')$$, 'the RC submits their own response');
select throws_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000002' and form_id='fa710000-0000-4000-8000-000000000002'),'approved',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000002' and form_id='fa710000-0000-4000-8000-000000000002')))$$, '42501', 'You cannot review your own response', 'a manager cannot review their own response');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000002','{"name":"SA own"}')$$, 'the Super Admin submits their own response');
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000001' and form_id='fa710000-0000-4000-8000-000000000002'),'approved',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000001' and form_id='fa710000-0000-4000-8000-000000000002')))$$, 'a Super Admin may review their own response');
reset role;

-- Resubmit on an event-linked form keeps the registration email in step with the submission.
insert into public.events(id,name,region_id,starts_at,ends_at,published_at,created_by,updated_by)
values ('fa720000-0000-4000-8000-000000000001','Review event',1,now()+interval '1 day',now()+interval '2 day',now(),'fa700000-0000-4000-8000-000000000001','fa700000-0000-4000-8000-000000000001');
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','fa710000-0000-4000-8000-000000000003','title','Event sign-up','event_id','fa720000-0000-4000-8000-000000000001','published_at',now() - interval '1 hour',
 'fields',jsonb_build_array(jsonb_build_object('key','name','label','Name','type','text','required',true))))$$, 'RC saves an event-linked form');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000003','{"name":"Event one"}')$$, 'student registers through the event form');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000003'),'rejected',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000003')),'Name mismatch')$$, 'RC rejects the event response');
reset role;
update public.event_registrations set registered_email='stale-address@ds.study.iitm.ac.in' where member_id='fa700000-0000-4000-8000-000000000003' and event_id='fa720000-0000-4000-8000-000000000001';
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('fa710000-0000-4000-8000-000000000003','{"name":"Event one fixed"}')$$, 'student resubmits the event response');
reset role;
select is((select registered_email from public.event_registrations where member_id='fa700000-0000-4000-8000-000000000003' and event_id='fa720000-0000-4000-8000-000000000001'), (select email from public.members where id='fa700000-0000-4000-8000-000000000003'), 'the resubmit refreshes the registration email');
select is((select count(*)::int from public.event_registrations where member_id='fa700000-0000-4000-8000-000000000003' and event_id='fa720000-0000-4000-8000-000000000001'), 1, 'still one registration');

-- Invite copy: a rejected response gets its own message; never submitted keeps the original.
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.review_form_response((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002'),'rejected',pg_temp.rv_exp((select id from public.form_responses where member_id='fa700000-0000-4000-8000-000000000003' and form_id='fa710000-0000-4000-8000-000000000002')),'Wrong region')$$, 'RC rejects the group response again');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.get_lounge_form_invite('fa710000-0000-4000-8000-000000000002')$$, '42501', 'Your response was not approved. Fix it and send it again to get the invite.', 'a rejected response gets the not-approved message');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000004","role":"authenticated"}';
select throws_ok($$select public.get_lounge_form_invite('fa710000-0000-4000-8000-000000000002')$$, '42501', 'Submit this application before viewing the invite', 'a member who never submitted keeps the original message');
reset role;

-- Hard delete redacts review reasons; a rejected row keeps a placeholder so the check constraint holds.
insert into public.form_responses(id,form_id,member_id,submitted_email,field_schema,answers,review_status,review_reason,reviewed_by,reviewed_at) values
 ('fa730000-0000-4000-8000-000000000001','fa710000-0000-4000-8000-000000000001','fa700000-0000-4000-8000-000000000005','99f7000005@ds.study.iitm.ac.in','[]','{"name":"Other"}','rejected','Name does not match Other region student','fa700000-0000-4000-8000-000000000002',now()),
 ('fa730000-0000-4000-8000-000000000002','fa710000-0000-4000-8000-000000000002','fa700000-0000-4000-8000-000000000005','99f7000005@ds.study.iitm.ac.in','[]','{"name":"Other"}','approved',null,'fa700000-0000-4000-8000-000000000002',now());
set local session_replication_role=replica;
update public.members set account_status='deleted',deleted_at=now()-interval '31 days' where id='fa700000-0000-4000-8000-000000000005';
set local session_replication_role=origin;
insert into public.approval_requests(id,type,target_member_id,target_snapshot,reason,requested_by) values('fa740000-0000-4000-8000-000000000001','member_hard_delete','fa700000-0000-4000-8000-000000000005','{}','Erase','fa700000-0000-4000-8000-000000000002');
select lives_ok($$select public.svc_execute_hard_delete('fa700000-0000-4000-8000-000000000001','fa740000-0000-4000-8000-000000000001')$$, 'hard delete runs with review fields present');
select is((select review_reason from public.form_responses where id='fa730000-0000-4000-8000-000000000001'), 'Redacted', 'a rejected reason is replaced by a placeholder');
select is((select review_reason from public.form_responses where id='fa730000-0000-4000-8000-000000000002'), null, 'a non-rejected row has no reason');
select ok((select answers='{}' and submitted_email like 'deleted-%' from public.form_responses where id='fa730000-0000-4000-8000-000000000001'), 'hard delete still erases answers and email');

-- Suspended reviewer
update public.members set account_status = 'suspended' where id = 'fa700000-0000-4000-8000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"fa700000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.review_form_response((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003'),'approved',pg_temp.rv_exp((select id from rv_ids where member_id='fa700000-0000-4000-8000-000000000003')))$$, '42501', null, 'a suspended RC cannot review');
reset role;
set local role anon;
select throws_ok($$select public.review_form_response(gen_random_uuid(),'approved',pg_temp.rv_exp(gen_random_uuid()))$$, '42501', null, 'anonymous callers have no execute grant');
reset role;
select * from finish();
rollback;

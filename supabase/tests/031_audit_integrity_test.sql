-- Focused regressions for the 2026-10-09 backend/admin data-integrity audit.
begin;
select no_plan();

select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper')
where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');
insert into public.members(id,member_code,email)
values ('d1000000-0000-4000-8000-000000000099','26f1000099','26f1000099@ds.study.iitm.ac.in');
insert into public.member_roster(email,added_by) values
 ('26f1000001@ds.study.iitm.ac.in','d1000000-0000-4000-8000-000000000099'),
 ('26f1000002@ds.study.iitm.ac.in','d1000000-0000-4000-8000-000000000099');
insert into auth.users(id,email,aud,role,raw_app_meta_data) values
 ('d1000000-0000-4000-8000-000000000001','26f1000001@ds.study.iitm.ac.in','authenticated','authenticated','{"provider":"google"}'),
 ('d1000000-0000-4000-8000-000000000002','26f1000002@ds.study.iitm.ac.in','authenticated','authenticated','{"provider":"google"}');
insert into public.super_admin_allowlist(user_id,label)
values ('d1000000-0000-4000-8000-000000000001','Audit integrity test SA');
insert into public.events(id,name,starts_at,ends_at,published_at,created_by,updated_by)
values ('d2000000-0000-4000-8000-000000000001','Attendance source test',now(),now()+interval '1 day',now(),
 'd1000000-0000-4000-8000-000000000001','d1000000-0000-4000-8000-000000000001');
insert into public.member_roster(email,added_by)
values ('20f3000987@ds.study.iitm.ac.in','d1000000-0000-4000-8000-000000000001');

set local role authenticated;
set local request.jwt.claims='{"sub":"d1000000-0000-4000-8000-000000000001","role":"authenticated"}';

select lives_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"26f1000010@ds.study.iitm.ac.in","duration_seconds":1300},
   {"email":"masked","duration_seconds":1200,"source_row_id":"2"},
   {"email":"masked","duration_seconds":900,"source_row_id":"3"}]','merge','default')$$,
 'first attendance source imports valid and unresolved rows');
select is((select count(*)::integer from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and category='unresolved'),2,
 'identical unresolved source rows keep distinct identities');

select lives_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"26f1000010@ds.study.iitm.ac.in","duration_seconds":1300}]','merge','sheet-b')$$,
 'a second source can share a canonical email identity');
select ok((select import_sources @> array['default','sheet-b'] from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and email='26f1000010@ds.study.iitm.ac.in'),
 'shared canonical attendance retains both source identities');
select throws_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"26f1000010@ds.study.iitm.ac.in","duration_seconds":1800}]','merge','default')$$,'PT409',null,
 'a source cannot change a shared identity while another source still claims the old value');
select throws_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"26f1000010@ds.study.iitm.ac.in","duration_seconds":1800}]','merge','sheet-c')$$,'PT409',null,
 'overlapping sheets with different verdict-bearing values are rejected for reconciliation');

select lives_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"masked","duration_seconds":1200,"source_row_id":"2"}]')$$,
 'two-argument attendance call defaults to merge');
select is((select count(*)::integer from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and category='unresolved'),2,
 'default merge retains omitted unresolved rows');

select lives_ok($$select public.import_event_attendance('d2000000-0000-4000-8000-000000000001',
 '[{"email":"masked","duration_seconds":1200,"source_row_id":"2"}]','replace','default')$$,
 'explicit replacement reconciles one named source');
select is((select count(*)::integer from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and category='unresolved'),1,
 'named replacement removes only omitted unresolved rows from that source');
select ok(exists(select 1 from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and email='26f1000010@ds.study.iitm.ac.in' and import_sources @> array['sheet-b']),
 'replacement preserves an identity still owned by another source');
select is((select duration_seconds from public.event_attendance where event_id='d2000000-0000-4000-8000-000000000001' and email='26f1000010@ds.study.iitm.ac.in'),1300,
 'replacing one source cannot leave its stale attendance value behind');

select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','d3000000-0000-4000-8000-000000000001','title','Patna group','source_url','https://forms.google.com/forms/d/e/a/viewform/','form_kind','group','group_label','Patna'))$$,
 'group metadata and source URL save');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','d3000000-0000-4000-8000-000000000004','title','Archived group','form_kind','group','group_label','Patna','published_at',now(),'archived_at',now(),'invite_url','https://chat.whatsapp.com/SecretInviteCode'))$$,
 'archived form and private invite save');
select is(public.get_lounge_form_invite('d3000000-0000-4000-8000-000000000004'),'https://chat.whatsapp.com/SecretInviteCode',
 'form organizer can retrieve its private invite after archive');
select ok((select new_values->>'invite_changed'='true' and not(new_values ? 'invite_url') and new_values::text not like '%SecretInviteCode%' from public.audit_log where action='form.save' and target_id='d3000000-0000-4000-8000-000000000004' order by id desc limit 1),
 'form invite audit records a boolean change indicator without retaining the invite URL');
select ok(not private.can_submit_form('d3000000-0000-4000-8000-000000000004'),
 'archived forms cannot accept submissions');
select ok((public.list_lounge_forms()::text like '%d3000000-0000-4000-8000-000000000004%'),
 'organizers retain archived form history');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','d3000000-0000-4000-8000-000000000001','title','Renamed group','form_kind','group','group_label','Patna'))$$,
 'editing without a source URL preserves the prior source');
select is((select source_url from public.lounge_forms where id='d3000000-0000-4000-8000-000000000001'),'https://forms.google.com/forms/d/e/a/viewform/',
 'omitted source URL is not cleared');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('id','d3000000-0000-4000-8000-000000000002','title','Duplicate source','source_url','https://forms.google.com/forms/d/e/a/viewform'))$$,'23505',null,
 'canonical source URL uniqueness rejects a trailing-slash duplicate');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('title','Duplicate cohort audience','audience_cohorts',jsonb_build_array(public.get_available_cohorts()->>'current',public.get_available_cohorts()->>'current')))$$,'22023',null,
 'duplicate cohort selections are rejected instead of silently diverging');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','d3000000-0000-4000-8000-000000000003','title','Other trim check','fields',jsonb_build_array(jsonb_build_object('key','choice','label','Choice','type','select','required',true,'allow_other',true,'options',jsonb_build_array('Listed'))),'published_at',now()))$$,
 'Other validation fixture saves');
select throws_ok($$select public.submit_lounge_form('d3000000-0000-4000-8000-000000000003',jsonb_build_object('choice','Other:'||repeat('x',301)))$$,'22023',null,
 'custom Other answer over 300 trimmed characters is rejected');
select lives_ok($$select public.submit_lounge_form('d3000000-0000-4000-8000-000000000003',jsonb_build_object('choice','Other:  '||repeat('x',300)||'  '))$$,
 'Other answer at the trimmed 300-character limit is accepted');

select throws_ok($$insert into public.events(name,starts_at,ends_at,archive)
 values('Future archive',now()+interval '1 day',now()+interval '2 days',true)$$,'22023',null,
 'future scheduled events cannot be marked as public archive records');
select is((public.get_available_cohorts()->'options')::jsonb,
 (select to_jsonb(array_agg(distinct x order by x)) from jsonb_array_elements_text(public.get_available_cohorts()->'options') x),
 'cohort options contain unique values');
select ok((public.get_available_cohorts()->'options') @> '["20F1","20F2","20F3"]'::jsonb,
 'older roster-only cohort years appear even when signed-in members have newer cohorts');

reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"d1000000-0000-4000-8000-000000000002","role":"authenticated"}';
select ok(not (public.list_lounge_forms()::text like '%d3000000-0000-4000-8000-000000000004%'),
 'unsubmitted members cannot discover archived forms');
select throws_ok($$select public.submit_lounge_form('d3000000-0000-4000-8000-000000000004','{}')$$,'42501',null,
 'unsubmitted members cannot submit to archived forms');

reset role;
insert into public.member_roster(email,added_by)
values ('26f1000003@ds.study.iitm.ac.in','d1000000-0000-4000-8000-000000000001');
insert into auth.users(id,email,aud,role,raw_app_meta_data)
values ('d1000000-0000-4000-8000-000000000003','26f1000003@ds.study.iitm.ac.in','authenticated','authenticated','{"provider":"google"}');
insert into public.super_admin_allowlist(user_id,label)
values ('d1000000-0000-4000-8000-000000000003','Second test SA');
update public.members set account_status='deleted',deleted_at=now()-interval '31 days'
where id='d1000000-0000-4000-8000-000000000002';
insert into public.approval_requests(id,type,target_member_id,target_snapshot,requested_change,reason,requested_by,review_note)
values ('d4000000-0000-4000-8000-000000000001','member_hard_delete',
 'd1000000-0000-4000-8000-000000000002','{"email":"private-test@example.invalid"}',
 '{"full_name":"Private test name"}','private-test@example.invalid',
 'd1000000-0000-4000-8000-000000000001','private-test@example.invalid');
set local role service_role;
select lives_ok($$select public.svc_execute_hard_delete('d1000000-0000-4000-8000-000000000003','d4000000-0000-4000-8000-000000000001')$$,
 'second administrator executes an eligible hard-delete request');
reset role;
select ok((select reason='Redacted' and requested_change='{}'::jsonb and review_note is null
 and target_snapshot->>'redacted'='true' from public.approval_requests
 where id='d4000000-0000-4000-8000-000000000001'),
 'hard deletion clears operational request free text and identity snapshots');
select * from finish();
rollback;

-- Real PostgreSQL RLS/definer/grants gates, isolated fixtures and full rollback.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');
create temp table fx(k text primary key,id uuid,email text);
insert into fx values
 ('sa','b9000000-0000-4000-8000-000000000001','26f3000001@ds.study.iitm.ac.in'),
 ('rc','b9000000-0000-4000-8000-000000000002','26f3000002@ds.study.iitm.ac.in'),
 ('rc2','b9000000-0000-4000-8000-000000000003','26f3000003@ds.study.iitm.ac.in'),
 ('rc3','b9000000-0000-4000-8000-000000000004','26f3000004@ds.study.iitm.ac.in'),
 ('member','b9000000-0000-4000-8000-000000000005','26f3000005@ds.study.iitm.ac.in'),
 ('other','b9000000-0000-4000-8000-000000000006','26f3000006@ds.study.iitm.ac.in'),
 ('head','b9000000-0000-4000-8000-000000000007','26f3000007@ds.study.iitm.ac.in'),
 ('unknown','b9000000-0000-4000-8000-000000000008','26f3000008@ds.study.iitm.ac.in'),
 ('es','b9000000-0000-4000-8000-000000000009','26f3000009@es.study.iitm.ac.in'),
 ('mg','b9000000-0000-4000-8000-000000000010','26f3000010@mg.study.iitm.ac.in'),
 ('ae','b9000000-0000-4000-8000-000000000011','26f3000011@ae.study.iitm.ac.in');
grant select on fx to authenticated;
insert into public.members(id,member_code,email,region_id) values('b9000000-0000-4000-8000-000000000099','26f3000099','26f3000099@ds.study.iitm.ac.in',(select id from public.regions where code='region_01'));
insert into public.member_roster(email,region_id,added_by) select email,(select id from public.regions where code='region_01'),'b9000000-0000-4000-8000-000000000099' from fx where k='sa';
insert into auth.users(id,email,aud,role,raw_app_meta_data) select id,email,'authenticated','authenticated','{"provider":"google"}'::jsonb from fx where k='sa';
insert into public.super_admin_allowlist(user_id,label) select id,'Test SA' from fx where k='sa';
insert into public.member_roster(email,region_id,added_by) select email,case when k='unknown' then null else (select id from public.regions where code=case when k='other' then 'region_02' else 'region_01' end) end,(select id from fx where k='sa') from fx where k<>'sa';
insert into auth.users(id,email,aud,role,raw_app_meta_data) select id,email,'authenticated','authenticated','{"provider":"google"}'::jsonb from fx where k<>'sa';
select is((select count(*)::integer from public.members where id in(select id from fx)),11,'four exact roster domains provision without names or phones');
select ok((select full_name is null and region_id is null from public.members where id=(select id from fx where k='unknown')),'unknown allocation stays null');
select throws_ok($$insert into auth.users(id,email) values('b9000000-0000-4000-8000-000000000099','stranger@ae.study.iitm.ac.in')$$,'42501','This email is not on the house roster','allowed domain alone never authorizes signup');
insert into public.member_roster(email,added_by) values('password-only@ds.study.iitm.ac.in',(select id from fx where k='sa'));
select throws_ok($$insert into auth.users(id,email,raw_app_meta_data) values('b9000000-0000-4000-8000-000000000098','password-only@ds.study.iitm.ac.in','{"provider":"email"}')$$,'42501','Use Google sign-in to claim your roster account','roster claim requires Google rather than password signup');
select is_empty($$select 1 from auth.users where id='b9000000-0000-4000-8000-000000000098'$$,'refused provider creates no Auth account');

insert into public.admin_assignments(member_id,position,region_id,assigned_by) select id,'rc',(select id from public.regions where code='region_01'),(select id from fx where k='sa') from fx where k in('rc','rc2');
select throws_ok($$insert into public.admin_assignments(member_id,position,region_id,assigned_by) select id,'rc',(select id from public.regions where code='region_01'),(select id from fx where k='sa') from fx where k='rc3'$$,'23505',null,'third RC rejected');
select throws_ok($$insert into public.admin_assignments(member_id,position,region_id,assigned_by) select id,'rc',(select id from public.regions where code='international'),(select id from fx where k='rc') from fx where k='other'$$,'22023','International has no Regional Coordinator','International rejects RC');
insert into public.admin_assignments(member_id,position,community_id,assigned_by) select id,'head',(select id from public.communities where code='technical'),(select id from fx where k='sa') from fx where k='head';
create temp table event_fx(k text primary key,id uuid);
insert into event_fx values ('regional','e9000000-0000-4000-8000-000000000001'),('other','e9000000-0000-4000-8000-000000000002'),('community','e9000000-0000-4000-8000-000000000003'),('past','e9000000-0000-4000-8000-000000000004'),('draftpast','e9000000-0000-4000-8000-000000000005'),('futurecohort','e9000000-0000-4000-8000-000000000006');
grant select on event_fx to authenticated,anon;
insert into public.events(id,name,region_id,community_id,starts_at,ends_at,published_at,created_by,updated_by,audience_cohorts)
select id,k,case when k='community' then null else(select id from public.regions where code=case when k='other' then 'region_02' else 'region_01' end) end,
case when k='community' then(select id from public.communities where code='technical') else null end,
case when k in('past','draftpast') then now()-interval '2 day' else now()+interval '1 day' end,
case when k in('past','draftpast') then now()-interval '1 day' else now()+interval '2 day' end,
case when k='draftpast' then null else now() end,(select id from fx where k='sa'),(select id from fx where k='sa'),case when k='futurecohort' then array[private.next_cohort()] else '{}' end from event_fx;
insert into public.events(id,name,region_id,starts_at,ends_at,created_by,updated_by) values('e9000000-0000-4000-8000-000000000020','Deletable draft',(select id from public.regions where code='region_01'),now()+interval '1 day',now()+interval '2 day',(select id from fx where k='sa'),(select id from fx where k='sa'));
insert into storage.objects(bucket_id,name) select 'certificate-templates',e||'/signed.png' from unnest(array['e9000000-0000-4000-8000-000000000001','e9000000-0000-4000-8000-000000000010','e9000000-0000-4000-8000-000000000011']) e;
-- Older admin request paths must not treat a NULL region or name as "unchanged" or "in scope".
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.request_member_update((select id from fx where k='unknown'),jsonb_build_object('full_name','Named Student','region_id',(select id from public.regions where code='region_01')),'Roster correction')$$,'SA files profile update for a member with no name or region');
select ok(exists(select 1 from public.search_members('26f3000009') where email='26f3000009@es.study.iitm.ac.in'),'nameless identity is returned by search');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$select public.request_member_deletion((select id from fx where k='unknown'),'Not in my region')$$,'42501',null,'RC cannot file deletion against a member with no region');
select throws_ok($$select public.request_blacklist((select id from fx where k='unknown'),'Not in my region')$$,'42501',null,'RC cannot file blacklist against a member with no region');
select is((public.roster_add_many('[{"email":"26f3000006@ds.study.iitm.ac.in"}]')->0->>'category'),'processed','RC roster add does not reveal global identity existence');
select throws_ok($$insert into public.events(name,region_id,starts_at,ends_at,archive) values('Archive by RC',(select id from public.regions where code='region_01'),now(),now()+interval '1 day',true)$$,'42501','Only a Super Admin manages archived events','RC cannot create archive events');
select lives_ok($$select public.soft_delete_event('e9000000-0000-4000-8000-000000000020')$$,'RC soft-deletes own draft through scoped RPC');
select is((select count(*)::integer from public.events where id='e9000000-0000-4000-8000-000000000020'),0,'RC cannot inspect a deleted event');
update public.events set deleted_at=null where id='e9000000-0000-4000-8000-000000000020';
select throws_ok($$select public.soft_delete_event('e9000000-0000-4000-8000-000000000020',false)$$,'42501',null,'RC cannot restore a soft-deleted event');
reset role;
select ok((select deleted_at is not null from public.events where id='e9000000-0000-4000-8000-000000000020'),'RC direct restore did not change the deleted event');
set local role authenticated;
select ok(not(public.list_lounge_events()::text like '%e9000000-0000-4000-8000-000000000020%'),'soft-deleted event leaves the organizer Lounge list');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.soft_delete_event('e9000000-0000-4000-8000-000000000020',false)$$,'Super Admin restores soft-deleted event');
select ok((select deleted_at is null from public.events where id='e9000000-0000-4000-8000-000000000020'),'restore persists');
reset role;
select ok((select requested_change ?& array['full_name','region_id'] from public.approval_requests where target_member_id=(select id from fx where k='unknown') and type='member_profile_update'),'profile update detects name and region for a member who had neither');
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000005","role":"authenticated"}';
select is((select count(*)::integer from public.events),3,'member sees own-region+community+published past; other region/future cohort/draft hidden');
select throws_ok($$update public.members set region_id=(select id from public.regions where code='region_02') where id=auth.uid()$$,'42501',null,'direct region update denied by column grant');
select lives_ok($$select public.update_my_profile('Member Name','+919990000111')$$,'member profile name/phone persist');
select lives_ok($$select public.set_my_tour_seen(true)$$,'tour stored');
select ok((select tour_seen_at is not null from public.members where id=auth.uid()),'tour flag reads back');
select throws_ok($$select public.select_my_initial_region((select id from public.regions where code='region_02'))$$,'PT409',null,'initial selection cannot overwrite existing region');
select lives_ok($$select public.request_my_region_change((select id from public.regions where code='region_02'),'Correct allocation')$$,'member files region correction');
select is((select r.code from public.members m join public.regions r on r.id=m.region_id where m.id=auth.uid()),'region_01','pending correction preserves region');
select ok(private.manages_scope((select id from public.regions where code='region_01'),null) is false,'ordinary member scope helper returns false, never null');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('title','Unauthorized regional form','region_id',(select id from public.regions where code='region_01')))$$,'42501',null,'ordinary member cannot create regional form');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('title','Unauthorized community form','community_id',(select id from public.communities where code='technical')))$$,'42501',null,'ordinary member cannot create community form');
select throws_ok($$select public.save_announcement(jsonb_build_object('title','Unauthorized regional notice','body','Bad','region_id',(select id from public.regions where code='region_01')))$$,'42501',null,'ordinary member cannot create regional notice');
select throws_ok($$select public.export_event_records((select id from event_fx where k='regional'))$$,'42501',null,'ordinary member cannot export event records');
select ok(not private.manages_template_path('e9000000-0000-4000-8000-000000000001/test.png'),'ordinary member cannot upload regional signed template');

select throws_ok($$select public.import_event_attendance((select id from event_fx where k='regional'),'[{"email":"x@ds.study.iitm.ac.in","duration_seconds":1200}]')$$,'42501',null,'member cannot import attendance');
reset role;
create temp table region_request_fx as select id from public.member_region_requests;
grant select on region_request_fx to authenticated;
set local role anon;
select is((select count(*)::integer from public.public_events),1,'public view exposes published completed event only');
select is(jsonb_array_length(to_jsonb(array(select public.list_public_past_events()))),1,'safe public RPC exposes same past set');
select throws_ok($$select public.list_lounge_forms()$$,'42501',null,'anon cannot list forms');
select throws_ok($$select * from public.form_responses$$,'42501',null,'anon cannot read responses');
select throws_ok($$select * from public.issued_certificates$$,'42501',null,'anon cannot read recipient records');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000006","role":"authenticated"}';
select is_empty($$select * from public.member_region_requests$$,'other-region member cannot read region requests');
select throws_ok($$select public.review_region_change('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',true)$$,'42501',null,'unscoped region review refused');
select throws_ok($$select public.review_region_change((select id from region_request_fx),true)$$,'42501',null,'ordinary other-region member cannot review even a concealed valid request');
reset role;
-- assign_position runs inside approve_request; call it as owner under Super Admin claims.
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.assign_position((select id from fx where k='other'),'rc')$$,'RPC assigns the first RC of a region');
reset role;
update public.admin_assignments set ended_at=now() where member_id=(select id from fx where k='rc2') and ended_at is null;
select lives_ok($$select public.assign_position((select id from fx where k='rc2'),'rc')$$,'RPC assigns a second RC beside the first');
select throws_ok($$select public.assign_position((select id from fx where k='rc3'),'rc')$$,null,null,'RPC refuses a third RC');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000006","role":"authenticated"}';
select throws_ok($$select public.review_region_change((select id from region_request_fx),true)$$,'42501',null,'a different-region RC cannot review the request');

reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$insert into public.events(name,region_id,starts_at,ends_at) values('Other region',(select id from public.regions where code='region_02'),now(),now()+interval '1 day')$$,'42501',null,'RC cannot create outside own region');
select throws_ok($$update public.events set region_id=(select id from public.regions where code='region_02') where id=(select id from event_fx where k='regional')$$,'42501',null,'RC cannot move own event outside scope');
select throws_ok($$update public.events set audience_cohorts=array['99F3'] where id=(select id from event_fx where k='regional')$$,'22023',null,'server rejects distant future cohort');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000001','title','Event registration','event_id',(select id from event_fx where k='regional'),'published_at',now(),'invite_url','https://chat.whatsapp.com/FixtureCode','fields','[{"key":"name","label":"Name","type":"text","required":true,"prefill":"name"},{"key":"phone","label":"Phone","type":"phone","prefill":"phone"},{"key":"interests","label":"Interests","type":"multiselect","options":["Code","Art"],"allow_other":true}]'::jsonb))$$,'RC creates scoped published form with original multiselect contract');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('title','Wrong scope','community_id',(select id from public.communities where code='technical')))$$,'42501',null,'RC cannot manage community form');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000020','title','Pick one','region_id',(select id from public.regions where code='region_01'),'published_at',now(),'fields','[{"key":"pick","label":"Pick","type":"select","options":["Chess","Go"],"allow_other":true}]'::jsonb))$$,'RC creates single-choice form allowing Other');
select lives_ok($$select public.save_announcement(jsonb_build_object('id','d9000000-0000-4000-8000-000000000001','title','Region notice','body','Useful update','region_id',(select id from public.regions where code='region_01')))$$,'RC publishes own regional notice');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000007","role":"authenticated"}';
select lives_ok($$update public.events set description='Technical organizers' where id=(select id from event_fx where k='community')$$,'Head edits own community event');
select is_empty($$select * from public.events where id=(select id from event_fx where k='draftpast')$$,'community operator cannot read regional draft');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000003','title','Community phone consent','community_id',(select id from public.communities where code='technical'),'published_at',now(),'fields','[{"key":"phone","label":"Phone","type":"phone"}]'::jsonb))$$,'Head manages own community application');
select lives_ok($$select public.save_announcement(jsonb_build_object('title','Community notice','body','Technical announcement','community_id',(select id from public.communities where code='technical')))$$,'Head manages own community notice');
select throws_ok($$select public.import_event_attendance((select id from event_fx where k='regional'),'[{"email":"26f3000005@ds.study.iitm.ac.in","duration_seconds":1200}]')$$,'42501',null,'Head cannot import regional attendance');
select ok(private.manages_template_path('e9000000-0000-4000-8000-000000000003/test.png'),'Head may upload blank template for own community event');
select ok(not private.manages_template_path('e9000000-0000-4000-8000-000000000001/test.png'),'Head cannot upload another organizer template');
select ok(not private.manages_template_path('invalid/test.png'),'storage path rejects invalid event ID');

reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000005","role":"authenticated"}';
select throws_ok($$select public.get_lounge_form_invite('f9000000-0000-4000-8000-000000000001')$$,'42501',null,'invite hidden before own response');
select ok(not(public.list_lounge_forms()::text like '%FixtureCode%'),'form listing never leaks invitation');
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"Student","interests":["Invented"]}')$$,'22023',null,'multiselect validates permitted options');
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"Student","interests":["Code","Code"]}')$$,'22023',null,'multiselect rejects repeated options');
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000020','{"pick":"Invented"}')$$,'22023',null,'single choice rejects unlisted text');
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000020','{"pick":"Other:"}')$$,'22023',null,'single choice rejects empty Other');
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000020','{"pick":"Other: Carrom"}')$$,'single choice accepts permitted Other answer');
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"   "}')$$,'22023',null,'required text rejects whitespace');
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"Student","phone":"+919990000222","interests":["Code","Other: Astronomy"]}',false)$$,'member submits form and event registration');
select is((select phone from public.members where id=auth.uid()),'+919990000111','unchecked save phone preserves profile');
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000003','{"phone":"+919990000444"}',true)$$,'explicit phone consent saves profile from application');
select is((select phone from public.members where id=auth.uid()),'+919990000444','phone consent persists normalized number');

select is(public.get_lounge_form_invite('f9000000-0000-4000-8000-000000000001'),'https://chat.whatsapp.com/FixtureCode','invite revealed after own response');
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"Changed"}',false)$$,'repeat submit returns original record');
select is((select count(*)::integer from public.form_responses where member_id=auth.uid()),3,'responses idempotent');
select is((select count(*)::integer from public.event_registrations where member_id=auth.uid()),1,'registration idempotent');
select lives_ok($$select public.set_my_notice_state('d9000000-0000-4000-8000-000000000001',true,true)$$,'notice read/dismiss persisted');
select ok(exists(select 1 from jsonb_array_elements(public.list_my_notices()) x where x->>'id'='d9000000-0000-4000-8000-000000000001' and x->>'dismissed_at' is not null),'notice dismissal read back');
select throws_ok($$select public.export_form_responses('f9000000-0000-4000-8000-000000000001')$$,'42501',null,'member cannot export peers responses');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000001','title','Unauthorized edit','event_id',(select id from event_fx where k='regional')))$$,'42501',null,'ordinary member cannot edit known regional form');
select throws_ok($$select public.save_announcement(jsonb_build_object('id','d9000000-0000-4000-8000-000000000001','title','Unauthorized edit','body','Bad','region_id',(select id from public.regions where code='region_01')))$$,'42501',null,'ordinary member cannot edit known regional notice');

reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000006","role":"authenticated"}';
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000001','{"name":"Other region"}')$$,'42501',null,'event registration respects region');
select is_empty($$select * from public.form_responses$$,'other member cannot read peer response');
select is(jsonb_array_length(public.list_my_notices()),1,'other region gets community notice and excludes regional notice');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.import_event_attendance((select id from event_fx where k='regional'),'[{"email":" 26F3000005@DS.STUDY.IITM.AC.IN ","duration_seconds":700},{"email":"26f3000005@ds.study.iitm.ac.in","duration_seconds":600},{"email":"26f3000006@ds.study.iitm.ac.in","duration_seconds":2400},{"email":"ma***@ds.study.iitm.ac.in","duration_seconds":2400}]')$$,'organizer imports normalized multiple sessions/unregistered/masked');
select is((select duration_seconds from public.event_attendance where member_id=(select id from fx where k='member')),1300,'multiple Meet sessions add within sheet');
select is((select count(*)::integer from public.event_attendance),3,'masked and unregistered rows retained separately');
select lives_ok($$select public.import_event_attendance((select id from event_fx where k='regional'),'[{"email":"26f3000005@ds.study.iitm.ac.in","duration_seconds":1300}]')$$,'attendance reimport succeeds');
select is((select count(*)::integer from public.event_attendance),3,'attendance reimport no duplicates');
select throws_ok($$select public.release_event_certificates((select id from event_fx where k='regional'))$$,'22023',null,'release requires signed template');
select throws_ok($$update public.events set certificate_template_url='https://example.test/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000001/signed.png' where id=(select id from event_fx where k='regional')$$,'22023',null,'template must come from project storage');
select throws_ok($$update public.events set certificate_template_url='https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000010/signed.png' where id=(select id from event_fx where k='regional')$$,'22023',null,'template must belong to this event');
select throws_ok($$update public.events set certificate_template_url='https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000001/missing.png' where id=(select id from event_fx where k='regional')$$,'22023',null,'template object must exist');
select lives_ok($$update public.events set certificate_template_url='https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000001/signed.png' where id=(select id from event_fx where k='regional')$$,'organizer attaches signed blank template');
select is((public.release_event_certificates((select id from event_fx where k='regional'))->>'pending_names')::integer,1,'eligible student without confirmed name waits for name');
select is((public.release_event_certificates((select id from event_fx where k='regional'))->>'issued')::integer,0,'repeat release issues no duplicates');
select throws_ok($$select public.import_event_attendance((select id from event_fx where k='regional'),'[{"email":"26f3000005@ds.study.iitm.ac.in","duration_seconds":0}]')$$,'PT409',null,'released attendance locked');
select is(jsonb_array_length(public.export_form_responses('f9000000-0000-4000-8000-000000000001')),1,'organizer scoped responses export');
select ok(not(public.export_form_responses('f9000000-0000-4000-8000-000000000001')->0 ?| array['name','phone']),'export does not expose unrequested profile contact fields');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000001','title','Updated form','event_id',(select id from event_fx where k='regional'),'published_at',now(),'fields','[{"key":"later","label":"Later question","type":"text"}]'::jsonb))$$,'organizer can revise future form questions');
select is((public.export_form_responses('f9000000-0000-4000-8000-000000000001')->0->'field_schema'->0->>'key'),'name','response retains original submitted question schema');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000002','title','Phone consent','region_id',(select id from public.regions where code='region_01'),'published_at',now(),'fields','[{"key":"phone","label":"Phone","type":"phone"}]'::jsonb))$$,'organizer creates profile prefill consent form');
select lives_ok($$select public.review_region_change((select id from public.member_region_requests where status='pending'),true,'Verified')$$,'current-region RC approves member correction without second SA');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000005","role":"authenticated"}';
select throws_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000002','{"phone":"+919990000333"}',true)$$,'42501',null,'region correction removes future access to old regional application');
select lives_ok($$select public.confirm_my_certificate_name('Student Legal Name')$$,'confirmation after release automatically issues eligible certificate');
select is(jsonb_array_length(public.list_my_certificates()),1,'student owns one issued certificate');
select throws_ok($$select public.confirm_my_certificate_name('Different Name')$$,'PT409',null,'confirmed certificate name immutable without correction');
select lives_ok($$select public.update_my_profile('New Lounge Name',null)$$,'later Lounge name freely editable');
select is(public.list_my_certificates()->0->>'certificate_name','Student Legal Name','Lounge edit never changes issued certificate name');
select is((select r.code from public.members m join public.regions r on r.id=m.region_id where m.id=auth.uid()),'region_02','approved correction persists');
select is(public.get_lounge_form_invite('f9000000-0000-4000-8000-000000000001'),null::text,'old-region invite hidden after approved move');
select ok(exists(select 1 from public.lounge_forms where id='f9000000-0000-4000-8000-000000000020'),'a responder still reads the form they answered after leaving its audience');
reset role;
select is((select count(*)::integer from public.issued_certificates),1,'unregistered attendee receives no certificate');
select is((select issued_by from public.issued_certificates),(select id from fx where k='rc'),'issuer is the organizer who released, not the last editor');
create temp table cert_fx as select id from public.issued_certificates;
grant select on cert_fx to anon;
set local role anon;
select ok(public.verify_issued_certificate((select id from cert_fx)) ? 'valid','public verification works');
select ok(not(public.verify_issued_certificate((select id from cert_fx)) ?| array['member_id','certificate_name','email','template_url']),'public verification omits recipient PII');
select is(public.verify_issued_certificate('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),null::jsonb,'unknown certificate returns null');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000008","role":"authenticated"}';
select lives_ok($$select public.select_my_initial_region((select id from public.regions where code='international'))$$,'unknown allocation selects International');
select throws_ok($$select public.select_my_initial_region((select id from public.regions where code='region_01'))$$,'PT409',null,'second initial selection refused');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((public.roster_add_many('[{"email":" NEW@es.study.iitm.ac.in "},{"email":"new@es.study.iitm.ac.in"}]')->1->>'category'),'existing','normalized repeated roster additions deduplicate');
select is((public.roster_add_many(jsonb_build_array(jsonb_build_object('email','26f3000005@ds.study.iitm.ac.in','region_id',(select id from public.regions where code='region_01'))))->0->>'category'),'conflict','add-only roster import reports conflicting region');
reset role;
-- A distinct reviewed attendance event proves the non-Meet gate and 20-minute boundary.
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
reset role;
select lives_ok($$insert into public.events(id,name,starts_at,ends_at,published_at,attendance_mode,certificate_template_url) values('e9000000-0000-4000-8000-000000000010','Reviewed event',now(),now()+interval '1 day',now(),'reviewed','https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000010/signed.png')$$,'reviewed attendance fixture created');
set local role authenticated;
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000010','title','Reviewed registration','event_id','e9000000-0000-4000-8000-000000000010','published_at',now()))$$,'reviewed event has house registration');
reset role;
select lives_ok($$insert into public.events(id,name,starts_at,ends_at,published_at,certificate_template_url) values('e9000000-0000-4000-8000-000000000011','Meet below threshold',now(),now()+interval '1 day',now(),'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/certificate-templates/e9000000-0000-4000-8000-000000000011/signed.png')$$,'separate Meet gate fixture created');
set local role authenticated;
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','f9000000-0000-4000-8000-000000000011','title','Meet gate registration','event_id','e9000000-0000-4000-8000-000000000011','published_at',now()))$$,'Meet gate registration form created');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000005","role":"authenticated"}';
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000010','{}')$$,'member registers reviewed event');
select lives_ok($$select public.submit_lounge_form('f9000000-0000-4000-8000-000000000011','{}')$$,'member registers Meet gate event');
reset role;
set local role authenticated;
set local request.jwt.claims='{"sub":"b9000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok($$select public.import_event_attendance('e9000000-0000-4000-8000-000000000010','[{"email":"26f3000005@ds.study.iitm.ac.in"}]')$$,'22023',null,'non-Meet import requires explicit reviewed eligibility');
select lives_ok($$select public.import_event_attendance('e9000000-0000-4000-8000-000000000010','[{"email":"26f3000005@ds.study.iitm.ac.in","eligible":false}]')$$,'reviewed ineligible attendance stored');
select is((public.release_event_certificates('e9000000-0000-4000-8000-000000000010')->>'issued')::integer,0,'reviewed ineligible attendee receives no certificate');
select lives_ok($$select public.import_event_attendance('e9000000-0000-4000-8000-000000000011','[{"email":"26f3000005@ds.study.iitm.ac.in","duration_seconds":1199}]')$$,'Meet below threshold attendance stored');
select is((public.release_event_certificates('e9000000-0000-4000-8000-000000000011')->>'issued')::integer,0,'1199 seconds cannot satisfy >=1200 gate');
reset role;
-- Hard delete erases every Lounge copy of the member's identity; counts and IDs remain.
create temp table hd(k text primary key,id uuid);
insert into hd values('member',(select id from fx where k='mg')),('response','c9000000-0000-4000-8000-000000000001'),('request','c9000000-0000-4000-8000-000000000002');
insert into public.form_responses(id,form_id,member_id,submitted_email,field_schema,answers) values((select id from hd where k='response'),'f9000000-0000-4000-8000-000000000003',(select id from hd where k='member'),'26f3000010@mg.study.iitm.ac.in','[]','{"phone":"+919990000555"}');
insert into public.event_registrations(event_id,member_id,response_id,registered_email) values((select id from event_fx where k='community'),(select id from hd where k='member'),(select id from hd where k='response'),'26f3000010@mg.study.iitm.ac.in');
insert into public.event_attendance(event_id,row_key,email,member_id,duration_seconds,raw_row,category,imported_by) values((select id from event_fx where k='community'),'26f3000010@mg.study.iitm.ac.in','26f3000010@mg.study.iitm.ac.in',(select id from hd where k='member'),1300,'{"email":"26f3000010@mg.study.iitm.ac.in"}','registered',(select id from fx where k='sa'));
insert into public.issued_certificates(event_id,member_id,certificate_name,template_url,issued_by) values((select id from event_fx where k='community'),(select id from hd where k='member'),'Legal Name','https://example.test/t.png',(select id from fx where k='sa'));
insert into public.certificate_name_requests(member_id,old_name,new_name,reason) values((select id from hd where k='member'),'Legal Name','Legal Name Two','Spelling');
insert into public.member_region_requests(member_id,from_region_id,to_region_id,reason) values((select id from hd where k='member'),(select id from public.regions where code='region_01'),(select id from public.regions where code='region_02'),'Moved city');
set local session_replication_role=replica;
update public.members set certificate_name='Legal Name',certificate_name_confirmed_at=now(),account_status='deleted',deleted_at=now()-interval '31 days' where id=(select id from hd where k='member');
set local session_replication_role=origin;
insert into public.approval_requests(id,type,target_member_id,target_snapshot,reason,requested_by) values((select id from hd where k='request'),'member_hard_delete',(select id from hd where k='member'),'{}','Erase',(select id from fx where k='rc3'));
select lives_ok($$select public.svc_execute_hard_delete((select id from fx where k='sa'),(select id from hd where k='request'))$$,'hard delete executes');
select ok((select certificate_name is null and certificate_name_confirmed_at is null and cohort is null from public.members where id=(select id from hd where k='member')),'hard delete clears certificate name and cohort');
select ok((select answers='{}' and submitted_email like 'deleted-%' from public.form_responses where id=(select id from hd where k='response')),'hard delete erases response answers and email');
select ok((select registered_email like 'deleted-%' from public.event_registrations where member_id=(select id from hd where k='member')),'hard delete erases registration email');
select ok((select email is null and raw_row='{}' and row_key like 'redacted:%' from public.event_attendance where member_id=(select id from hd where k='member')),'hard delete erases attendance email, key and raw row');
select is((select certificate_name from public.issued_certificates where member_id=(select id from hd where k='member')),'Deleted member','hard delete erases certificate name; verification ID remains');
select ok((select old_name is null and new_name='Deleted member' and reason='Redacted' from public.certificate_name_requests where member_id=(select id from hd where k='member')),'hard delete erases certificate name requests');
select is((select reason from public.member_region_requests where member_id=(select id from hd where k='member')),'Redacted','hard delete erases region request reason');

-- No accidental grants on the new tables (TRUNCATE bypasses RLS).
select ok(not has_table_privilege('anon','public.form_responses','TRUNCATE'),'anon lacks response truncate');
select ok(not has_table_privilege('authenticated','public.issued_certificates','UPDATE'),'issued certificate records immutable via API');
select ok(not has_function_privilege('authenticated','private.issue_eligible_certificates(uuid,uuid)','EXECUTE'),'private issuer cannot be invoked by member');
select * from finish();
rollback;

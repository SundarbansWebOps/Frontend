-- pgTAP: save_lounge_form stores form_kind, group fields and archived_at
-- (20261024130000_save_form_kind_and_archive). Synthetic identities only (ids start with c1400000,
-- codes 99f964xxxx). Everything rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('c1400000-0000-4000-8000-000000000098', '99f9640098', '99f9640098@ds.study.iitm.ac.in', 1);
create temp table ct(k text primary key, id uuid, email text);
insert into ct values
 ('sa', 'c1400000-0000-4000-8000-000000000001', '99f9640001@ds.study.iitm.ac.in'),
 ('th', 'c1400000-0000-4000-8000-000000000002', '99f9640002@ds.study.iitm.ac.in');
insert into public.member_roster(email, region_id, added_by) select email, 1, 'c1400000-0000-4000-8000-000000000098' from ct;
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from ct;
insert into public.super_admin_allowlist(user_id, label) select id, 'Test SA form fields' from ct where k = 'sa';
insert into public.admin_assignments(member_id, position, region_id, community_id, assigned_by)
select id, 'head', null, (select id from public.communities where code = 'technical'), (select id from ct where k = 'sa') from ct where k = 'th';
create temp table tid as select (select id from public.communities where code = 'technical') as tech;
grant select on tid to authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1400000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1400000-0000-4000-8000-0000000000f1','title','Patna group',
  'region_id',1,'form_kind','group','group_label','Patna','group_purpose','Meet the Patna region','published_at',now()))$$,
  'Super Admin saves a group form');
select is((select form_kind || '/' || group_label || '/' || group_purpose from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f1'),
  'group/Patna/Meet the Patna region', 'the group fields are stored');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1400000-0000-4000-8000-0000000000f1','title','Patna group, renamed',
  'region_id',1,'published_at',(select published_at from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f1')))$$,
  'a save that omits them');
select is((select form_kind || '/' || group_label from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f1'),
  'group/Patna', 'keeps the stored group fields');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1400000-0000-4000-8000-0000000000f1','title','Patna group, renamed',
  'region_id',1,'form_kind','general','group_label',null,'group_purpose','  '))$$, 'turning it back into a general form');
select is((select form_kind || '/' || coalesce(group_label,'-') || '/' || coalesce(group_purpose,'-') from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f1'),
  'general/-/-', 'clears the group fields');
select throws_ok($$select public.save_lounge_form(jsonb_build_object('id','c1400000-0000-4000-8000-0000000000f1','title','x','region_id',1,'form_kind','poll'))$$,
  '23514', null, 'an unknown form kind is refused');
select lives_ok($$select public.save_lounge_form(jsonb_build_object('id','c1400000-0000-4000-8000-0000000000f2','title','Live survey',
  'community_id',(select tech from tid),'published_at',now() - interval '1 minute'))$$, 'Super Admin publishes a community form');
reset role;
select is((select form_kind from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f2'), 'general', 'a new form defaults to general');

-- The Head archives and restores their live form the way the Archive button does.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1400000-0000-4000-8000-000000000002","role":"authenticated"}';
select lives_ok($$select public.save_lounge_form(to_jsonb(f) || jsonb_build_object('archived_at',now())) from public.lounge_forms f
  where f.id = 'c1400000-0000-4000-8000-0000000000f2'$$, 'Head archives their live form');
select ok((select archived_at is not null from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f2'), 'archiving is stored');
select lives_ok($$select public.save_lounge_form(to_jsonb(f) || jsonb_build_object('archived_at',null)) from public.lounge_forms f
  where f.id = 'c1400000-0000-4000-8000-0000000000f2'$$, 'Head restores it');
select ok((select archived_at is null and published_at is not null from public.lounge_forms where id = 'c1400000-0000-4000-8000-0000000000f2'),
  'restoring clears the archive and keeps it published');
reset role;

select * from finish();
rollback;

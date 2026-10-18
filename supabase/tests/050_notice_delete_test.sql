-- pgTAP: notice removal. Only organizers delete notices, for everyone, scope-checked and audited. Self-contained, inside begin … rollback. Ids start with b5.
begin;
select no_plan();

create temp table fx (k text primary key, id uuid, email text, region text);
insert into fx values
  ('sa', 'b5000000-0000-4000-8000-000000000001', '99f9500001@ds.study.iitm.ac.in', 'region_01'),
  ('rc2', 'b5000000-0000-4000-8000-000000000002', '99f9500002@ds.study.iitm.ac.in', 'region_02'),
  ('m1', 'b5000000-0000-4000-8000-000000000003', '99f9500003@ds.study.iitm.ac.in', 'region_01'),
  ('m2', 'b5000000-0000-4000-8000-000000000004', '99f9500004@ds.study.iitm.ac.in', 'region_01');
grant select on fx to authenticated, service_role;

select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');
-- A bare seed member adds the Super Admin's roster row; the Super Admin adds everyone else.
insert into public.members (id, member_code, email, region_id)
  values ('b5000000-0000-4000-8000-000000000099', '99f9500099', '99f9500099@ds.study.iitm.ac.in',
          (select id from public.regions where code = 'region_01'));
insert into public.member_roster (email, region_id, added_by)
  select email, (select id from public.regions where code = region), 'b5000000-0000-4000-8000-000000000099'
  from fx where k = 'sa';
insert into auth.users (id, email, aud, role, raw_app_meta_data)
  select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from fx where k = 'sa';
insert into public.member_roster (email, region_id, added_by)
  select email, (select id from public.regions where code = region), (select id from fx where k = 'sa')
  from fx where k <> 'sa';
insert into auth.users (id, email, aud, role, raw_app_meta_data)
  select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from fx where k <> 'sa';
insert into public.super_admin_allowlist (user_id, label) select id, 'test sa' from fx where k = 'sa';
insert into public.admin_assignments (member_id, position, region_id, assigned_by)
  select fx.id, 'rc', (select id from public.regions where code = fx.region), (select id from fx where k = 'sa')
  from fx where k = 'rc2';

set local role authenticated;
set local request.jwt.claims = '{"sub":"b5000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$ select public.save_announcement(jsonb_build_object(
  'id','b5100000-0000-4000-8000-000000000001','title','Test notice','body','Oops')) $$,
  'Super Admin posts a house-wide notice');

-- ── Members cannot remove notices ───────────────────────────────────────────
set local request.jwt.claims = '{"sub":"b5000000-0000-4000-8000-000000000003","role":"authenticated"}';
select is(jsonb_array_length(public.list_my_notices()), 1, 'member sees the notice');
select hasnt_function('public', 'hide_my_notice', array['uuid'], 'member hide function is gone');
select lives_ok($$ select public.set_my_notice_state('b5100000-0000-4000-8000-000000000001', true, true) $$,
  'closing the banner still works');
select is(jsonb_array_length(public.list_my_notices()), 1, 'banner dismissal keeps the notice in the bell');

-- ── Organizer delete ────────────────────────────────────────────────────────
select throws_ok($$ select public.delete_announcement('b5100000-0000-4000-8000-000000000001') $$,
  '42501', null, 'ordinary member cannot delete a notice');
set local request.jwt.claims = '{"sub":"b5000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($$ select public.delete_announcement('b5100000-0000-4000-8000-000000000001') $$,
  '42501', null, 'RC cannot delete a house-wide notice');
set local request.jwt.claims = '{"sub":"b5000000-0000-4000-8000-000000000001","role":"authenticated"}';
select lives_ok($$ select public.delete_announcement('b5100000-0000-4000-8000-000000000001') $$,
  'Super Admin deletes the notice');
reset role;
select is((select count(*)::integer from public.announcements where id = 'b5100000-0000-4000-8000-000000000001'),
  0, 'notice is gone');
select is((select count(*)::integer from public.member_notice_states where announcement_id = 'b5100000-0000-4000-8000-000000000001'),
  0, 'member states are gone');
select is((select old_values->>'title' from public.audit_log where action = 'notice.delete'
           and target_id = 'b5100000-0000-4000-8000-000000000001'),
  'Test notice', 'audit log keeps the deleted notice for recovery');

select * from finish();
rollback;

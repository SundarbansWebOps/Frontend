-- "I've joined all my groups" preference: self only, active member only, audited.
-- Synthetic identities only. Every fixture rolls back.
begin;
select no_plan();
select vault.create_secret(repeat('local-pgtap-only-',3),'blacklist_hash_pepper') where not exists(select 1 from vault.decrypted_secrets where name='blacklist_hash_pepper');

insert into public.members(id, member_code, email, region_id)
values ('ad1b0000-0000-4000-8000-000000000098', '99f1920098', '99f1920098@ds.study.iitm.ac.in', 1);
create temp table gfh_people(id uuid, email text);
insert into gfh_people values
 ('ad1b0000-0000-4000-8000-000000000001', '99f1920001@ds.study.iitm.ac.in'),
 ('ad1b0000-0000-4000-8000-000000000002', '99f1920002@ds.study.iitm.ac.in'),
 ('ad1b0000-0000-4000-8000-000000000003', '99f1920003@ds.study.iitm.ac.in');
insert into public.member_roster(email, region_id, added_by)
select email, 1, 'ad1b0000-0000-4000-8000-000000000098' from gfh_people;
grant select on gfh_people to authenticated;
insert into auth.users(id, email, aud, role, raw_app_meta_data)
select id, email, 'authenticated', 'authenticated', '{"provider":"google"}'::jsonb from gfh_people;

select is((select group_forms_hidden from public.members where id = 'ad1b0000-0000-4000-8000-000000000001'), false, 'defaults to shown');

set local role authenticated;
set local request.jwt.claims = '{"sub":"ad1b0000-0000-4000-8000-000000000001","role":"authenticated"}';
select is(public.set_group_forms_hidden(true), true, 'member hides the section');
select is((select group_forms_hidden from public.members where id = auth.uid()), true, 'flag reads back through the members self-select');
select lives_ok($$select public.set_group_forms_hidden(true)$$, 'repeating the same value is harmless');
select throws_ok($$select public.set_group_forms_hidden(null)$$, '22023', 'Choose hidden or shown', 'null is rejected');
select throws_ok($$update public.members set group_forms_hidden = false where id = auth.uid()$$, '42501', null, 'direct column update is denied');
select is((select count(*)::int from public.members where group_forms_hidden and id <> auth.uid() and id in (select id from gfh_people)), 0, 'setting your own flag leaves other members alone');
select is(public.set_group_forms_hidden(false), false, 'member shows the section again');
reset role;

select is((select count(*)::int from public.audit_log where action = 'member.group_forms_hidden' and target_id = 'ad1b0000-0000-4000-8000-000000000001'), 2, 'only real changes are audited (hide, then show)');
select is((select new_values->>'group_forms_hidden' from public.audit_log where action = 'member.group_forms_hidden' order by id desc limit 1), 'false', 'audit records the new value');
select is((select group_forms_hidden from public.members where id = 'ad1b0000-0000-4000-8000-000000000002'), false, 'another member is untouched');

update public.members set account_status = 'suspended' where id = 'ad1b0000-0000-4000-8000-000000000003';
set local role authenticated;
set local request.jwt.claims = '{"sub":"ad1b0000-0000-4000-8000-000000000003","role":"authenticated"}';
select throws_ok($$select public.set_group_forms_hidden(true)$$, '42501', 'Account is not active', 'suspended member is denied');
reset role;
select is((select group_forms_hidden from public.members where id = 'ad1b0000-0000-4000-8000-000000000003'), false, 'denied call changed nothing');

set local role anon;
select throws_ok($$select public.set_group_forms_hidden(true)$$, '42501', null, 'anonymous callers have no execute grant');
reset role;

select * from finish();
rollback;

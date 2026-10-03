-- Go-live: remove the fake (seed / test) accounts and everything tied to them
-- The production project was used for development and testing, so it still holds the fake users
-- from seed.sql and the test runs. This migration deletes exactly those, identified by the fixed
-- fake id pattern seed.sql and the tests use (11111111-… to 88888888-…-0000000000NN). Real accounts
-- (the Super Admins from migration 20261001232700) never match it. On a fresh project with no seed
-- data this migration changes nothing.
--
-- The append-only guards on audit_log and approval_requests are switched off only for the duration
-- of this transaction, and row auditing is suppressed so the cleanup itself writes no audit rows
-- about deleted test accounts. Both guards are switched back on before commit.

create temporary table go_live_fake_ids on commit drop as
select id
from public.members
where id::text ~ '^(11111111|22222222|33333333|44444444|55555555|66666666|77777777|88888888)-0000-4000-8000-0000000000[0-9]{2}$'
union
select id
from auth.users
where id::text ~ '^(11111111|22222222|33333333|44444444|55555555|66666666|77777777|88888888)-0000-4000-8000-0000000000[0-9]{2}$';

create temporary table go_live_fake_requests on commit drop as
select id
from public.approval_requests
where target_member_id in (select id from go_live_fake_ids)
   or requested_by     in (select id from go_live_fake_ids)
   or reviewed_by      in (select id from go_live_fake_ids);

select set_config('app.suppress_row_audit', 'on', true);
alter table public.audit_log disable trigger audit_log_no_update_delete;
alter table public.approval_requests disable trigger approval_requests_no_delete;

delete from public.audit_log
where actor_id in (select id from go_live_fake_ids)
   or target_id in (select id::text from go_live_fake_ids)
   or request_id in (select id from go_live_fake_requests)
   or (target_table = 'admin_assignments'
       and target_id in (select id::text from public.admin_assignments
                         where member_id in (select id from go_live_fake_ids)
                            or assigned_by in (select id from go_live_fake_ids)));

delete from private.auth_email_authorizations
where user_id in (select id from go_live_fake_ids);

delete from public.blacklist_entries
where member_id  in (select id from go_live_fake_ids)
   or created_by in (select id from go_live_fake_ids)
   or lifted_by  in (select id from go_live_fake_ids)
   or request_id in (select id from go_live_fake_requests);

delete from public.approval_requests
where id in (select id from go_live_fake_requests);

delete from public.events
where created_by in (select id from go_live_fake_ids)
   or updated_by in (select id from go_live_fake_ids);

delete from public.admin_assignments
where member_id   in (select id from go_live_fake_ids)
   or assigned_by in (select id from go_live_fake_ids);

delete from public.member_private
where member_id in (select id from go_live_fake_ids);

delete from public.regional_registrations
where member_id in (select id from go_live_fake_ids);

delete from public.community_registrations
where member_id in (select id from go_live_fake_ids);

delete from public.super_admin_allowlist
where user_id in (select id from go_live_fake_ids);

delete from public.members
where id in (select id from go_live_fake_ids);

-- auth.identities, sessions and refresh tokens cascade from auth.users.
delete from auth.users
where id in (select id from go_live_fake_ids);

alter table public.approval_requests enable trigger approval_requests_no_delete;
alter table public.audit_log enable trigger audit_log_no_update_delete;
select set_config('app.suppress_row_audit', 'off', true);

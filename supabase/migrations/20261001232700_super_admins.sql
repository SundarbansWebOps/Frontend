-- Production Super Admins (frontend review item 10)
-- The allowlist is keyed by auth user id and changes only by migration (CLAUDE.md). The accounts
-- are created through Supabase Auth first; this migration looks them up by email, so no user ids
-- or credentials are stored in the repo. On a project where an account does not exist yet, its
-- row is simply skipped (re-run the insert in a later migration once the person has signed up).
-- Hard deletes need two different Super Admins, so at least two of these must stay active.

insert into public.super_admin_allowlist (user_id, label)
select u.id, v.label
from (values
  ('sundarbans-webad@ds.study.iitm.ac.in', 'Web Admin'),
  ('21f3001973@ds.study.iitm.ac.in',       'Super Admin (21f3001973)'),
  ('sundarbans-sec@ds.study.iitm.ac.in',   'Secretary')
) as v(email, label)
join auth.users u on lower(u.email) = v.email
on conflict (user_id) do nothing;

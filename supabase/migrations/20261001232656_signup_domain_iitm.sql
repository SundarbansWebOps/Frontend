-- Restrict sign-up to IITM student email addresses (frontend review item 5, open question Q7)
-- Uses the allowlist mechanism from migration 23: once private.signup_email_domains has any row,
-- handle_new_auth_user refuses sign-ups from every other domain ("Database error saving new user"
-- in Auth; the reason is not shown to the client).
--
-- Existing accounts are not affected. Super Admins and staff who do not have an IITM address must
-- sign up BEFORE this migration is applied, or their domain must be added here.
-- The blacklist check at sign-up already exists (migration 22) and keeps working with this.
--
-- CONFIRM BEFORE MERGING: is ds.study.iitm.ac.in the only domain? (e.g. es.study.iitm.ac.in for the
-- Electronic Systems programme, or staff addresses.) Add one row per allowed domain.

insert into private.signup_email_domains (domain) values
  ('ds.study.iitm.ac.in')
on conflict (domain) do nothing;

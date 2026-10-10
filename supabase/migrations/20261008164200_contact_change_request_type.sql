-- Two-person rule for login email changes: a new request type, added on its own so the next
-- migration can use it (enum values must be committed first).
alter type public.request_type add value if not exists 'member_contact_change';

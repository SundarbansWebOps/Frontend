-- A Head or Co-Head asks a Super Admin to publish their form (owner, 2026-10-24).
-- Its own migration: a new enum value cannot be used in the transaction that adds it, and
-- 20261024120100_form_publish_approval uses it in constraints and indexes.
alter type public.request_type add value if not exists 'form_publish';

-- A Head or Co-Head asks a Super Admin to take a student off their community (owner, 2026-10-24).
-- Its own migration: a new enum value cannot be used in the transaction that adds it, and
-- 20261023202050_community_tags uses it in constraints and indexes.
alter type public.request_type add value if not exists 'community_tag_removal';

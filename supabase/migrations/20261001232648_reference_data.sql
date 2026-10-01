-- Reference data: communities and regions (frontend review item 3)
-- Until now these rows came only from seed.sql, so a project rebuilt from migrations had no
-- regions and every sign-up failed ("A valid region_code is required"). This migration makes the
-- rows part of the schema history. Idempotent: on a project that already has them (e.g. the dev
-- project, seeded) it changes nothing.
--
-- Regions: the 10 codes below are the placeholders the project already uses. Their codes are what
-- sign-up sends as region_code; the display names can be corrected in a follow-up migration once
-- the real region names are confirmed (open question Q24), e.g.
--   update public.regions set name = 'Chennai' where code = 'region_01';
-- Never delete or renumber a region: members.region_id and RC assignments reference it.

insert into public.communities (code, name) values
  ('esports',   'E-Sports'),
  ('technical', 'Technical'),
  ('cultural',  'Cultural')
on conflict (code) do nothing;

insert into public.regions (code, name)
select format('region_%s', lpad(n::text, 2, '0')), format('Region %s', lpad(n::text, 2, '0'))
from generate_series(1, 10) as n
on conflict (code) do nothing;

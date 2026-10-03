-- Real region names (open question Q24)
-- The 9 Sundarbans regions replace the placeholder names from migration 20261001232648. Codes stay
-- the same (sign-up sends region_code, and members / RC assignments reference the row), so only the
-- display name changes. The tenth placeholder, region_10, has no real region and is removed; the
-- delete is refused if anything references it (all FKs to regions are NO ACTION).

update public.regions r
set name = v.name
from (values
  ('region_01', 'Patna'),
  ('region_02', 'Delhi NCR'),
  ('region_03', 'Mumbai'),
  ('region_04', 'Chandigarh'),
  ('region_05', 'Kolkata'),
  ('region_06', 'Hyderabad'),
  ('region_07', 'Lucknow'),
  ('region_08', 'Bengaluru'),
  ('region_09', 'Chennai')
) as v(code, name)
where r.code = v.code;

delete from public.regions where code = 'region_10';

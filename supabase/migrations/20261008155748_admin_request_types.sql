-- Admin panel, part 1: new approval request types
-- Every change to student data now goes through a request that a different Super Admin approves
-- (two-person rule). New enum values must be committed before any constraint or function can use
-- them, so they are added on their own, ahead of part 2 (admin_panel_backend).
--   member_profile_update  name, preferred name, gender, phone or region (RC: own region; SA: anyone)
--   member_status_change   suspend, reinstate, restore, lift blacklist (SA files)
--   position_change        assign or revoke an RC / Head / Co-Head position (SA files)

alter type public.request_type add value if not exists 'member_profile_update';
alter type public.request_type add value if not exists 'member_status_change';
alter type public.request_type add value if not exists 'position_change';

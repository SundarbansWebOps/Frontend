-- House-wide events created by an RC go live only after a Super Admin approves (owner, 2026-10-13).
-- New enum values must be committed before use, so the request type is added on its own.
alter type public.request_type add value if not exists 'event_publish';

-- Seed fixtures for local dev and tests.
-- Members here are FAKE test accounts. The real roster lives in the council
-- Google Sheet and reaches the members table only through the members-sync
-- Edge Function — never commit it to git.

-- ── Regions (slugs mirror src/views/meetups/regionConfigs.js) ───────────
insert into public.regions (slug, name) values
  ('bangalore',  'Bangalore'),
  ('chandigarh', 'Chandigarh'),
  ('chennai',    'Chennai'),
  ('delhi',      'Delhi NCR'),
  ('hyderabad',  'Hyderabad'),
  ('kolkata',    'Kolkata'),
  ('mumbai',     'Mumbai'),
  ('patna',      'Patna'),
  ('lucknow',    'Lucknow');

-- ── Members (FAKE fixtures) ──────────────────────────────────────────────
insert into public.members (email, full_name, region, roll_number, is_active) values
  ('member1@test.local',  'Test Member One',   'Chennai', '21F1000001', true),
  ('member2@test.local',  'Test Member Two',   'Mumbai',  '22F3000002', true),
  ('alumni1@test.local',  'Test Inactive',     'Delhi',   '20F1000003', false);

-- ── Events ───────────────────────────────────────────────────────────────
insert into public.events (title, description, community, starts_at, ends_at, venue, registration_url, status, published_at) values
  ('Hackathon: Build in 24hrs', '24-hour team hackathon across all tracks.', 'technical',
     now() + interval '20 days', now() + interval '21 days', 'Main Hall, Block A',
     'https://example.com/register/hackathon', 'published', now() - interval '2 days'),
  ('AI/ML Paper Reading Club', 'Fortnightly deep-dive into a recent AI/ML paper.', 'technical',
     now() + interval '9 days', null, 'Room 204, Tech Block', null, 'published', now() - interval '2 days'),
  ('Sundarban Utsav', 'Annual cultural festival evening.', 'cultural',
     now() + interval '30 days', now() + interval '30 days' + interval '5 hours', 'Open Air Theatre',
     'https://example.com/register/utsav', 'published', now() - interval '1 day'),
  ('Spoken Word Open Mic', 'Poetry and storytelling night.', 'cultural',
     now() + interval '14 days', null, 'Cafeteria Lawn', null, 'published', now() - interval '1 day'),
  ('Valorant House Clash', 'Inter-region 5v5 tournament.', 'esports',
     now() + interval '12 days', now() + interval '12 days' + interval '4 hours', 'Online',
     'https://example.com/register/valorant', 'published', now() - interval '1 day'),
  ('Open Source Contribution Drive', 'Guided first-PR session.', 'technical',
     now() + interval '25 days', null, 'Computer Lab 3, Block B', null, 'pending_review', null),
  ('Photography Walk (draft)', 'Unapproved placeholder event.', 'cultural',
     now() + interval '40 days', null, 'TBD', null, 'draft', null);

-- ── Meetups ──────────────────────────────────────────────────────────────
insert into public.meetups (region_id, meetup_no, title, description, venue, starts_at, total_students, collaboration, social_url, status, published_at)
select r.id, v.meetup_no, v.title, v.description, v.venue, v.starts_at, v.total_students, v.collaboration, v.social_url, v.status, v.published_at
from (values
  ('chennai', 521, 'Chennai Meetup #521', 'Joint meetup with neighbouring chapters.', 'Chennai', now() - interval '35 days', 27,
     'sundarbans X kaziranga X Namalla X Sportify', 'https://www.instagram.com/p/example1', 'published'::content_status, now() - interval '30 days'),
  ('mumbai', 489, 'Mumbai Meetup #489', 'Semester kickoff meetup.', 'Mumbai', now() - interval '20 days', 54,
     null, 'https://www.instagram.com/p/example2', 'published'::content_status, now() - interval '18 days'),
  ('delhi', 512, 'Delhi NCR Pre-Exams Meetup', 'Group study + chai.', 'Delhi', now() + interval '10 days', null,
     null, null, 'published'::content_status, now() - interval '1 day'),
  ('chennai', 522, 'Chennai Meetup #522 (draft)', 'Draft for the next Chennai meetup.', 'Chennai', now() + interval '18 days', null,
     null, null, 'draft'::content_status, null)
) as v(slug, meetup_no, title, description, venue, starts_at, total_students, collaboration, social_url, status, published_at)
join public.regions r on r.slug = v.slug;

-- ── Important dates ──────────────────────────────────────────────────────
insert into public.important_dates (title, category, starts_on, ends_on, notes, status, published_at) values
  ('End-term examination window', 'exam', current_date + 25, current_date + 33,
     'Check the LMS for your slot timetable.', 'published', now() - interval '3 days'),
  ('Course registration opens', 'academic', current_date + 8, null, null, 'published', now() - interval '3 days'),
  ('Re-apply deadline (draft)', 'academic', current_date + 60, null, null, 'draft', null);

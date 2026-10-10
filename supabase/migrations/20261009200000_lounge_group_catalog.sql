-- Restore group discovery independently of the broader audit rollout.
-- Existing list_lounge_forms returns to_jsonb(f), so these fields are exposed automatically.

-- Group metadata is source-backed and editable in the organizer UI. Only verified membership
-- applications are promoted; recruitment forms remain distinct. Missing source copy stays empty.
alter table public.lounge_forms
  add column form_kind text not null default 'general'
    check (form_kind in ('general','group','recruitment')),
  add column group_label text check (group_label is null or length(btrim(group_label)) between 1 and 80),
  add column group_purpose text check (group_purpose is null or length(btrim(group_purpose)) <= 300),
  add column archived_at timestamptz;
update public.lounge_forms set form_kind='group',
  group_label=case id::text
    when '1cb30c9f-d48a-5fc4-b1db-5cb6f99cfb74' then 'Bengaluru'
    when '7bf59906-1960-5c2a-93c9-8624d70ac42e' then 'Chandigarh'
    when '67e5b09c-2b8a-52a0-b326-01d0a2bf54cb' then 'Chennai'
    when '0add795d-a412-5c49-bf58-bfad378e80ad' then 'Delhi'
    when '14cec811-73a5-54ef-a8f1-7b8222fbc691' then 'Kolkata'
    when '6d4f1bee-33f2-5f0f-a97b-4866993d7a39' then 'Mumbai'
    when 'ef6e5e79-5ea5-56dc-b81e-b5c75373694c' then 'Patna'
    when '2fe75761-88af-5422-a3c7-d8e86830d3e2' then 'Technical'
    when '5a905465-ec6c-50f2-9503-40cc2e97d00d' then 'Cultural'
    when '4f142402-d390-512b-89e3-8193705b809e' then 'Esports'
  end
where id in (
 '1cb30c9f-d48a-5fc4-b1db-5cb6f99cfb74','7bf59906-1960-5c2a-93c9-8624d70ac42e',
 '67e5b09c-2b8a-52a0-b326-01d0a2bf54cb','0add795d-a412-5c49-bf58-bfad378e80ad',
 '14cec811-73a5-54ef-a8f1-7b8222fbc691','6d4f1bee-33f2-5f0f-a97b-4866993d7a39',
 'ef6e5e79-5ea5-56dc-b81e-b5c75373694c','2fe75761-88af-5422-a3c7-d8e86830d3e2',
 '5a905465-ec6c-50f2-9503-40cc2e97d00d','4f142402-d390-512b-89e3-8193705b809e'
);

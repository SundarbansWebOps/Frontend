-- "I've joined all my groups": a student who joined the WhatsApp groups before the site
-- existed hides the Lounge's WhatsApp groups section. The flag is the student's own
-- preference, readable through the existing members self-select and changed only by the RPC
-- below (the column is not in the members UPDATE grant).
alter table public.members
  add column group_forms_hidden boolean not null default false;

comment on column public.members.group_forms_hidden is
  'Student-set: hide the Lounge WhatsApp groups section (already joined them all). Set only via set_group_forms_hidden().';

create function public.set_group_forms_hidden(p_hidden boolean)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old boolean;
begin
  if not private.is_active_member() then
    raise exception 'Account is not active' using errcode = '42501';
  end if;
  if p_hidden is null then
    raise exception 'Choose hidden or shown' using errcode = '22023';
  end if;

  select group_forms_hidden into v_old
    from public.members where id = auth.uid() for update;

  if v_old is distinct from p_hidden then
    update public.members set group_forms_hidden = p_hidden where id = auth.uid();
    perform private.write_audit(
      'member.group_forms_hidden', 'members', auth.uid()::text,
      jsonb_build_object('group_forms_hidden', v_old),
      jsonb_build_object('group_forms_hidden', p_hidden)
    );
  end if;
  return p_hidden;
end;
$$;

revoke execute on function public.set_group_forms_hidden(boolean)
  from public, anon, authenticated, service_role;
grant execute on function public.set_group_forms_hidden(boolean) to authenticated;

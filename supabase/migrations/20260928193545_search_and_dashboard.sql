-- Migration 21: search_members() and get_my_dashboard()
-- Spec §12 (search), §4 (dashboard routing), §9, §14.
--
-- search_members(query, include_deleted default false)
--   Searches name (full and preferred), email, phone and member_code with a pg_trgm index.
--   Scope comes only from auth.uid(); no scope parameter exists (§12):
--     Super Admin      all members (include_deleted = true also returns soft-deleted ones)
--     RC               members of their region, not soft-deleted (same rule as RLS, Q19a)
--     Head / Co-Head   members with an ACTIVE registration in their community (§9, §12)
--     anyone else      refused (42501), including inactive accounts
--   include_deleted is a Super Admin display option, not a scope; others' value is ignored.
--   The query is data, never a pattern: LIKE wildcards (% _) and the escape character are
--   escaped, so crafted input can only match literally. Length 3..100.
--   Results: at most 50, best trigram similarity first.
--
-- get_my_dashboard()
--   { role, position, region_id, community_id } derived only from auth.uid() through the
--   access helpers (§4). role: super_admin | admin | normal. Inactive accounts are refused.
--   Convenience only: every table and function re-checks scope on its own.

-- ── Trigram index ───────────────────────────────────────────────────────────
-- One expression index over all searchable fields. The same expression is used verbatim in
-- search_members() so the planner can use it. Only immutable built-ins (||, coalesce, lower).

create index members_search_trgm_idx on public.members
  using gin ((lower(full_name || ' ' || coalesce(preferred_name, '') || ' ' || email || ' ' || phone || ' ' || member_code))
             extensions.gin_trgm_ops);

-- ── search_members ──────────────────────────────────────────────────────────

create function public.search_members(p_query text, p_include_deleted boolean default false)
returns table (
  id             uuid,
  member_code    text,
  full_name      text,
  preferred_name text,
  email          text,
  phone          text,
  region_id      smallint,
  account_status public.account_status,
  score          real
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query       text := btrim(p_query);
  v_needle      text;
  v_pattern     text;
  v_digits      text;
  v_digit_pat   text;
  v_is_sa       boolean := (select private.is_super_admin());
  v_region      smallint := (select private.my_rc_region());
  v_communities smallint[] := (select private.my_community_ids());
begin
  if not v_is_sa and v_region is null and cardinality(v_communities) = 0 then
    raise exception 'Search is not available for your account' using errcode = 'insufficient_privilege';
  end if;

  if v_query is null or length(v_query) < 3 or length(v_query) > 100 then
    raise exception 'Search text must be 3 to 100 characters' using errcode = 'invalid_parameter_value';
  end if;

  -- Literal match only: escape the escape character first, then the wildcards.
  v_needle  := lower(v_query);
  v_pattern := '%' || replace(replace(replace(v_needle, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  -- "+1 202-555 0106" should find +12025550106: also try the digits alone for phone-like input.
  v_digits := regexp_replace(v_query, '[^0-9]', '', 'g');
  if v_query ~ '^[0-9+() .-]+$' and length(v_digits) >= 4 then
    v_digit_pat := '%' || v_digits || '%';
  end if;

  return query
  select m.id, m.member_code, m.full_name, m.preferred_name, m.email, m.phone, m.region_id, m.account_status,
         extensions.similarity(
           lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || m.phone || ' ' || m.member_code),
           v_needle) as score
  from public.members m
  where (   lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || m.phone || ' ' || m.member_code)
              like v_pattern
         or (v_digit_pat is not null
             and lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || m.phone || ' ' || m.member_code)
                   like v_digit_pat))
    and (
          (v_is_sa and (p_include_deleted or m.account_status <> 'deleted'))
       or (not v_is_sa and v_region is not null
           and m.region_id = v_region and m.account_status <> 'deleted')
       or (not v_is_sa and v_region is null and cardinality(v_communities) > 0
           and m.account_status <> 'deleted'
           and exists (select 1 from public.community_registrations r
                       where r.member_id = m.id and r.status = 'active'
                         and r.community_id = any (v_communities)))
        )
  -- By position: "score" alone would be ambiguous with the OUT parameter of the same name.
  order by 9 desc, 3, 1
  limit 50;
end;
$$;

comment on function public.search_members(text, boolean) is
  'Scoped member search (§12). Scope from auth.uid() only; query matched literally; 3..100 chars; max 50 rows.';

revoke execute on function public.search_members(text, boolean) from public, anon, service_role;
grant execute on function public.search_members(text, boolean) to authenticated;

-- ── get_my_dashboard ────────────────────────────────────────────────────────
-- Security invoker: it only calls the access helpers and reads the caller's own assignment
-- (visible to them through admin_assignments RLS).

create function public.get_my_dashboard()
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_region      smallint;
  v_communities smallint[];
  v_position    public.admin_position;
begin
  if not (select private.is_active_member()) then
    raise exception 'Account is not active' using errcode = 'insufficient_privilege';
  end if;

  if (select private.is_super_admin()) then
    return jsonb_build_object('role', 'super_admin', 'position', null, 'region_id', null, 'community_id', null);
  end if;

  v_region := (select private.my_rc_region());
  if v_region is not null then
    return jsonb_build_object('role', 'admin', 'position', 'rc', 'region_id', v_region, 'community_id', null);
  end if;

  v_communities := (select private.my_community_ids());
  if cardinality(v_communities) > 0 then
    select a.position into v_position
    from public.admin_assignments a
    where a.member_id = (select auth.uid()) and a.ended_at is null and a.community_id = v_communities[1];

    return jsonb_build_object('role', 'admin', 'position', v_position, 'region_id', null,
                              'community_id', v_communities[1]);
  end if;

  return jsonb_build_object('role', 'normal', 'position', null, 'region_id', null, 'community_id', null);
end;
$$;

comment on function public.get_my_dashboard() is
  'Dashboard routing (§4): { role, position, region_id, community_id } from auth.uid() only. Convenience; every call re-checks scope.';

revoke execute on function public.get_my_dashboard() from public, anon, service_role;
grant execute on function public.get_my_dashboard() to authenticated;
;

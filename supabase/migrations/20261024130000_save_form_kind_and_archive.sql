-- save_lounge_form never stored form_kind, group_label, group_purpose or archived_at
-- (20261009200000 added the columns after the function), so Archive and the group fields in the
-- organizer editor were silently dropped. Store them; a save that omits a key keeps the old value.
do $patch$
declare
 body text:=pg_get_functiondef('public.save_lounge_form(jsonb)'::regprocedure);
 fixed text:=body;
 edits text[][]:=array[
  ['source_url,joins_community)',
   'source_url,joins_community,form_kind,group_label,group_purpose,archived_at)'],
  [',coalesce((p_form->>''joins_community'')::boolean,false))',
   ',coalesce((p_form->>''joins_community'')::boolean,false),coalesce(p_form->>''form_kind'',''general''),'
   ||'nullif(btrim(p_form->>''group_label''),''''),nullif(btrim(p_form->>''group_purpose''),''''),(p_form->>''archived_at'')::timestamptz)'],
  ['else lounge_forms.joins_community end,updated_at=now();',
   'else lounge_forms.joins_community end,'
   ||'form_kind=case when p_form ? ''form_kind'' then excluded.form_kind else lounge_forms.form_kind end,'
   ||'group_label=case when p_form ? ''group_label'' then excluded.group_label else lounge_forms.group_label end,'
   ||'group_purpose=case when p_form ? ''group_purpose'' then excluded.group_purpose else lounge_forms.group_purpose end,'
   ||'archived_at=case when p_form ? ''archived_at'' then excluded.archived_at else lounge_forms.archived_at end,updated_at=now();']];
 i int;
begin
 for i in 1..array_length(edits,1) loop
  -- Each anchor must match exactly once.
  if (length(fixed)-length(replace(fixed,edits[i][1],'')))/length(edits[i][1]) <> 1 then
   raise exception 'save_lounge_form changed: anchor % not found once, update this migration',i;
  end if;
  fixed:=replace(fixed,edits[i][1],edits[i][2]);
 end loop;
 execute fixed;
end $patch$;

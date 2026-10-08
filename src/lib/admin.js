// Admin lounge data: every call goes through Supabase as the signed-in RC or Super Admin, and
// the database decides what they may see or change (row-level security plus the RPC checks).
// Changes to a student's record are requests; a different Super Admin approves them.
import { supabase } from './supabase.js';

const unwrap = ({ data, error, count }) => {
  if (error) throw error;
  return count === undefined || count === null ? data : { data, count };
};

export const PAGE = 50;

export const REQUEST_LABEL = {
  member_deletion: 'Delete member',
  member_blacklist: 'Blacklist member',
  member_hard_delete: 'Erase permanently',
  member_profile_update: 'Edit details',
  member_contact_change: 'Change login email',
  member_status_change: 'Change status',
  position_change: 'Change position',
  community_record_update: 'Edit community record',
  community_record_deletion: 'Delete community record',
};

export const POSITION_LABEL = { rc: 'Regional Coordinator', head: 'Head', co_head: 'Co-Head' };
export const STATUS_ACTION_LABEL = {
  suspend: 'Suspend',
  reinstate: 'Reinstate',
  restore: 'Restore',
  lift_blacklist: 'Lift blacklist',
};

// Lookups

export async function loadLookups() {
  const [regions, communities] = await Promise.all([
    supabase.from('regions').select('id, code, name').order('code'),
    supabase.from('communities').select('id, code, name').order('id'),
  ]);
  return { regions: unwrap(regions), communities: unwrap(communities) };
}

// Overview counts (each one already scoped by the database).

// RC: pending counts their own requests; Super Admin: the whole queue (RLS decides).
export async function loadCounts() {
  const head = { count: 'exact', head: true };
  const now = new Date().toISOString();
  const [members, roster, events, pending] = await Promise.all([
    supabase.from('members').select('id', head).neq('account_status', 'deleted'),
    supabase.from('member_roster').select('email', head),
    supabase.from('events').select('id', head).is('deleted_at', null).gte('ends_at', now),
    supabase.from('approval_requests').select('id', head).eq('status', 'pending'),
  ]);
  return {
    members: members.count ?? 0,
    roster: roster.count ?? 0,
    events: events.count ?? 0,
    pending: pending.count ?? 0,
  };
}

// Students

const MEMBER_COLS =
  'id, member_code, full_name, preferred_name, email, phone, gender, region_id, account_status, deleted_at, created_at, last_login_at';

export async function listMembers({ regionId = null, status = 'current', page = 0 } = {}) {
  let q = supabase
    .from('members')
    .select(MEMBER_COLS, { count: 'exact' })
    .order('full_name')
    .range(page * PAGE, page * PAGE + PAGE - 1);
  if (regionId) q = q.eq('region_id', regionId);
  if (status === 'current') q = q.neq('account_status', 'deleted');
  else if (status) q = q.eq('account_status', status);
  return unwrap(await q);
}

export async function searchMembers(query, includeDeleted = false) {
  return unwrap(
    await supabase.rpc('search_members', { p_query: query, p_include_deleted: includeDeleted })
  );
}

export async function getMember(id) {
  const [m, pos, reg] = await Promise.all([
    supabase.from('members').select(MEMBER_COLS).eq('id', id).maybeSingle(),
    supabase
      .from('admin_assignments')
      .select('id, position, region_id, community_id, started_at')
      .eq('member_id', id)
      .is('ended_at', null)
      .maybeSingle(),
    supabase
      .from('regional_registrations')
      .select('answers, updated_at')
      .eq('member_id', id)
      .maybeSingle(),
  ]);
  const member = unwrap(m);
  return { member, position: pos.error ? null : pos.data, regional: reg.error ? null : reg.data };
}

// Requests about a student

export const requestUpdate = (memberId, changes, reason) =>
  supabase
    .rpc('request_member_update', { p_member_id: memberId, p_changes: changes, p_reason: reason })
    .then(unwrap);
export const requestDeletion = (memberId, reason) =>
  supabase.rpc('request_member_deletion', { p_member_id: memberId, p_reason: reason }).then(unwrap);
export const requestBlacklist = (memberId, reason) =>
  supabase.rpc('request_blacklist', { p_member_id: memberId, p_reason: reason }).then(unwrap);
export const requestStatus = (memberId, action, reason) =>
  supabase
    .rpc('request_status_change', { p_member_id: memberId, p_action: action, p_reason: reason })
    .then(unwrap);
export const requestPosition = (memberId, action, position, communityId, reason) =>
  supabase
    .rpc('request_position_change', {
      p_member_id: memberId,
      p_action: action,
      p_position: position ?? null,
      p_community_id: communityId ?? null,
      p_reason: reason,
    })
    .then(unwrap);
// Login email: one Super Admin files, another approves through change-member-contact.
export const requestContactChange = (memberId, email, reason) =>
  supabase
    .rpc('request_contact_change', { p_member_id: memberId, p_email: email, p_reason: reason })
    .then(unwrap);
export const requestHardDelete = (memberId, reason) =>
  supabase.rpc('request_hard_delete', { p_member_id: memberId, p_reason: reason }).then(unwrap);

// Roster (students who have not signed in yet)

export async function listRoster() {
  return unwrap(
    await supabase
      .from('member_roster')
      .select('email, full_name, phone, region_id, gender, added_at')
      .order('added_at', { ascending: false })
  );
}

export const rosterAdd = (row) =>
  supabase
    .rpc('roster_add', {
      p_email: row.email,
      p_full_name: row.full_name,
      p_phone: row.phone || null,
      p_region_id: row.region_id || null,
      p_gender: row.gender || null,
    })
    .then(unwrap);
export const rosterAddMany = (rows) =>
  supabase.rpc('roster_add_many', { p_rows: rows }).then(unwrap);
export const rosterRemove = (email) =>
  supabase.rpc('roster_remove', { p_email: email }).then(unwrap);

// One student per line, tab- or comma-separated: email, full name[, phone][, region][, gender].
// Phone may be left empty.
// Spreadsheet copies paste as tabs. A header row is skipped.
export function parseRosterPaste(text, regions) {
  const byCode = new Map(regions.map((r) => [r.code, r.id]));
  const byName = new Map(regions.map((r) => [r.name.toLowerCase(), r.id]));
  return text
    .split(/\r?\n/)
    .map((line) => line.split(line.includes('\t') ? '\t' : ',').map((c) => c.trim()))
    .filter((c) => c.length >= 2 && c[0] && c[1] && !/^e-?mail$/i.test(c[0]))
    .map(([email, full_name, phone, region, gender]) => ({
      email,
      full_name,
      phone: phone || null,
      region_id: region
        ? (byCode.get(region.toLowerCase()) ?? byName.get(region.toLowerCase()) ?? null)
        : null,
      gender: gender || null,
    }));
}

// Events

const EVENT_COLS =
  'id, name, description, registration_link, gmail_link, starts_at, ends_at, community_id, cancelled_at, deleted_at, created_at, updated_at';

export async function listEvents({ past = false } = {}) {
  const now = new Date().toISOString();
  let q = supabase.from('events').select(EVENT_COLS).is('deleted_at', null).limit(100);
  q = past
    ? q.lt('ends_at', now).order('starts_at', { ascending: false })
    : q.gte('ends_at', now).order('starts_at');
  return unwrap(await q);
}

export async function saveEvent(event) {
  const row = {
    name: event.name,
    description: event.description || null,
    registration_link: event.registration_link || null,
    gmail_link: event.gmail_link || null,
    starts_at: event.starts_at,
    ends_at: event.ends_at,
    community_id: event.community_id || null,
  };
  const q = event.id
    ? supabase.from('events').update(row).eq('id', event.id).select('id')
    : supabase.from('events').insert(row).select('id');
  const data = unwrap(await q);
  if (!data?.length) throw new Error('This event could not be saved. Reload and try again.');
  return data[0].id;
}

export async function setEventCancelled(id, cancelled) {
  return unwrap(
    await supabase
      .from('events')
      .update({ cancelled_at: cancelled ? new Date().toISOString() : null })
      .eq('id', id)
      .select('id')
  );
}

export async function deleteEvent(id) {
  return unwrap(
    await supabase
      .from('events')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
      .select('id')
  );
}

// Approval requests

const REQUEST_COLS = `id, type, status, reason, requested_change, target_snapshot, review_note, requested_at,
  reviewed_at, requested_by, reviewed_by, target_member_id,
  target:members!approval_requests_target_member_id_fkey(full_name, member_code, region_id),
  requester:members!approval_requests_requested_by_fkey(full_name)`;

export async function listRequests({ status = 'pending' } = {}) {
  let q = supabase
    .from('approval_requests')
    .select(REQUEST_COLS)
    .order('requested_at', { ascending: false })
    .limit(100);
  q = status === 'pending' ? q.eq('status', 'pending') : q.neq('status', 'pending');
  return unwrap(await q);
}

export const approveRequest = (id, note) =>
  supabase.rpc('approve_request', { p_request_id: id, p_note: note || null }).then(unwrap);
export const rejectRequest = (id, note) =>
  supabase.rpc('reject_request', { p_request_id: id, p_note: note || null }).then(unwrap);
export const cancelRequest = (id) =>
  supabase.rpc('cancel_request', { p_request_id: id }).then(unwrap);

async function invoke(name, body) {
  const { data, error } = await supabase.functions.invoke(name, { body });
  if (error) {
    let message = error.message;
    try {
      message = (await error.context?.json())?.error ?? message;
    } catch {
      /* keep the generic message */
    }
    throw new Error(message);
  }
  return data;
}

// Sign-in access follows the member's status (an inactive member is banned in Auth).
export const syncSignInAccess = (memberId) =>
  invoke('apply-account-status', { member_id: memberId });
// A second Super Admin approves a login email change (Auth and members move together).
export const executeContactChange = (requestId, note) =>
  invoke('change-member-contact', { request_id: requestId, note: note || null });
// Permanent erasure is executed by a second Super Admin through its Edge Function.
export const executeHardDelete = (requestId) =>
  invoke('hard-delete-member', { request_id: requestId });

// Positions and audit (Super Admin)

export async function listPositions() {
  return unwrap(
    await supabase
      .from('admin_assignments')
      .select(
        'id, position, region_id, community_id, started_at, member:members!admin_assignments_member_id_fkey(id, full_name, member_code)'
      )
      .is('ended_at', null)
  );
}

export async function listAudit(page = 0) {
  const rows = unwrap(
    await supabase
      .from('audit_log')
      .select('id, created_at, action, target_table, target_id, result, actor_id, request_id')
      .order('created_at', { ascending: false })
      .range(page * PAGE, page * PAGE + PAGE - 1)
  );
  const ids = [...new Set(rows.map((r) => r.actor_id).filter(Boolean))];
  const names = ids.length
    ? unwrap(await supabase.from('members').select('id, full_name').in('id', ids))
    : [];
  const byId = new Map(names.map((n) => [n.id, n.full_name]));
  return rows.map((r) => ({ ...r, actor: byId.get(r.actor_id) ?? null }));
}

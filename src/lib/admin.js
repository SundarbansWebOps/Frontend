// Admin lounge data: every call goes through Supabase as the signed-in organizer, and
// the database decides what they may see or change (row-level security plus the RPC checks).
// Changes to a student's record are requests; a different Super Admin approves them.
// Student region corrections are reviewed by the current-region RC or a Super Admin (Q15).
import { supabase } from './supabase.js';
import { auth, isHead, isRc, isSuperAdmin } from './auth.js';
import {
  exportEventRecords as loungeExportEventRecords,
  exportFormResponses as loungeExportFormResponses,
  getAvailableCohorts as loungeGetAvailableCohorts,
  importAttendance as loungeImportAttendance,
  listAttendance as loungeListAttendance,
  listCertificateNameRequests as loungeListCertificateNameRequests,
  listForms as loungeListForms,
  listRegionRequests as loungeListRegionRequests,
  releaseCertificates as loungeReleaseCertificates,
  reviewCertificateNameRequest as loungeReviewCertificateNameRequest,
  reviewRegionRequest as loungeReviewRegionRequest,
  saveForm as loungeSaveForm,
  saveNotice as loungeSaveNotice,
  uploadCertificateTemplate as loungeUploadCertificateTemplate,
} from './lounge.js';

const unwrap = ({ data, error, count }) => {
  if (error) throw error;
  return count === undefined || count === null ? data : { data, count };
};

const asList = (data) => (Array.isArray(data) ? data : []);

export const PAGE = 50;
export const FORM_FIELD_TYPES = [
  'text',
  'textarea',
  'email',
  'phone',
  'select',
  'checkbox',
  'multiselect',
];
export const PREFILL_KEYS = ['name', 'phone', 'email'];
export const MEET_ELIGIBLE_SECONDS = 1200;
export const TEMPLATE_MAX_BYTES = 10485760;
export const TEMPLATE_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

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

export function isInternationalRegion(region) {
  return region?.code === 'international' || /^international$/i.test(region?.name ?? '');
}

export function fieldKeyFromLabel(label, used = []) {
  let key = String(label || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 64);
  if (!/^[a-z]/.test(key)) key = `f_${key}`.slice(0, 64);
  if (!key) key = 'field';
  let out = key;
  let n = 2;
  while (used.includes(out)) {
    out = `${key.slice(0, 60)}_${n}`;
    n += 1;
  }
  return out;
}

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

export async function listRoster({ query = '', page = 0 } = {}) {
  let q = supabase
    .from('member_roster')
    .select('email, full_name, phone, region_id, gender, added_at', { count: 'exact' })
    .order('added_at', { ascending: false })
    .order('email')
    .range(page * PAGE, page * PAGE + PAGE - 1);
  if (query.trim()) {
    // Quote PostgREST filter values and search wildcard characters literally.
    const pattern = JSON.stringify(`%${query.trim().replace(/[\\%_]/g, '\\$&')}%`);
    q = q.or(`email.ilike.${pattern},full_name.ilike.${pattern}`);
  }
  return unwrap(await q);
}

export const rosterAdd = (row) =>
  supabase
    .rpc('roster_add', {
      p_email: row.email,
      p_full_name: row.full_name || null,
      p_phone: row.phone || null,
      p_region_id: row.region_id || null,
      p_gender: row.gender || null,
    })
    .then(unwrap);
export const rosterAddMany = (rows) =>
  supabase.rpc('roster_add_many', { p_rows: rows }).then(unwrap);
export const rosterRemove = (email) =>
  supabase.rpc('roster_remove', { p_email: email }).then(unwrap);

function regionIdFrom(value, regions) {
  if (!value) return null;
  const key = String(value).trim().toLowerCase();
  if (!key) return null;
  const byCode = new Map(regions.map((r) => [r.code.toLowerCase(), r.id]));
  const byName = new Map(regions.map((r) => [r.name.toLowerCase(), r.id]));
  return byCode.get(key) ?? byName.get(key) ?? null;
}

// One student per line, tab- or comma-separated: email[, full name][, phone][, region][, gender].
// Name, phone, region and gender may be left empty. Spreadsheet copies paste as tabs.
export function parseRosterPaste(text, regions) {
  return text
    .split(/\r?\n/)
    .map((line) => line.split(line.includes('\t') ? '\t' : ',').map((c) => c.trim()))
    .filter((c) => c.length >= 1 && c[0] && !/^e-?mail$/i.test(c[0]))
    .map(([email, full_name, phone, region, gender]) => ({
      email,
      full_name: full_name || null,
      phone: phone || null,
      region_id: regionIdFrom(region, regions),
      region_error: region && !regionIdFrom(region, regions) ? `Unknown region: ${region}` : null,
      gender: gender || null,
    }));
}

export function parseCsv(text) {
  const rows = [];
  let row = [];
  let cell = '';
  let q = false;
  const pushCell = () => {
    row.push(cell);
    cell = '';
  };
  const pushRow = () => {
    if (row.some((c) => c.trim())) rows.push(row.map((c) => c.trim()));
    row = [];
  };
  const src = String(text ?? '').replace(/^\uFEFF/, '');
  for (let i = 0; i < src.length; i += 1) {
    const ch = src[i];
    if (q) {
      if (ch === '"') {
        if (src[i + 1] === '"') {
          cell += '"';
          i += 1;
        } else q = false;
      } else cell += ch;
    } else if (ch === '"') q = true;
    else if (ch === ',') pushCell();
    else if (ch === '\n') {
      pushCell();
      pushRow();
    } else if (ch !== '\r') cell += ch;
  }
  pushCell();
  pushRow();
  return rows;
}

const HEADER_ALIASES = {
  email: ['email', 'e-mail', 'student_email', 'student email', 'mail'],
  full_name: ['full name', 'name', 'full_name', 'student name', 'student_name'],
  phone: ['phone', 'mobile', 'whatsapp', 'phone number'],
  region: ['region', 'allocated_region', 'allocated region', 'house region'],
  gender: ['gender'],
};

function headerIndex(headers, aliases) {
  const lower = headers.map((h) => h.toLowerCase());
  for (const a of aliases) {
    const i = lower.indexOf(a);
    if (i >= 0) return i;
  }
  return -1;
}

export function suggestRosterMapping(headers) {
  return {
    email: headerIndex(headers, HEADER_ALIASES.email),
    full_name: headerIndex(headers, HEADER_ALIASES.full_name),
    phone: headerIndex(headers, HEADER_ALIASES.phone),
    region: headerIndex(headers, HEADER_ALIASES.region),
    gender: headerIndex(headers, HEADER_ALIASES.gender),
  };
}

export function rowsFromRosterCsv(rows, mapping, regions) {
  if (!rows.length) return [];
  const [headers, ...body] = rows;
  const col = (name, line) => {
    const i = mapping[name];
    return i >= 0 ? (line[i] ?? '').trim() : '';
  };
  const seen = new Map();
  const out = [];
  for (const line of body) {
    const email = col('email', line).toLowerCase();
    if (!email) continue;
    const rawRegion = col('region', line);
    const row = {
      email,
      full_name: col('full_name', line) || null,
      phone: col('phone', line) || null,
      region_id: regionIdFrom(rawRegion, regions),
      region_error:
        rawRegion && !regionIdFrom(rawRegion, regions) ? `Unknown region: ${rawRegion}` : null,
      gender: col('gender', line) || null,
      _headers: headers,
      _raw: line,
    };
    if (seen.has(email)) {
      seen.get(email).duplicate = true;
      row.duplicate = true;
    } else {
      seen.set(email, row);
    }
    out.push(row);
  }
  return out;
}

export function toCsv(rows, columns) {
  const esc = (v) => {
    let s = v == null ? '' : typeof v === 'object' ? JSON.stringify(v) : String(v);
    // Member-typed text must never run as a spreadsheet formula.
    if (typeof v !== 'number' && /^[=+\-@\t\r]/.test(s)) s = `'${s}`;
    return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const cols = columns ?? [
    ...new Set(rows.flatMap((r) => (r && typeof r === 'object' ? Object.keys(r) : []))),
  ];
  const columnKey = (column) => (typeof column === 'object' ? column.key : column);
  const columnLabel = (column) => (typeof column === 'object' ? column.label : column);
  return [
    cols.map((column) => esc(columnLabel(column))).join(','),
    ...rows.map((r) => cols.map((column) => esc(r?.[columnKey(column)])).join(',')),
  ].join('\n');
}

export function downloadCsv(filename, rows, columns) {
  const blob = new Blob([toCsv(rows, columns)], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function flattenExportRows(value) {
  if (Array.isArray(value)) {
    return value.map((row) => {
      if (!row || typeof row !== 'object' || Array.isArray(row)) return { value: row };
      const out = {};
      for (const [k, v] of Object.entries(row)) {
        out[k] = v && typeof v === 'object' ? JSON.stringify(v) : v;
      }
      return out;
    });
  }
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([section, rows]) =>
      flattenExportRows(rows).map((row) => ({ section, ...row }))
    );
  }
  return [];
}

// Events

const EVENT_COLS =
  'id, name, description, registration_link, gmail_link, starts_at, ends_at, community_id, region_id, published_at, audience_cohorts, attendance_mode, certificate_template_url, certificates_released_at, archive, source_key, display_date, image_url, event_type, wing, location, image_width, image_height, attendee_count, attendee_display, cancelled_at, deleted_at, created_at, updated_at';

export async function listEvents({ view = 'upcoming' } = {}) {
  const now = new Date().toISOString();
  let q = supabase.from('events').select(EVENT_COLS).is('deleted_at', null);
  if (view === 'drafts') {
    q = q.is('published_at', null).order('updated_at', { ascending: false }).order('id');
  } else if (view === 'past') {
    q = q.not('published_at', 'is', null).order('starts_at', { ascending: false }).order('id');
  } else {
    q = q
      .not('published_at', 'is', null)
      .eq('archive', false)
      .gte('ends_at', now)
      .order('starts_at')
      .order('id');
  }
  const rows = [];
  for (let from = 0; ; from += 200) {
    const page = unwrap(await q.range(from, from + 199));
    rows.push(...page);
    if (page.length < 200) break;
  }
  const visible =
    view === 'past' ? rows.filter((e) => e.archive || (e.ends_at && e.ends_at < now)) : rows;
  return visible.map((event) => ({ ...event, can_manage: canManageEvent(event) }));
}

// RLS can expose events to members who may read public history. Keep organizer actions
// aligned with the dashboard scope while the RPC remains the authoritative write check.
export function canManageEvent(event) {
  if (!event || !auth.dashboard) return false;
  if (isSuperAdmin.value) return true;
  if (isRc.value) return event.region_id === auth.dashboard.region_id && event.community_id == null;
  if (isHead.value)
    return event.community_id === auth.dashboard.community_id && event.region_id == null;
  return false;
}

export async function saveEvent(event, { publish = false, unpublish = false } = {}) {
  const row = {
    name: event.name,
    description: event.description || null,
    registration_link: event.registration_link || null,
    gmail_link: event.gmail_link || null,
    starts_at: event.starts_at || null,
    ends_at: event.ends_at || null,
    community_id: event.community_id || null,
    region_id: event.region_id || null,
    audience_cohorts: event.audience_cohorts ?? [],
    attendance_mode: event.attendance_mode || 'meet',
    certificate_template_url: event.certificate_template_url || null,
    archive: !!event.archive,
    source_key: event.source_key || null,
    display_date: event.display_date || null,
    image_url: event.image_url || null,
    event_type: event.event_type || null,
    wing: event.wing || null,
    location: event.location || null,
    image_width: event.image_width || null,
    image_height: event.image_height || null,
    attendee_count: event.attendee_count ?? null,
    attendee_display: event.attendee_display || null,
  };
  if (publish) row.published_at = new Date().toISOString();
  else if (unpublish) row.published_at = null;
  else if (event.published_at) row.published_at = event.published_at;
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
  return unwrap(await supabase.rpc('soft_delete_event', { p_event_id: id, p_deleted: true }));
}

export async function uploadCertificateTemplate(eventId, file) {
  if (!eventId) throw new Error('Save the event before attaching a signed template.');
  return loungeUploadCertificateTemplate(eventId, file);
}

// Cohorts (India calendar; Q20–Q24). RPC is the live source; the local calendar matches the SQL.

function indiaYmd(at = new Date()) {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  })
    .formatToParts(at)
    .reduce((acc, p) => {
      acc[p.type] = p.value;
      return acc;
    }, {});
  return { year: Number(parts.year), month: Number(parts.month), day: Number(parts.day) };
}

export function currentCohort(at = new Date()) {
  const { year, month } = indiaYmd(at);
  const term = month < 5 ? '1' : month < 9 ? '2' : '3';
  return `${String(year).slice(-2)}F${term}`;
}

export function nextCohort(at = new Date()) {
  const { year, month } = indiaYmd(at);
  const nextYear = month < 9 ? year : year + 1;
  const nextMonth = month < 5 ? 5 : month < 9 ? 9 : 1;
  return currentCohort(new Date(`${nextYear}-${String(nextMonth).padStart(2, '0')}-01T06:00:00Z`));
}

export function cohortCalendar(at = new Date()) {
  const current = currentCohort(at);
  const next = nextCohort(at);
  const options = [];
  for (let year = 2017; year <= 2100; year += 1) {
    for (const term of [1, 2, 3]) {
      const code = `${String(year).slice(-2)}F${term}`;
      options.push(code);
      if (code === next) return { current, next, options };
    }
  }
  return { current, next, options };
}

export async function getAvailableCohorts() {
  try {
    const data = await loungeGetAvailableCohorts();
    if (data?.options?.length) return data;
  } catch {
    /* calendar below matches the SQL rollover */
  }
  return cohortCalendar();
}

export function termsForYear(year, cohorts) {
  const yy = String(year).slice(-2);
  return ['1', '2', '3'].filter((t) => cohorts.options.includes(`${yy}F${t}`)).map((t) => `F${t}`);
}

export function yearFromCohort(code) {
  const yy = Number(String(code).slice(0, 2));
  if (Number.isNaN(yy)) return null;
  return 2000 + yy;
}

// Forms — lounge.js adapters, with list/export normalized to arrays for the admin UI.

export async function listForms() {
  return asList(await loungeListForms());
}

export const saveForm = (form) => loungeSaveForm(form);

export async function exportFormResponses(formId) {
  return asList(await loungeExportFormResponses(formId));
}

export function formResponsesToCsv(payload) {
  const rows = asList(payload);
  const fields = [];
  const byIdentity = new Map();
  for (const row of rows) {
    for (const field of row.field_schema || []) {
      if (!field?.key) continue;
      const identity = JSON.stringify([field.key, field.label || field.key, field.type || '']);
      if (byIdentity.has(identity)) continue;
      const column = `answer:${identity}`;
      const entry = { key: field.key, identity, column, label: field.label || field.key };
      byIdentity.set(identity, entry);
      fields.push(entry);
    }
  }
  const usedLabels = new Set(['email', 'submitted_at']);
  const labelCounts = new Map();
  for (const field of fields) {
    const base = String(field.label || field.key);
    labelCounts.set(base, (labelCounts.get(base) ?? 0) + 1);
  }
  for (const field of fields) {
    const base = String(field.label || field.key);
    let label = labelCounts.get(base) > 1 || usedLabels.has(base) ? `${base} [${field.key}]` : base;
    let suffix = 2;
    while (usedLabels.has(label)) label = `${base} [${field.key}-${suffix++}]`;
    field.label = label;
    usedLabels.add(label);
  }
  const columns = [
    { key: 'email', label: 'email' },
    { key: 'submitted_at', label: 'submitted_at' },
    ...fields.map((field) => ({ key: field.column, label: field.label })),
  ];
  const csvRows = rows.map((row) => {
    const out = { email: row.email, submitted_at: row.submitted_at };
    for (const captured of row.field_schema || []) {
      const identity = JSON.stringify([
        captured.key,
        captured.label || captured.key,
        captured.type || '',
      ]);
      const field = byIdentity.get(identity);
      if (!field) continue;
      const value = row.answers?.[captured.key];
      out[field.column] = Array.isArray(value) ? value.join('; ') : (value ?? '');
    }
    return out;
  });
  return { columns, rows: csvRows, fields };
}

export async function listEventRegistrations(eventId) {
  return unwrap(
    await supabase
      .from('event_registrations')
      .select('event_id, member_id, registered_email, registered_at')
      .eq('event_id', eventId)
  );
}

export async function listAttendance(eventId) {
  return asList(await loungeListAttendance(eventId));
}

export const importAttendance = (
  eventId,
  rows,
  options = { mode: 'merge', sourceId: 'admin-upload' }
) => loungeImportAttendance(eventId, rows, options);

export const releaseCertificates = (eventId) => loungeReleaseCertificates(eventId);

export async function exportEventRecords(eventId) {
  return loungeExportEventRecords(eventId);
}

export function normalizeEmail(value) {
  return String(value ?? '')
    .trim()
    .toLowerCase();
}

export function isMaskedEmail(value) {
  const email = normalizeEmail(value);
  return !email || /[*…]/.test(email) || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

export function parseDurationSeconds(raw) {
  if (raw == null || raw === '') return null;
  const s = String(raw).trim().toLowerCase();
  if (/^\d+(\.\d+)?$/.test(s)) return Math.round(Number(s));
  const hms = s.match(/^(\d+):(\d{1,2})(?::(\d{1,2}))?$/);
  if (hms) {
    const h = Number(hms[1]);
    const m = Number(hms[2]);
    const sec = Number(hms[3] || 0);
    if (hms[3] == null && h <= 24 && m < 60) return h * 3600 + m * 60;
    return h * 3600 + m * 60 + sec;
  }
  let total = 0;
  let matched = false;
  const hour = s.match(/(\d+(?:\.\d+)?)\s*h(?:ours?)?/);
  const min = s.match(/(\d+(?:\.\d+)?)\s*m(?:in(?:utes?)?)?/);
  const sec = s.match(/(\d+(?:\.\d+)?)\s*s(?:ec(?:onds?)?)?/);
  if (hour) {
    total += Number(hour[1]) * 3600;
    matched = true;
  }
  if (min) {
    total += Number(min[1]) * 60;
    matched = true;
  }
  if (sec) {
    total += Number(sec[1]);
    matched = true;
  }
  return matched ? Math.round(total) : null;
}

const MEET_HEADERS = {
  email: ['email', 'e-mail', 'email address'],
  duration: ['duration', 'duration of meeting', 'time in call'],
  first: ['first name', 'first'],
  last: ['last name', 'last'],
  joined: ['time joined', 'join time'],
  exited: ['time exited', 'leave time'],
};

export function suggestMeetMapping(headers) {
  return {
    email: headerIndex(headers, MEET_HEADERS.email),
    duration: headerIndex(headers, MEET_HEADERS.duration),
    first: headerIndex(headers, MEET_HEADERS.first),
    last: headerIndex(headers, MEET_HEADERS.last),
    joined: headerIndex(headers, MEET_HEADERS.joined),
    exited: headerIndex(headers, MEET_HEADERS.exited),
  };
}

export function previewAttendance({
  rows,
  mapping,
  registrations = [],
  mode = 'meet',
  eligibleSeconds = MEET_ELIGIBLE_SECONDS,
}) {
  if (!rows.length) {
    return { registered: [], unregistered: [], absent: [], unresolved: [], importRows: [] };
  }
  const [, ...body] = rows;
  const col = (name, line) => {
    const i = mapping[name];
    return i >= 0 ? (line[i] ?? '').trim() : '';
  };
  const registeredEmails = new Set(
    registrations.map((r) => normalizeEmail(r.registered_email || r.email)).filter(Boolean)
  );
  const seenAttend = new Set();
  const registered = [];
  const unregistered = [];
  const unresolved = [];
  const importMap = new Map();
  const unresolvedImportRows = [];

  for (const [index, line] of body.entries()) {
    const email = normalizeEmail(col('email', line));
    const duration_seconds = parseDurationSeconds(col('duration', line));
    const item = {
      email,
      duration_seconds,
      first: col('first', line),
      last: col('last', line),
      joined: col('joined', line),
      exited: col('exited', line),
    };
    if (isMaskedEmail(email)) {
      const itemRow = { ...item, eligible: false, source_row_id: String(index + 1) };
      unresolved.push(item);
      unresolvedImportRows.push(itemRow);
      continue;
    }
    const eligible =
      mode === 'reviewed' ? !!item._eligible : (duration_seconds ?? 0) >= eligibleSeconds;
    const importRow = {
      email,
      duration_seconds: duration_seconds ?? 0,
      eligible: mode === 'reviewed' ? eligible : (duration_seconds ?? 0) >= eligibleSeconds,
    };
    if (importMap.has(email)) {
      const prev = importMap.get(email);
      prev.duration_seconds += importRow.duration_seconds;
      prev.eligible = prev.eligible || importRow.eligible;
    } else importMap.set(email, importRow);
    item.eligible =
      mode === 'reviewed'
        ? eligible
        : (importMap.get(email).duration_seconds ?? 0) >= eligibleSeconds;
    seenAttend.add(email);
    if (registeredEmails.has(email)) registered.push(item);
    else unregistered.push(item);
  }

  const absent = [...registeredEmails]
    .filter((email) => !seenAttend.has(email))
    .map((email) => ({ email, duration_seconds: 0, eligible: false }));

  return {
    registered,
    unregistered,
    absent,
    unresolved,
    importRows: [...importMap.values(), ...unresolvedImportRows],
  };
}

export function applyReviewedEligibility(preview, email, eligible) {
  const row = preview.importRows.find((r) => r.email === email);
  if (row) row.eligible = eligible;
  for (const list of [preview.registered, preview.unregistered]) {
    for (const item of list) if (item.email === email) item.eligible = eligible;
  }
}

// Notices (organizer)

export async function listNoticesAdmin({ page = 0 } = {}) {
  return unwrap(
    await supabase
      .from('announcements')
      .select(
        'id, title, body, link, region_id, community_id, audience_cohorts, starts_at, ends_at, created_at'
      )
      .order('starts_at', { ascending: false })
      .order('id')
      .range(page * PAGE, page * PAGE + PAGE - 1)
  );
}

export const saveNotice = (notice) => loungeSaveNotice(notice);

// Student region requests (Q15) and certificate-name requests (SA)

export async function listRegionRequests() {
  return asList(await loungeListRegionRequests());
}

export const reviewRegionRequest = (id, approve, note = '') =>
  loungeReviewRegionRequest(id, approve, note);

export async function listCertificateNameRequests() {
  return asList(await loungeListCertificateNameRequests());
}

export const reviewCertificateNameRequest = (id, approve, note = '') =>
  loungeReviewCertificateNameRequest(id, approve, note);

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

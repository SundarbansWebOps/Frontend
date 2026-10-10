// Member flows and organizer operations use the same database contracts. The database owns
// eligibility, publication, organizer scope and persistent state; browser hints grant no access.
let client;
const sb = async () => (client ??= (await import('./supabase.js')).supabase);
const unwrap = ({ data, error }) => {
  if (error) throw error;
  return data;
};
async function rpc(name, params) {
  return unwrap(await (await sb()).rpc(name, params));
}
export async function loadLounge() {
  const supabase = await sb();
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  const uid = data.session?.user?.id;
  if (!uid) throw new Error('Sign in to enter the Lounge.');
  const [profile, events, forms, notices, certificates, regionRequests] = await Promise.all([
    supabase
      .from('members')
      .select(
        'id,member_code,full_name,preferred_name,email,phone,region_id,tour_seen_at,certificate_name,certificate_name_confirmed_at,cohort,region:regions(code,name)'
      )
      .eq('id', uid)
      .single()
      .then(unwrap),
    listLoungeEvents(),
    listForms(),
    listNotices(),
    listCertificates(),
    listRegionRequests(),
  ]);
  return { uid, profile, events, forms, notices, certificates, regionRequests };
}
export const updateProfile = ({ preferred_name = null, phone = null }) =>
  rpc('update_my_profile', { p_preferred_name: preferred_name, p_phone: phone });
export const markTourSeen = (seen = true) => rpc('set_my_tour_seen', { p_seen: seen });
export const selectInitialRegion = (regionId) =>
  rpc('select_my_initial_region', { p_region_id: regionId });
export const requestRegionChange = (regionId, reason) =>
  rpc('request_my_region_change', { p_region_id: regionId, p_reason: reason });
export async function listRegionRequests() {
  return unwrap(
    await (await sb()).from('member_region_requests').select('*').order('requested_at', {
      ascending: false,
    })
  );
}
export const reviewRegionRequest = (id, approve, note = '') =>
  rpc('review_region_change', { p_request_id: id, p_approve: approve, p_note: note || null });
export const listLoungeEvents = () => rpc('list_lounge_events');
export const listPublicPastEvents = () => rpc('list_public_past_events');
export const getAvailableCohorts = () => rpc('get_available_cohorts');
export const listForms = () => rpc('list_lounge_forms');
export const saveForm = (form) => rpc('save_lounge_form', { p_form: form });
export const submitForm = (id, answers, savePhone = false) =>
  rpc('submit_lounge_form', { p_form_id: id, p_answers: answers, p_save_phone: savePhone });
export const getFormInvite = (id) => rpc('get_lounge_form_invite', { p_form_id: id });
export const groupFormsForMember = (forms, regionId) =>
  forms.filter(
    (form) =>
      form.form_kind === 'group' &&
      !form.archived_at &&
      !form.event_id &&
      (form.region_id == null || form.region_id === regionId)
  );

export async function listGroups(forms = null, regionId = null) {
  const submitted = groupFormsForMember(forms ?? (await listForms()), regionId).filter(
    (form) => form.submitted
  );
  return Promise.all(
    submitted.map(async (form) => {
      try {
        const invite = await getFormInvite(form.id);
        return {
          id: form.id,
          name: form.group_label || form.title,
          purpose: form.group_purpose || '',
          invite_url: invite || '',
          invite_unavailable: !invite,
          applied: true,
          region_id: form.region_id,
          community_id: form.community_id,
        };
      } catch (error) {
        return {
          id: form.id,
          name: form.group_label || form.title,
          purpose: form.group_purpose || '',
          invite_url: '',
          invite_error: error?.message || 'Invite link is not available yet.',
          applied: true,
          region_id: form.region_id,
          community_id: form.community_id,
        };
      }
    })
  );
}
export const listNotices = () => rpc('list_my_notices');
export const setNoticeState = (id, { read = true, dismiss = false } = {}) =>
  rpc('set_my_notice_state', { p_announcement_id: id, p_read: read, p_dismiss: dismiss });
export const saveNotice = (notice) => rpc('save_announcement', { p_announcement: notice });
export const listCertificates = () => rpc('list_my_certificates');
export const confirmCertificateName = (name) =>
  rpc('confirm_my_certificate_name', { p_name: name });
export const requestCertificateNameChange = (name, reason) =>
  rpc('request_certificate_name_change', { p_name: name, p_reason: reason });
export async function listCertificateNameRequests() {
  return unwrap(
    await (await sb()).from('certificate_name_requests').select('*').order('requested_at', {
      ascending: false,
    })
  );
}
export const reviewCertificateNameRequest = (id, approve, note = '') =>
  rpc('review_certificate_name_change', {
    p_request_id: id,
    p_approve: approve,
    p_note: note || null,
  });
export const verifyCertificate = (id) => rpc('verify_issued_certificate', { p_id: id });
export const importAttendance = (eventId, rows, options = {}) =>
  rpc('import_event_attendance', {
    p_event_id: eventId,
    p_rows: rows,
    p_mode: options.mode ?? 'merge',
    p_source_id: options.sourceId ?? 'default',
  });
export async function listAttendance(eventId) {
  return unwrap(
    await (
      await sb()
    )
      .from('event_attendance')
      .select(
        'event_id,row_key,import_source,import_sources,email,member_id,duration_seconds,reviewed_eligible,category,imported_at'
      )
      .eq('event_id', eventId)
      .order('category')
      .order('email')
  );
}
export const releaseCertificates = (eventId) =>
  rpc('release_event_certificates', { p_event_id: eventId });
export const exportFormResponses = (formId) => rpc('export_form_responses', { p_form_id: formId });
export const exportEventRecords = (eventId) => rpc('export_event_records', { p_event_id: eventId });
export async function uploadCertificateTemplate(eventId, file) {
  const extensions = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp' };
  const extension = extensions[file.type];
  if (!extension || file.size > 10 * 1024 * 1024)
    throw new Error('Choose a PNG, JPEG or WebP signed template under 10 MB.');
  const supabase = await sb();
  const path = `${eventId}/${crypto.randomUUID()}.${extension}`;
  unwrap(
    await supabase.storage.from('certificate-templates').upload(path, file, {
      contentType: file.type,
      upsert: false,
    })
  );
  return supabase.storage.from('certificate-templates').getPublicUrl(path).data.publicUrl;
}

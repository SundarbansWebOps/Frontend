/**
 * Sundarbans House — Google Sheet → Supabase roster sync (Apps Script side).
 *
 * The council Google Sheet stays the source of truth for membership. Bind
 * this script to the member-roster spreadsheet; it pushes every active row
 * into the members-sync Edge Function, which upserts the members table.
 *
 ── One-time setup (Spreadsheet → Extensions → Apps Script) ──────────────
 * 1. Paste this file as Code.gs.
 * 2. Project Settings → Script Properties, add:
 *      SYNC_URL    = https://<project-ref>.supabase.co/functions/v1/members-sync
 *                    (local dev: http://127.0.0.1:54421/functions/v1/members-sync)
 *      SYNC_SECRET = the value of MEMBERS_SYNC_SECRET
 * 3. Run syncMembers once by hand to grant the UrlFetchApp scope.
 * 4. Triggers → add an installable trigger: syncMembers, "On change" or a
 *    daily time-driven trigger. (Sheet edits by the council then propagate
 *    within a minute.)
 *
 * Expected sheet layout (first tab, header row first):
 *   A: Email | B: Full Name | C: Region | D: Roll Number | E: Active (TRUE/FALSE)
 * Column letters are configurable in COLUMNS below.
 */

const COLUMNS = { email: 1, fullName: 2, region: 3, rollNumber: 4, active: 5 };

function syncMembers() {
  const props = PropertiesService.getScriptProperties();
  const url = props.getProperty('SYNC_URL');
  const secret = props.getProperty('SYNC_SECRET');
  if (!url || !secret) {
    throw new Error('Set SYNC_URL and SYNC_SECRET in Script Properties.');
  }

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheets()[0];
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) {
    console.log('Roster sheet has no data rows; nothing to sync.');
    return;
  }

  const members = [];
  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    const email = String(row[COLUMNS.email - 1] ?? '')
      .trim()
      .toLowerCase();
    if (!email) continue; // skip blank separators
    members.push({
      email: email,
      full_name: String(row[COLUMNS.fullName - 1] ?? '').trim() || null,
      region: String(row[COLUMNS.region - 1] ?? '').trim() || null,
      roll_number: String(row[COLUMNS.rollNumber - 1] ?? '').trim() || null,
      is_active:
        row[COLUMNS.active - 1] !== false &&
        String(row[COLUMNS.active - 1] ?? '').toUpperCase() !== 'FALSE',
      source_updated_at: new Date().toISOString(),
    });
  }

  const res = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { 'x-sync-secret': secret },
    payload: JSON.stringify({ members: members, replace: true }),
    muteHttpExceptions: true,
  });

  console.log('members-sync responded %s: %s', res.getResponseCode(), res.getContentText());
  if (res.getResponseCode() !== 200) {
    throw new Error('Roster sync failed — see the log for the response body.');
  }
}

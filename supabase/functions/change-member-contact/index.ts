// change-member-contact (two-person rule)
// POST { "request_id": uuid, "note"?: string }
// Caller: a Super Admin OTHER than the one who filed the request with request_contact_change().
//
// Approves a member_contact_change request and moves the login email in Supabase Auth and in
// members together:
//   1. svc_contact_request_plan: checks the request (pending, other Super Admin) and re-validates
//      the new email (format, not in use, never a Super Admin's address). No writes.
//   2. Authorize exactly that address (the auth.users guard trigger refuses any other email
//      change), then update it in Auth (confirmed, no email round-trip).
//   3. svc_complete_contact_request: re-validate under lock, write members, mark the request
//      approved, audit. If step 3 fails, step 2 is reverted so Auth and members never disagree.
// Direct changes are no longer accepted. Phone numbers change through profile-update requests.
import { admin, HttpError, optionalString, readJson, requireSuperAdmin, rpc, serve, uuidField } from "../_shared/common.ts";
serve("change-member-contact", async (req)=>{
  const actor = await requireSuperAdmin(req);
  const body = await readJson(req);
  const requestId = uuidField(body, "request_id");
  const note = optionalString(body, "note", 2000);
  const plan = await rpc("svc_contact_request_plan", {
    p_actor: actor,
    p_request_id: requestId
  });
  const memberId = plan.member_id;
  await rpc("svc_authorize_auth_email", {
    p_actor: actor,
    p_member_id: memberId,
    p_email: plan.new_email
  });
  const { error } = await admin.auth.admin.updateUserById(memberId, {
    email: plan.new_email,
    email_confirm: true
  });
  if (error) {
    await rpc("svc_record_auth_action", {
      p_actor: actor,
      p_member_id: memberId,
      p_action: "auth.email_change",
      p_details: {
        request_id: requestId,
        error: error.message
      },
      p_result: "failure"
    });
    throw new HttpError(502, "auth_error", "Supabase Auth refused the new email; nothing was changed");
  }
  try {
    await rpc("svc_complete_contact_request", {
      p_actor: actor,
      p_request_id: requestId,
      p_expected_email: plan.old_email,
      p_note: note
    });
  } catch (e) {
    const { error } = await rpc("svc_authorize_auth_email", {
      p_actor: actor,
      p_member_id: memberId,
      p_email: plan.old_email
    }).then(()=>admin.auth.admin.updateUserById(memberId, {
        email: plan.old_email,
        email_confirm: true
      })).catch((err)=>({
        error: {
          message: String(err?.message ?? err)
        }
      }));
    await rpc("svc_record_auth_action", {
      p_actor: actor,
      p_member_id: memberId,
      p_action: "auth.email_revert",
      p_details: error ? {
        request_id: requestId,
        error: error.message
      } : {
        request_id: requestId
      },
      p_result: error ? "failure" : "success"
    }).catch(()=>{});
    if (error) {
      console.error("change-member-contact: Auth email revert failed", memberId, error.message);
      throw new HttpError(500, "out_of_sync", "Members update failed and the Auth email could not be reverted; check audit_log");
    }
    throw e;
  }
  return {
    request_id: requestId,
    member_id: memberId,
    email: plan.new_email
  };
});

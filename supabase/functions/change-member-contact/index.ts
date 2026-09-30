// change-member-contact (spec §11, §16)
// POST { "member_id": uuid, "email"?: string, "phone"?: string }   Caller: Super Admin.
//
// Changes a member's email and/or phone in Supabase Auth and in members, keeping them in sync:
//   1. svc_prepare_contact_change: validate + normalise (uniqueness in members and auth.users,
//      never an email tied to a Super Admin account, E.164 phone). No writes.
//   2. If the email changes: authorize exactly that address (the auth.users guard trigger refuses
//      any other email change), then update it in Auth (confirmed, no email round-trip).
//   3. svc_apply_contact_change: re-validate under lock, write members, audit old/new values.
//      If step 3 fails, step 2 is reverted so Auth and members never disagree.
// Login is email-only (Q7), so the phone lives in members only.
import { admin, HttpError, optionalString, readJson, requireSuperAdmin, rpc, serve, uuidField } from "../_shared/common.ts";
serve("change-member-contact", async (req)=>{
  const actor = await requireSuperAdmin(req);
  const body = await readJson(req);
  const memberId = uuidField(body, "member_id");
  const email = optionalString(body, "email", 254);
  const phone = optionalString(body, "phone", 40);
  const plan = await rpc("svc_prepare_contact_change", {
    p_actor: actor,
    p_member_id: memberId,
    p_email: email,
    p_phone: phone
  });
  if (plan.new_email) {
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
          error: error.message
        },
        p_result: "failure"
      });
      throw new HttpError(502, "auth_error", "Supabase Auth refused the new email; nothing was changed");
    }
  }
  try {
    await rpc("svc_apply_contact_change", {
      p_actor: actor,
      p_member_id: memberId,
      p_email: email,
      p_phone: phone,
      p_expected_email: plan.old_email
    });
  } catch (e) {
    if (plan.new_email) {
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
          error: error.message
        } : {},
        p_result: error ? "failure" : "success"
      }).catch(()=>{});
      if (error) {
        console.error("change-member-contact: Auth email revert failed", memberId, error.message);
        throw new HttpError(500, "out_of_sync", "Members update failed and the Auth email could not be reverted; check audit_log");
      }
    }
    throw e;
  }
  return {
    member_id: memberId,
    email_changed: plan.new_email !== null,
    phone_changed: plan.new_phone !== null,
    email: plan.new_email ?? plan.old_email,
    phone: plan.new_phone ?? plan.old_phone
  };
});

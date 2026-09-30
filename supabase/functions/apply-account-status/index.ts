// apply-account-status (spec §14, §16)
// POST { "member_id": uuid }   Caller: Super Admin.
//
// Syncs the Supabase Auth ban with members.account_status: banned unless the status is
// 'active', unbanned when it is. Call it after approving a blacklist or deletion request,
// and after any Super Admin status change or reinstatement. Idempotent.
//
// Banning blocks new sign-ins and token refreshes. An access token already issued stays
// valid until it expires; RLS denies every non-active account in the meantime (§14).
import { admin, HttpError, readJson, requireSuperAdmin, rpc, serve, uuidField } from "../_shared/common.ts";
const BAN_DURATION = "876000h"; // ~100 years; lifted explicitly with "none"
serve("apply-account-status", async (req)=>{
  const actor = await requireSuperAdmin(req);
  const memberId = uuidField(await readJson(req), "member_id");
  const target = await rpc("svc_account_status_for_auth", {
    p_actor: actor,
    p_member_id: memberId
  });
  const { error } = await admin.auth.admin.updateUserById(memberId, {
    ban_duration: target.ban ? BAN_DURATION : "none"
  });
  const action = target.ban ? "auth.ban" : "auth.unban";
  if (error) {
    await rpc("svc_record_auth_action", {
      p_actor: actor,
      p_member_id: memberId,
      p_action: action,
      p_details: {
        account_status: target.account_status,
        error: error.message
      },
      p_result: "failure"
    });
    throw new HttpError(502, "auth_error", "Supabase Auth refused the update; nothing was changed");
  }
  await rpc("svc_record_auth_action", {
    p_actor: actor,
    p_member_id: memberId,
    p_action: action,
    p_details: {
      account_status: target.account_status
    }
  });
  return {
    member_id: memberId,
    account_status: target.account_status,
    banned: target.ban
  };
});

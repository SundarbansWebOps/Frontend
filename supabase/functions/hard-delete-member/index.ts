// hard-delete-member (spec §10, §15, §16)
// POST { "request_id": uuid }   Caller: a Super Admin OTHER than the one who filed the request.
//
// Approves and executes a member_hard_delete request filed with request_hard_delete():
//   1. svc_execute_hard_delete (one DB transaction): checks the second-Super-Admin rule and the
//      30-day wait, anonymises the member (placeholders), clears form answers, redacts the
//      member's request snapshots, marks the request approved + executed, writes audit_log.
//   2. Deletes the Auth user (sessions and identities go with it).
// Anonymise first, then delete (the member id, blacklist hashes, requests and audit stay).
// If step 2 fails, calling again with the same request_id retries only the Auth deletion.
import { admin, HttpError, readJson, requireSuperAdmin, rpc, serve, uuidField } from "../_shared/common.ts";
serve("hard-delete-member", async (req)=>{
  const actor = await requireSuperAdmin(req);
  const requestId = uuidField(await readJson(req), "request_id");
  const result = await rpc("svc_execute_hard_delete", {
    p_actor: actor,
    p_request_id: requestId
  });
  const { error } = await admin.auth.admin.deleteUser(result.member_id);
  const alreadyGone = error && (error.status === 404 || /not found/i.test(error.message));
  if (error && !alreadyGone) {
    await rpc("svc_record_auth_action", {
      p_actor: actor,
      p_member_id: result.member_id,
      p_action: "auth.delete_user",
      p_details: {
        request_id: requestId,
        error: error.message
      },
      p_result: "failure"
    });
    throw new HttpError(502, "auth_error", "Member was anonymised, but deleting the Auth user failed; call again with the same request_id to retry");
  }
  if (!alreadyGone) {
    await rpc("svc_record_auth_action", {
      p_actor: actor,
      p_member_id: result.member_id,
      p_action: "auth.delete_user",
      p_details: {
        request_id: requestId
      }
    });
  }
  return {
    request_id: requestId,
    member_id: result.member_id,
    state: result.state,
    auth_user_deleted: true
  };
});

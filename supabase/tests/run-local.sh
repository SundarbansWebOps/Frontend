#!/usr/bin/env bash
# Fresh disposable database on 5452x; never reset the repo's dev stack or another project.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d /tmp/sundarbans-pgtap.XXXXXX)
test_project="sundarbans-pgtap-$$"
started=false
cleanup() {
  if "$started"; then
    supabase stop --workdir "$test_dir" --no-backup > "$test_dir/stop.log" 2>&1 || cat "$test_dir/stop.log"
  fi
  rm -rf "$test_dir"
}
trap cleanup EXIT
mkdir -p "$test_dir/supabase/migrations" "$test_dir/supabase/tests"
cp "$repo_root"/supabase/migrations/*.sql "$test_dir/supabase/migrations/"
cp "$repo_root"/supabase/tests/*.sql "$test_dir/supabase/tests/"
python3 - "$repo_root/supabase/config.toml" "$test_dir/supabase/config.toml" "$test_project" <<'PY'
import re
import sys
source, target, project = sys.argv[1:]
config = open(source).read()
config = re.sub(r'^project_id = .*$', f'project_id = "{project}"', config, flags=re.M)
config = re.sub(r'\b5442([0-9])\b', r'5452\1', config)
config = config.replace('inspector_port = 8183', 'inspector_port = 8193')
open(target, 'w').write(config)
PY
# Legacy history revokes this cloud-provided function before a later migration recreates
# it. Fresh Supabase CLI images omit it. A test-only bootstrap preserves historical files.
cat > "$test_dir/supabase/migrations/20260928000000_local_platform_bootstrap.sql" <<'SQL'
create function public.rls_auto_enable() returns event_trigger
language plpgsql security definer set search_path='' as $$ begin end; $$;
SQL
started=true
if ! supabase start --workdir "$test_dir" > "$test_dir/start.log" 2>&1; then
  tail -n 35 "$test_dir/start.log"
  exit 1
fi
supabase test db --workdir "$test_dir"
python3 "$repo_root/supabase/tests/concurrency.py" postgresql://postgres:postgres@127.0.0.1:54522/postgres

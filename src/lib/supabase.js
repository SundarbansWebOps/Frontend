// The one Supabase client for the site. The project URL and the publishable key are public by
// design (they ship to every browser); row-level security in the database decides what each
// signed-in member may read or change. Vercel or a local .env can point at another project.
import { createClient } from '@supabase/supabase-js';

export const SUPABASE_URL =
  import.meta.env.VITE_SUPABASE_URL || 'https://bqoejoznqudcyeaebmsm.supabase.co';
const PUBLISHABLE_KEY =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_61O0mgCXVAInGq2DhoInOQ_Z4nj8b4r';

// PKCE: Google sends the visitor back with ?code=… (before the #/route), which suits the hash
// router; the implicit flow would put tokens in the # and collide with it.
export const supabase = createClient(SUPABASE_URL, PUBLISHABLE_KEY, {
  auth: {
    flowType: 'pkce',
    detectSessionInUrl: true,
    persistSession: true,
    autoRefreshToken: true,
  },
});

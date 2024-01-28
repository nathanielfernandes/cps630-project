import { redirect } from '@sveltejs/kit'
import type { SupabaseClient } from '@supabase/supabase-js'

export const GET: (input: { url: URL, locals: { supabase: SupabaseClient} }) => Promise<{ status: number, headers: { location: string } }>
= async ({ url, locals: { supabase } }) => {
  const code = url.searchParams.get('code')

  if (code) {
    await supabase.auth.exchangeCodeForSession(code)
  }

  throw redirect(303, '/')
}
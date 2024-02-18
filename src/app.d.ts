// src/app.d.ts
import { SupabaseClient, Session } from '@supabase/supabase-js'
import { Database } from '$lib/databasedefs'

declare global {
  namespace App {
    interface Locals {
      supabase: SupabaseClient<Database>
      getSession(): Promise<Session | null>
    }
    interface PageData {
      session: Session | null
    }
    // interface Error {}
    // interface Platform {}
  }
  declare namespace svelteHTML {
    interface HTMLAttributes<T> {
      'on:click_outside'?: CompositionEventHandler<T>;
    }
  }
}

export {}
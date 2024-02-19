// src/hooks.server.ts
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { createSupabaseServerClient } from '@supabase/auth-helpers-sveltekit';
import { redirect, type Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { isProtectedPage } from '$lib/protectedPages';

const supabase: Handle = async ({ event, resolve }) => {
	event.locals.supabase = createSupabaseServerClient({
		supabaseUrl: PUBLIC_SUPABASE_URL,
		supabaseKey: PUBLIC_SUPABASE_ANON_KEY,
		event
	});

	/**
	 * a little helper that is written for convenience so that instead
	 * of calling `const { data: { session } } = await supabase.auth.getSession()`
	 * you just call this `await getSession()`
	 */
	event.locals.getSession = async () => {
		const {
			data: { session }
		} = await event.locals.supabase.auth.getSession();
		return session;
	};

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			return name === 'content-range';
		}
	});
};

const authorization: Handle = async ({ event, resolve }) => {
	// If the route is protected and user is not logged in, redirect to homepage and show login modal
	if (isProtectedPage(event.url.pathname) && event.request.method === 'GET') {
		const session = await event.locals.getSession();
		if (!session) {
			throw redirect(303, '/?askLogin=true');
		}
	}

	return resolve(event);
};

export const handle: Handle = sequence(supabase, authorization);

import { TOKEN } from '$env/static/private';


export async function GET({ request, params, locals }) {
  const token = request.headers.get('Token');

  if (token !== TOKEN) {
    return new Response('Unauthorized', { status: 401 });
  }

  const user_id = params.user_id; 
  const secret = request.headers.get('Secret');
  if (secret === null) {
    return new Response('Unauthorized', { status: 401 });
  }

  // run SELECT secret FROM users WHERE id = $1 
  // select secret from users where id = user_id
  const result = await locals.supabase.from('users').select('secret').eq('id', user_id).single();

  if (result.error || result.data.secret !== secret) {
    return new Response('Unauthorized', { status: 401 });
  }

  return new Response('Verified User', { status: 202 });
}
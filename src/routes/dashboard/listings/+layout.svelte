<script lang="ts">
	import { posts, type Post } from './stores';

    export let data;

    let { supabase, session } = data;
    $: ({ supabase } = data);

    const fetchPosts = async () => {
        const { data } = await supabase
        .from('posts')
        .select(`
            id,
            title,
            content,
            price,
            created_at,
            type,
            location,
            images:images!post_id (link, alt_text),
            user_id,
            email
        `)
        const fetched = data || [];

        posts.update((p) => {
            for (const post of fetched) {
                // @ts-ignore
                p[post.id.toString()] = post;
            }
            return p;
        });
    };

</script>

{#await fetchPosts()}

    <div class="fixed top-1/2 left-1/2">
        <i class="fa-solid fa-spinner text-slate-900 animate-spin text-3xl"></i>
    </div>
    
{:then}
    <slot />
{:catch error}
    <p>{error.message}</p>
{/await}


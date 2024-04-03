<script lang="ts">
	import { posts, type Post } from './stores';

	export let data;

	let { supabase, session } = data;
	$: ({ supabase } = data);

	const fetchPosts = async () => {
		const { data, error } = await supabase.from('posts').select(`
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
        `);

        if (error) {
            console.log(error);
            throw error;
        }

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
	<div class="fixed left-1/2 top-1/2">
		<i class="fa-solid fa-spinner animate-spin text-3xl text-slate-900"></i>
	</div>
{:then}
	<slot />
{:catch error}
	<div class="flex flex-1 items-center justify-center">
		<div class="flex flex-col items-center justify-center gap-2 rounded-md bg-white p-20 shadow-lg">
			<div
				class="flex h-5 w-5 items-center justify-center rounded-full border-2 border-solid border-red-500 p-5"
			>
				<i class="fa-solid fa-x fa-lg text-red-500"></i>
			</div>
			<p class="text-2xl text-red-500">Failed to load posts!</p>
		</div>
	</div>
{/await}

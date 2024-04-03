<script lang="ts">
	import { successAlert, errorAlert } from '$lib/Alerts/stores';
	import Card from '$lib/components/Card.svelte';
	import type { SupabaseClient } from '@supabase/supabase-js';
	import { posts } from '../../routes/dashboard/listings/stores';

	export let supabase: SupabaseClient;
	export let session;
	export let post_type: 'items_for_sale' | 'items_wanted' | 'academic_services';

	let user_id = session ? session.user.id : '';
	$: filtered_posts = Object.values($posts).filter((post) => post.type === post_type);

    const IMAGE_URL_PREFIX =
		'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/';
	const handleDelete = async (event: CustomEvent<{id: number, title: string}>) => {
        let response = await supabase.from('images').delete().eq('post_id', event.detail.id).select();
        if (response.error) {
            console.error(response.error);
            errorAlert("Failed to delete post.");
            return;
        }
        const imagePaths = response.data.map((d) => decodeURIComponent(d.link.replace(IMAGE_URL_PREFIX, "")));
        supabase.storage.from("images").remove(imagePaths);

		response = await supabase.from('posts').delete().eq('id', event.detail.id).select();
        if (response.error) {
            console.error(response.error);
            errorAlert("Failed to delete post.");
            return;
        }

        successAlert("Successfully deleted post: " + event.detail.title);
        delete $posts[event.detail.id];
        $posts = $posts;
	};
</script>

<div
	class="xs:grid-cols-1 mx-auto mb-10 mt-10 grid w-full max-w-screen-xl gap-10 px-7 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
>
	{#each filtered_posts as ad}
		<Card
			id={ad.id}
			title={ad.title}
			description={ad.content}
			date={ad.created_at}
			price={ad.price}
			images={ad.images}
			user={ad.user_id}
			email={ad.email}
			showContactButton={ad.user_id !== user_id}
			showActions={ad.user_id === user_id}
			on:deleteButtonClick={handleDelete}
		/>
	{/each}
</div>

<script lang="ts">
    import Card from '$lib/components/Card.svelte';
	import { posts } from '../../routes/dashboard/listings/stores';

    export let session;
    export let post_type: 'items_for_sale' | 'items_wanted' | 'academic_services';

    let user_id = session ? session.user.id : '';
    const filtered_posts = Object.values($posts).filter((post) => post.type === post_type);

</script>

<div
    class="px-7 xs:grid-cols-1 mx-auto mb-10 mt-10 grid w-full max-w-screen-xl gap-10 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
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
		/>
	{/each}
</div>
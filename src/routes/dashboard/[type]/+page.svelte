<script lang="ts">
    import Card from '$lib/components/Card.svelte';
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { writable } from 'svelte/store';

    export let data;
    let type = $page.params.type;
    let { supabase } = data;
    $: ({ supabase } = data);

    const posts = writable<any[]>([]);

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
            images:images!post_id (link, alt_text),
            user_id
        `)
        .eq('type', type)
        console.log(data);
        posts.set(data || []);
    };

    onMount(() => {
        fetchPosts();
        console.log(type)
    });
</script>

<div
	class="xs:grid-cols-1 mx-auto mb-10 mt-10 grid w-full max-w-screen-xl gap-10 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
>
	{#each $posts as ad}
		<Card
			title={ad.title}
			description={ad.content}
			date={ad.created_at}
			price={ad.price}
			profile_image={"/user.png"}
			images={ad.images}
			user={ad.user_id}
		/>
	{/each}
</div>
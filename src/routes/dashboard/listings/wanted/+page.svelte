<script lang="ts">
	import Listings from "$lib/Pages/Listings.svelte";

	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);
</script>

<Listings {supabase} {session} post_type="items_wanted" />
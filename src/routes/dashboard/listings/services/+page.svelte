<script lang="ts">
	import Listings from "../Listings.svelte";

	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);
</script>

<Listings {supabase} {session} post_type="academic_services" />
<script lang="ts">
	import Listings from "$lib/Pages/Listings.svelte";

    export let data;

    let { session } = data;

</script>

<Listings {session} post_type="items_wanted" />
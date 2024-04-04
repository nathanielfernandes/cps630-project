<script lang="ts">
	import { posts, user_info } from '$lib/stores';
	import Metric from '$lib/components/Metric.svelte';
	import Table from '$lib/components/Table.svelte';

	let viewing: 'all' | 'users' | 'sale' | 'wanted' | 'academic' = 'all';

	$: all_listings = Object.values($posts);
	$: post_cols = all_listings.length > 0 ? Object.keys(all_listings[0]) : [];

	$: users = Object.values($user_info);
	$: user_cols = users.length > 0 ? Object.keys(users[0]) : [];

	$: sale_listings = all_listings.filter((listing) => listing.type === 'items_for_sale');
	$: wanted_listings = all_listings.filter((listing) => listing.type === 'items_wanted');
	$: academic_services = all_listings.filter((listing) => listing.type === 'academic_services');
</script>

<main>
	<div class="max-w-screen-xl mx-auto px-4">
		<h1 class="text-left text-3xl font-bold text-gray-800 my-5">Admin Dashboard</h1>
		<div class="flex space-x-2 items-center w-full h-full mb-2">
			<button class="w-full h-full" on:click={() => viewing = 'all'}>
				<Metric
					title={'All Listings'}
					value={all_listings.length}
				/>
			</button>
			<button class="w-full h-full" on:click={() => viewing = 'users'}>
				<Metric
					title={'Users'}
					value={users.length}
				/>
			</button>
			<button class="w-full h-full" on:click={() => viewing = 'sale'}>
				<Metric
					title={'Active Listings'}
					value={sale_listings.length}
				/>
			</button>
			<button class="w-full h-full" on:click={() => viewing = 'wanted'}>
				<Metric
					title={'Wanted Listings'}
					value={wanted_listings.length}
				/>
			</button>
			<button class="w-full h-full" on:click={() => viewing = 'academic'}>
				<Metric
					title={'Academic Services'}
					value={academic_services.length}
				/>
			</button>
		</div>

		<div class="">
			{#if viewing === 'all'}
				<Table caption="All Listings" cols={post_cols} data={all_listings} />
			{:else if viewing === 'users'}
				<Table caption="Users" data_type="users" cols={user_cols} data={users} />
			{:else if viewing === 'sale'}
				<Table caption="Active Listings" cols={post_cols} data={sale_listings} />
			{:else if viewing === 'wanted'}
				<Table caption="Wanted Listings" cols={post_cols} data={wanted_listings} />
			{:else if viewing === 'academic'}
				<Table caption="Academic Services" cols={post_cols} data={academic_services} />
			{/if}
		</div>

	</div>
</main>

<style>
	.cursor-pointer {
		cursor: pointer;
	}
</style>

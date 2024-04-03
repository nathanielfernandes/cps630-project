<script lang="ts">
	import Metric from '$lib/components/Metric.svelte';
	import Table from '$lib/components/Table.svelte';
	export let data: any;

	let table = 'posts';
	let type = '';

	function updateTableAndType(newTable: string, newType: string) {
		table = newTable;
		type = newType;
		console.log(table, type);
	}
</script>

<main>
	<div class="container mx-auto px-4">
		<h1 class="text-left text-3xl font-bold text-gray-800">Dashboard</h1>
		<div class="grid grid-cols-4 gap-4">
			<button on:click={() => updateTableAndType('user_info', '')} class="cursor-pointer">
				<Metric
					{data}
					type={'user_info'}
					title={'Users'}
					label={'Total Amount Of Users'}
					icon={'https://hazafa.b-cdn.net/users-solid.svg'}
				/>
			</button>
			<button on:click={() => updateTableAndType('posts', 'items_for_sale')} class="cursor-pointer">
				<Metric
					{data}
					type={'items_for_sale'}
					title={'Active Listings'}
					label={'Total Amount of Active Listings'}
					icon={'https://hazafa.b-cdn.net/fire-solid.svg'}
				/>
			</button>
			<button on:click={() => updateTableAndType('posts', 'items_wanted')} class="cursor-pointer">
				<Metric
					{data}
					type={'items_wanted'}
					title={'Wanted Listings'}
					label={'Total Amount Of Wanted Listings'}
					icon={'https://hazafa.b-cdn.net/hand-regular.svg'}
				/>
			</button>
			<button
				on:click={() => updateTableAndType('posts', 'academic_services')}
				class="cursor-pointer"
			>
				<Metric
					{data}
					type={'academic_services'}
					title={'Academic Services'}
					label={'Total Amount Of Academic Services'}
					icon={'https://hazafa.b-cdn.net/users-solid.svg'}
				/>
			</button>
			<div class="col-span-full">
				<Table {data} bind:table bind:type />
			</div>
		</div>
	</div>
</main>

<style>
	.cursor-pointer {
		cursor: pointer;
	}
</style>

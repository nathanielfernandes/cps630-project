<script lang="ts">
	import { fade } from "svelte/transition";

	export let caption = '';
	export let data_type = 'listings';
	export let cols: string[] = [];
	export let data: any[] = [];
</script>

<div class="relative overflow-x-auto shadow-md sm:rounded-lg">
	<table class="w-full text-left text-sm text-gray-500 rtl:text-right">
		<caption class="bg-white p-5 text-left text-lg font-semibold text-gray-900 rtl:text-right">
			{caption}
			<p class="mt-1 text-sm font-normal text-gray-500">
				{data.length}
				{data_type}
			</p>
		</caption>
		<thead class="bg-gray-50 text-xs uppercase text-gray-700">
			<tr>
				{#each cols as col}
					<th scope="col" class="px-6 py-3">{col}</th>
				{/each}
				<th scope="col" class="px-6 py-4">Edit</th>
			</tr>
		</thead>
		<tbody>
			{#each data as item}
				<tr class="border-b bg-white" in:fade|global>
					{#each cols as key}
						<td class="px-6 py-4 {key === 'id' ? '' : 'max-w-10 truncate'}">
							{key === "images" ? item[key].length : item[key]}
						</td>
					{/each}
					<td class="px-6 py-4 text-left">
						<a href="#" class="font-medium text-blue-600 hover:underline">Edit</a>
					</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>

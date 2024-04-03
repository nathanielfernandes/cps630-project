<script lang="ts">
	export let table;
	export let type;
	export let data: any;
	let { supabase } = data;
	let fetched: any[] = [];
	let cols: string[] = [];

	const fetchFromDatabase = async (tableName: string, type?: string) => {
		let query;
		if (tableName !== 'posts') {
			query = supabase.from(tableName).select('*');
		} else {
			query = supabase.from(tableName).select(`
            id, title, content, price, created_at, type, location,
            images:images!post_id (link, alt_text), user_id, email
        `);
		}

		if (type) {
			query = query.eq('type', type);
		}

		const { data, error } = await query;

		if (error) {
			console.error(`Error fetching ${type || 'data'}:`, error);
			return;
		}

		fetched = data || [];
		console.log(fetched);
		cols = fetched.length > 0 ? Object.keys(fetched[0]) : [];
	};

	if (type === '') {
		fetchFromDatabase(table);
	} else {
		fetchFromDatabase(table, type);
	}

	function truncate(text: string, length: number): string {
		return text.length > length ? `${text.substring(0, length)}...` : text;
	}
</script>

<div class="relative overflow-x-auto shadow-md sm:rounded-lg">
	<table class="w-full text-left text-sm text-gray-500 rtl:text-right">
		<caption class="bg-white p-5 text-left text-lg font-semibold text-gray-900 rtl:text-right">
			Listings
			<p class="mt-1 text-sm font-normal text-gray-500">
				These are the listings available on the platform in a neat format.
			</p>
		</caption>
		<thead class="bg-gray-50 text-xs uppercase text-gray-700">
			<tr>
				{#each cols as col}
					<th scope="col" class="px-6 py-3">{col}</th>
				{/each}
				<th scope="col" class="px-6 py-3">Edit</th>
			</tr>
		</thead>
		<tbody>
			{#each fetched as post}
				<tr class="border-b bg-white">
					{#each cols as col}
						<td class="px-6 py-4">{truncate(post[col], 50)}</td>
					{/each}
					<td class="px-6 py-4 text-right">
						<a href="#" class="font-medium text-blue-600 hover:underline">Edit</a>
					</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>

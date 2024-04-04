<script lang="ts">
	export let label: string;
	export let icon: string;
	export let title: string;
	export let type: string;
	export let data: any;
	let value: number;
	let { supabase } = data;

	$: textColor = 'text-green-500';
	$: iconPosition = 'flex justify-end';

	const fetchCount = async () => {
		let tableName = 'posts';
		let conditions = type !== 'user_info' ? { type: type } : {};

		// For the 'user_info' case, adjust the tableName and reset conditions
		if (type === 'user_info' || type === 'total_listings') {
			tableName = type === 'user_info' ? 'user_info' : 'posts';
			conditions = {};
		}

		let query = supabase.from(tableName).select('*', { count: 'exact' }).match(conditions);

		const { data, error, count } = await query;

		if (error) {
			console.error(`Error fetching ${type} count:`, error);
			return;
		}

		value = tableName === 'user_info' ? data.length : count;
	};

	fetchCount();
</script>

<div>
	<div class="block min-w-60 max-w-sm rounded-lg border border-gray-200 bg-white p-6 shadow-md">
		<div class="mb-4 flex items-center justify-between">
			<h5 class="text-2xl font-bold tracking-tight text-black">
				{title}
			</h5>
			<div class={iconPosition}>
				<img src={icon} alt="icon" class="h-10 w-10" />
			</div>
		</div>
		<p class="text-4xl font-semibold text-black">
			{value}
		</p>
		<div class="flex items-center justify-between">
			<p class={`text-base font-normal ${textColor}`}>
				{label}
			</p>
		</div>
	</div>
</div>

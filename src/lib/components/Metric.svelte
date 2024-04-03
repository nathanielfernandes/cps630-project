<script lang="ts">
	let value: number;
	export let label: string;
	export let icon: string;
	export let title: string;
	export let type: string;
	export let data: any;
	let { supabase } = data;

	$: textColor = 'text-green-500';
	$: iconPosition = 'flex justify-end';

	const fetchCount = async (type: string) => {
		let query = supabase.from('posts').select('id', { count: 'exact' });
		if (type !== 'user_info') {
			query = query.eq('type', type);
		} else {
			query = supabase.from('user_info').select('*', { count: 'exact' });
		}

		const { data, error, count } = await query;

		if (error) {
			console.error(`Error fetching ${type} count:`, error);
			return;
		}

		return type === 'user_info' ? data.length : count;
	};
	fetchCount(type).then((count) => {
		value = count;
	});
</script>

<div>
	<div class="block min-w-80 max-w-sm rounded-lg border border-gray-200 bg-white p-6 shadow-md">
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

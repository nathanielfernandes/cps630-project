<script lang="ts">
	export let title: string;
	export let value: number = 0;
</script>


<div class="relative rounded-lg border border-gray-200 bg-white px-4 py-3 shadow-md w-full ">
	<h5 class="font-semibold tracking-tight text-slate-700 ">
		{title}
	</h5>
	<p class="text-4xl font-bold text-black my-2">
		{value}
	</p>

	<div class="bg-green-500 w-4 h-4 rounded-full animate-pulse absolute -top-1 -right-1">
	</div>
</div>
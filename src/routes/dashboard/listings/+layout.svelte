<script lang="ts">
	import { waiting } from '$lib/stores';
</script>

{#if $waiting}
	<div class="fixed left-1/2 top-1/2">
		<i class="fa-solid fa-spinner animate-spin text-3xl text-slate-900"></i>
	</div>
{:else}
	<slot />
<!-- {:catch error}
	<div class="flex flex-1 items-center justify-center">
		<div class="flex flex-col items-center justify-center gap-2 rounded-md bg-white p-20 shadow-lg">
			<div
				class="flex h-5 w-5 items-center justify-center rounded-full border-2 border-solid border-red-500 p-5"
			>
				<i class="fa-solid fa-x fa-lg text-red-500"></i>
			</div>
			<p class="text-2xl text-red-500">Failed to load posts!</p>
		</div>
	</div> -->
{/if}

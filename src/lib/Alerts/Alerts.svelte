<script>
	import { fade } from 'svelte/transition';
	import { __alerts } from './stores';

	const COLORS = {
		green: 'bg-green-400 text-green-900',
		red: 'bg-red-400 text-red-900',
		blue: 'bg-blue-400 text-blue-900',
		yellow: 'bg-amber-200 text-amber-800',
		dark: 'bg-gray-400 text-gray-900'
	};
</script>

<span class="fixed right-2 top-40 z-20">
	{#each $__alerts as { title, message, color, id, close } (id)}
		{@const tw = COLORS[color]}
		<div class="flex items-center p-4 mb-4 text-sm rounded-lg {tw}" role="alert" transition:fade>
			<svg
				class="flex-shrink-0 inline w-4 h-4 me-3"
				aria-hidden="true"
				xmlns="http://www.w3.org/2000/svg"
				fill="currentColor"
				viewBox="0 0 20 20"
			>
				<path
					d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z"
				/>
			</svg>
			<span class="sr-only">{title}</span>
			<div>
				<span class="font-medium">{title}</span>
				{message}
			</div>

			<button
				type="button"
				class=" ml-2 focus:outline-none whitespace-normal rounded-lg focus:ring-2 p-1.5 -mx-1.5 -my-1.5"
				aria-label="Close"
				on:click={close}
				><span class="sr-only">Close</span>
				<svg
					class="w-5 h-5"
					fill="currentColor"
					viewBox="0 0 20 20"
					xmlns="http://www.w3.org/2000/svg"
					><path
						fill-rule="evenodd"
						d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
						clip-rule="evenodd"
					/></svg
				></button
			>
		</div>
	{/each}
</span>

<script lang="ts">
	import { onMount } from 'svelte';

	export let show = false;
	export let persist = false;
	export let cancelable = true;

	let clazz = '';
	export { clazz as class };

	let mounted = false;
	onMount(() => (mounted = true));

	let dialog: HTMLDialogElement;

	$: mounted && show && dialog.showModal();

	const close = () => dialog.close();
</script>

<!-- svelte-ignore a11y-click-events-have-key-events a11y-no-noninteractive-element-interactions -->
<dialog
	bind:this={dialog}
	on:close={() => (show = false)}
	on:click|self={persist ? undefined : close}
	class="bg-white-800 relative rounded-lg p-4 {clazz} "
>
	<!-- svelte-ignore a11y-no-static-element-interactions -->
	<div on:click|stopPropagation>
		<button
			aria-label="Close modal"
			disabled={!cancelable}
			class:hidden={!cancelable}
			type="button"
			on:click={close}
			class="absolute right-1 top-1 ms-auto inline-flex h-8 w-8 items-center justify-center rounded-lg bg-transparent text-sm text-gray-400 hover:text-white"
		>
			<svg
				class="h-3 w-3"
				aria-hidden="true"
				xmlns="http://www.w3.org/2000/svg"
				fill="none"
				viewBox="0 0 14 14"
			>
				<path
					stroke="currentColor"
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"
				/>
			</svg>
			<span class="sr-only">Close modal</span>
		</button>

		<slot {close} />
	</div>
</dialog>

<style>
	dialog::backdrop {
		background-color: rgba(0, 0, 0, 0.3);
	}

	dialog[open] {
		animation: zoom 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
	}
	@keyframes zoom {
		from {
			transform: scale(0.95);
		}
		to {
			transform: scale(1);
		}
	}

	dialog[open]::backdrop {
		animation: fade 0.2s ease-out;
	}
	@keyframes fade {
		from {
			opacity: 0;
		}
		to {
			opacity: 1;
		}
	}
</style>

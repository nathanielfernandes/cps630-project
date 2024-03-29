<script lang="ts">
	import {
		successAlert,
		errorAlert,
		infoAlert,
		warningAlert,
		darkAlert
	} from '$lib/Alerts/stores.js';
	import Modal from '$lib/Modal/Modal.svelte';
	import Chat from '$lib/chatter/Chat.svelte';

	export let data;

	// console.log('data', data);
	$: if (data.session) {
		console.log('logged in as:', data.session.user.email);
		// console.log('session', data.session);
	}

	let show_modal = false;
	let text = '';
</script>

<h1>testing</h1>

<hr class="my-8" />
<button
	class="bg-green-500 text-white px-4 py-2 rounded-lg"
	on:click={() => successAlert('Hello', 'This is a success alert')}
>
	Success
</button>

<button
	class="bg-red-500 text-white px-4 py-2 rounded-lg"
	on:click={() => errorAlert('Hello', 'This is an error alert')}
>
	Error
</button>

<button
	class="bg-blue-500 text-white px-4 py-2 rounded-lg"
	on:click={() => infoAlert('Hello', 'This is an info alert')}
>
	Info
</button>

<button
	class="bg-yellow-500 text-white px-4 py-2 rounded-lg"
	on:click={() => warningAlert('Hello', 'This is a warning alert')}
>
	Warning
</button>

<button
	class="bg-gray-500 text-white px-4 py-2 rounded-lg"
	on:click={() => darkAlert('Hello', 'This is a dark alert')}
>
	Dark
</button>

<button class="bg-gray-500 text-white px-4 py-2 rounded-lg" on:click={() => (show_modal = true)}
	>Show modal</button
>

<Modal bind:show={show_modal} class="w-96" let:close>
	<h1 class="text-white text-2xl font-bold">Example Modal</h1>

	<p class="text-white">This is a modal</p>

	<input type="text" bind:value={text} class="w-full rounded-lg p-2" />
	<p class="text-white">This is some input: {text}</p>

	<button class="bg-red-500 text-white px-4 py-2 rounded-lg" on:click={close}> Finish </button>
</Modal>


<Chat />
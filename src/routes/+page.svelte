<script lang="ts">
	import {
		successAlert,
		errorAlert,
		infoAlert,
		warningAlert,
		darkAlert
	} from '$lib/Alerts/stores.js';

	export let data;

	console.log('data', data);
	$: if (data.session) {
		console.log('session', data.session);
	}
</script>

<h1>testing</h1>
<a href="/login">login</a>

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

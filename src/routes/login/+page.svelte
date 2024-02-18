<script lang="ts">
	import { enhance } from '$app/forms';
	export let form;
	import Modal from '$lib/Modal/Modal.svelte'
	let show_modal = false;
	let text = ''

</script>

<form method="post" use:enhance>
	<input name="email" value={form?.email ?? ''} />
	<input type="password" name="password" />
	<button>Sign up</button>
</form>

<button class="bg-gray-500 text-white px-4 py-2 rounded-lg" on:click={() => (show_modal = true)}
	>Show modal</button
>
<Modal bind:show={show_modal} class="w-96  p-8 space-y-4" let:close>
	<div class="space-y-4">
		<div class="space-y-1">
			<h1 class="text-white text-2xl font-bold">Welcome Back</h1>
			<p class="text-slate-200 text-sm  ">Login to access the TMU Marketplace</p>
		</div>
		<div class="space-y-1">
			<p class="text-slate-200 text-sm">Email Address</p>
			<input placeholder="hello@yourcompany.com" type="text" bind:value={text} class="w-full rounded-lg p-2 bg-slate-600" />
		</div>
		<div class="space-y-1">
			<p class="text-slate-200 text-sm">Password</p>
			<input placeholder="Hello World" type="text" bind:value={text} class="w-full rounded-lg p-2 bg-slate-600" />
		</div>
		<div class="space-y-2">
			<button class="w-full bg-blue-700 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded" >Login</button>
			<p class="text-slate-300 text-sm ">Don't have an account? Sign Up</p>
		</div>
	</div>
</Modal>

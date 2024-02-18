<script lang="ts">
	import Modal from '$lib/Modal/Modal.svelte';
	import type { SupabaseClient } from '@supabase/supabase-js';

	export let supabase: SupabaseClient;
	export let signup = false;
	export let show = false;

	let email: string;
	let password: string;

	const handleSignUp = async () => {
		await supabase.auth.signUp({
			email,
			password,
			options: {
				emailRedirectTo: `${location.origin}/auth/callback`
			}
		});
	};

	const handleSignIn = async () => {
		await supabase.auth.signInWithPassword({
			email,
			password
		});
	};

	const handleSubmit = async () => {
		if (signup) {
			await handleSignUp();
		} else {
			await handleSignIn();
		}
	};

	$: si = signup ? 'Sign Up' : 'Login';
</script>

<Modal bind:show class="w-96 p-8 space-y-4 text-white" let:close>
	{@const submit = () => {
		handleSubmit();
		close();
	}}
	<form class="space-y-4" on:submit={submit}>
		<div class="space-y-1">
			<h1 class="text-white text-xl font-bold">
				Welcome
				{#if signup}
					to the TMU Marketplace
				{:else}
					Back
				{/if}
			</h1>
			<p class="text-slate-200 text-sm">
				{si} to access the TMU Marketplace
			</p>
		</div>
		<div class="space-y-1">
			<p class="text-slate-200 text-sm">Email Address</p>
			<input
				placeholder="hello@yourcompany.com"
				type="text"
				bind:value={email}
				class="w-full rounded-lg p-2 bg-slate-600"
			/>
		</div>
		<div class="space-y-1">
			<p class="text-slate-200 text-sm">Password</p>
			<input
				placeholder="password..."
				type="password"
				bind:value={password}
				class="w-full rounded-lg p-2 bg-slate-600"
			/>
		</div>
		<div class="space-y-2">
			<button
				class="w-full bg-blue-700 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded"
				on:click={submit}
			>
				{si}
			</button>
			<p class="text-slate-300 text-sm">
				{#if signup}
					Already have an account?
				{:else}
					Don't have an account?
				{/if}
				<button class="text-blue-500 hover:underline" on:click={() => (signup = !signup)}>
					{signup ? 'Login' : 'Sign Up'}
				</button>
			</p>
		</div>
	</form>
</Modal>

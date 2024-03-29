<script lang="ts">
	import Modal from '$lib/Modal/Modal.svelte';
	import type { SupabaseClient } from '@supabase/supabase-js';

	export let supabase: SupabaseClient;
	export let signup = false;
	export let show = false;

	let status = '';
	let email: string;
	let password: string;
	let resetPW = false;

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

	const resetPassword = async () => {
		await supabase.auth.resetPasswordForEmail(email);
	};

	const clearInputs = () => {
		email = '';
		password = '';
		status = '';
	};


	const handleSubmit = async (): Promise<void> => {
		try {
			if (signup) {
				await handleSignUp(); 
				console.log(email, password);
			} else {
				await handleSignIn(); 
				console.log(email, password);
			}
		console.log("Operation was successful");
		clearInputs();

		} catch (error) {
			const errorMessage: string = (error instanceof Error) ? error.message : "An unknown error occurred";
			console.error("An error occurred during the operation:", errorMessage);
			status = "An error occurred. Please try again.";
			console.log(status);
		}
	};

	$: si = signup ? 'Sign Up' : 'Login';
</script>

<Modal bind:show class="w-96 p-8 space-y-4 text-white" let:close>
	{@const submit = () => {
		handleSubmit();
		//close();

	}}
	<form class="space-y-4" on:submit={submit}>
		{#if !resetPW}
			<div class="space-y-1">
				<h1 class="text-white text-xl font-bold">
					Welcome
					{#if signup}
						to the TMU Marketplace
					{:else}
						Back 
					{/if}
				</h1>
				<p class="text-slate-200 text-sm ">
					{si} to access the TMU Marketplace
				</p>
				{#if status !== ''}
				<p class="text-red-500 text-sm">{status}</p>
			{/if}
			</div>
			<div class="space-y-1">
				<p class="text-slate-200 text-sm">Email Address</p>
				<input
					placeholder="hello@yourcompany.com"
					type="email"
					bind:value={email}
					class="w-full rounded-lg p-2 bg-slate-600"
					required

				/>
			</div>
			<div class="space-y-1">

				<p class="text-slate-200 text-sm">Password</p>
				<input
					placeholder="password..."
					type="password"
					bind:value={password}
					class="w-full rounded-lg p-2 bg-slate-600"
					required
				/>
				{#if !signup}			
				<p class="text-slate-200 text-sm">
					<button
						class="text-sm text-blue-700 hover:underline dark:text-blue-500"
						on:click={() => (resetPW = true)}
					>
						Forgot your password?
				</button>
				</p>
			{/if}
			</div>
			<div class="space-y-2">
				<button
					type="submit"
					class="w-full bg-blue-700 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded"
				>
					{si}
				</button>
				<p class="text-slate-300 text-sm select-none">
					{#if signup}
						Already have an account?
					{:else}
						Don't have an account?
					{/if}
					<button
						class="text-blue-500 hover:underline"
						on:click|preventDefault={() => (signup = !signup)}
					>
						{signup ? 'Login' : 'Sign Up'}
					</button>
				</p>
			</div>
		{:else}
			<div class="space-y-1">
				<h1 class="text-white text-xl font-bold">
					Reset Password
				</h1>
				<p class="text-slate-200 text-sm ">
					Enter your email address to reset your password
				</p>
	
			</div>
			<p class="text-slate-200 text-sm">Email Address</p>
			<input
				placeholder="hello@yourcompany.com"
				type="email"
				bind:value={email}
				class="w-full rounded-lg p-2 bg-slate-600"
				required

			/>
			<button
			class="w-full bg-blue-700 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded"
			on:click={() => resetPassword()}
		>
			Reset Password
		</button>
			
		{/if}
	</form>
</Modal>

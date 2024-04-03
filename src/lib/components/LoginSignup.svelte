<script lang="ts">
	import Modal from '$lib/Modal/Modal.svelte'; // modal component
	import type { SupabaseClient } from '@supabase/supabase-js'; // supabase client
	import {
		// alert stores
		successAlert,
		errorAlert
	} from '$lib/Alerts/stores.js';

	export let supabase: SupabaseClient;
	export let signup = false; // Whether the user is signing up or logging in
	export let show = false; // Whether the modal is shown

	let email: string;
	let password = '';
	let resetPW = false;
	// Password validation
	$: hasMinLength = password.length >= 7;
	$: hasLowercase = /[a-z]/.test(password);
	$: hasUppercase = /[A-Z]/.test(password);
	$: hasNumber = /\d/.test(password);
	$: hasSymbol = /\W|_/.test(password);
	// Overall password validity
	$: isValidPassword = hasMinLength && hasLowercase && hasUppercase && hasNumber && hasSymbol;

	// Handle the authentication operation
	const handleAuthOperation = async (operationPromise: Promise<any>, successMessage: string) => {
		const { error } = await operationPromise;
		if (error) {
			errorAlert(error);
			return false;
		} else {
			successAlert('Success', successMessage);
			return true;
		}
	};
	// Sign up the user
	const handleSignUp = () => {
		if (!isValidPassword) {
			errorAlert('Password requirements not met');
			return false;
		} else {
			return handleAuthOperation(
				supabase.auth.signUp({
					email,
					password,
					options: { emailRedirectTo: `${location.origin}/auth/callback` }
				}),
				'Please check your email to verify your account'
			);
		}
	};

	// Sign in the user
	const handleSignIn = () => {
		return handleAuthOperation(
			supabase.auth.signInWithPassword({ email, password }),
			'You have successfully logged in'
		);
	};

	// Reset the user's password
	const handleResetPassword = () => {
		return handleAuthOperation(
			supabase.auth.resetPasswordForEmail(email),
			'Please check your email to reset your password'
		);
	};

	// Clear the input fields
	const clearInputs = () => {
		email = '';
		password = '';
	};

	// Handle the form submission
	const handleSubmit = async (event: Event, close: { (): void }): Promise<void> => {
		event.preventDefault();
		let res: boolean;
		if (resetPW) {
			res = await handleResetPassword();
		} else {
			const handler = signup ? handleSignUp : handleSignIn;
			res = await handler();
		}

		if (res) {
			if (!signup && !resetPW) {
				close();
			} else if (resetPW) {
				resetPW = false;
			}
			clearInputs();
		}
	};
	// Set the sign up or login text
	$: si = signup ? 'Sign Up' : 'Login';
</script>

<!-- Login/Signup Modal -->
<Modal bind:show class="w-96 space-y-4 p-8 text-gray-800" let:close>
	<form
		class="space-y-4"
		on:submit|preventDefault={(e) => {
			handleSubmit(e, close);
		}}
	>
		{#if !resetPW}
			<div class="space-y-1">
				<h1 class="text-xl font-bold text-gray-800">
					Welcome
					{#if signup}
						to the TMU Marketplace
					{:else}
						Back
					{/if}
				</h1>
				<p class="text-sm text-gray-600">
					{si} to access the TMU Marketplace
				</p>
			</div>
			<div class="space-y-1">
				<p class="text-sm text-gray-600">Email Address</p>
				<input
					id="username"
					placeholder="hello@yourcompany.com"
					type="email"
					bind:value={email}
					autocomplete="username"
					class="w-full rounded-lg border border-gray-300 bg-white p-2 text-gray-900"
					required
				/>
			</div>
			<div class="space-y-1">
				<p class="text-sm text-gray-600">Password</p>
				<input
					placeholder="password..."
					type="password"
					bind:value={password}
					autocomplete="current-password"
					class="w-full rounded-lg border border-gray-300 bg-white p-2 text-gray-900"
					required
				/>
				{#if signup}
					<p class="text-xs text-gray-600">Password must have:</p>
					<ul class="list-inside list-disc text-xs text-gray-600">
						<li class:text-green-600={hasMinLength} class:text-red-600={!hasMinLength}>
							Minimum 7 characters
						</li>
						<li class:text-green-600={hasLowercase} class:text-red-600={!hasLowercase}>
							At least one lowercase letter
						</li>
						<li class:text-green-600={hasUppercase} class:text-red-600={!hasUppercase}>
							At least one uppercase letter
						</li>
						<li class:text-green-600={hasNumber} class:text-red-600={!hasNumber}>
							At least one number
						</li>
						<li class:text-green-600={hasSymbol} class:text-red-600={!hasSymbol}>
							At least one symbol
						</li>
					</ul>
				{/if}
				{#if !signup}
					<button
						type="button"
						class="text-sm text-blue-600 hover:underline"
						on:click={() => (resetPW = true)}
					>
						Forgot your password?
					</button>
				{/if}
			</div>
			<div class="space-y-2">
				<button
					type="submit"
					class="w-full rounded bg-blue-500 px-4 py-2 font-bold text-white hover:bg-blue-600"
				>
					{si}
				</button>
				<p class="select-none text-sm text-gray-500">
					{#if signup}
						Already have an account?
					{:else}
						Don't have an account?
					{/if}
					<button
						class="text-blue-600 hover:underline"
						on:click|preventDefault={() => {
							signup = !signup;
							clearInputs();
						}}
					>
						{signup ? 'Login' : 'Sign Up'}
					</button>
				</p>
			</div>
		{:else}
			<div class="space-y-1">
				<h1 class="text-xl font-bold text-gray-800">Reset Password</h1>
				<p class="text-sm text-gray-600">Enter your email address to reset your password</p>
			</div>
			<p class="text-sm text-gray-600">Email Address</p>
			<input
				placeholder="hello@yourcompany.com"
				type="email"
				bind:value={email}
				class="w-full rounded-lg border border-gray-300 bg-white p-2 text-gray-900"
				required
			/>
			<button
				type="submit"
				class="w-full rounded bg-blue-500 px-4 py-2 font-bold text-white hover:bg-blue-600"
			>
				Reset Password
			</button>
			<button class="text-sm text-blue-600 hover:underline" on:click={() => (resetPW = false)}>
				Return to Login
			</button>
		{/if}
	</form>
</Modal>

<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import TMULogo from '$lib/images/TMU-rgb.png';
	import DefaultUserImage from '$lib/images/user.png';

	import { page } from '$app/stores';
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import Alerts from '$lib/Alerts/Alerts.svelte';

	export let data;

	let { supabase, session } = data;
	$: ({ supabase, session } = data);

	onMount(() => {
		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange((event, _session) => {
			if (_session?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		});

		return () => subscription.unsubscribe();
	});

	let showHamburgerMenu = false;

	const handleSignOut = async (e: MouseEvent) => {
		e.preventDefault();
		await supabase.auth.signOut();
	};

	const handleProfileImageError = (e: Event) => {
		if (!e.target) {
			return;
		}
		(e.target as HTMLImageElement).src = DefaultUserImage;
	};

	const dropdownTriggers: { [key: string]: string } = {
		'user-dropdown': 'user-menu-button',
		dropdownNavbar: 'dropdownNavbarLink'
	};
	function handleWindowClick(e: MouseEvent) {
		e.stopPropagation();

		if (!e.target) {
			return;
		}
		const element = e.target as HTMLElement;

		for (const [dropdownId, dropdownTriggerId] of Object.entries(dropdownTriggers)) {
			const dropdownElement = document.getElementById(dropdownId);
			const dropdownTriggerElement = document.getElementById(dropdownTriggerId);

			if (element.id !== dropdownId && element.id !== dropdownTriggerId) {
				dropdownElement?.classList.add('hidden');
				dropdownTriggerElement?.setAttribute('aria-expanded', 'false');
			} else {
				const hidden = dropdownElement && dropdownElement.classList.contains('hidden');
				if (hidden) {
					dropdownElement?.classList.remove('hidden');
				} else {
					dropdownElement?.classList.add('hidden');
				}
				dropdownTriggerElement?.setAttribute('aria-expanded', String(!hidden));
			}
		}
	}
</script>

<svelte:window on:click={handleWindowClick} />

<Alerts />

<nav class="min-w-96 border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
	<div class="mx-auto flex max-w-screen-xl flex-wrap items-center justify-between p-4">
		<a href="/" class="mr-8 flex shrink-0 items-center space-x-3 rtl:space-x-reverse">
			<img src={TMULogo} class="h-10" alt="TMU Logo" />
			<span class="self-center whitespace-nowrap text-2xl font-semibold text-black dark:text-white"
				>Marketplace</span
			>
		</a>
		<div class="relative flex shrink-0 space-x-3 md:order-2 md:space-x-0 rtl:space-x-reverse">
			{#if session}
				<div class="flex gap-5">
					<button
						on:click={() => goto('/auth')}
						type="button"
						class="hidden rounded-lg bg-blue-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 sm:block dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
						>Place an Ad</button
					>
					<button
						type="button"
						class="flex items-center rounded-full bg-gray-800 text-sm focus:ring-4 focus:ring-gray-300 md:me-0 dark:focus:ring-gray-600"
						id="user-menu-button"
						data-dropdown-toggle="user-dropdown"
						data-dropdown-placement="bottom"
					>
						<span class="sr-only">Open user menu</span>
						<img
							class="pointer-events-none h-10 w-10 rounded-full"
							src="/docs/images/people/profile-picture-3.jpg"
							alt="user photo"
							on:error={handleProfileImageError}
						/>
					</button>
				</div>
				<!-- User dropdown menu -->
				<div
					class="absolute right-0 top-3/4 z-50 my-4 hidden list-none divide-y divide-gray-100 rounded-lg bg-white text-base shadow dark:divide-gray-600 dark:bg-gray-700"
					id="user-dropdown"
				>
					<div class="px-4 py-3">
						<span class="block text-sm text-gray-900 dark:text-white">Bonnie Green</span>
						<span class="block truncate text-sm text-gray-500 dark:text-gray-400"
							>{session.user.email}</span
						>
					</div>
					<ul class="py-2" aria-labelledby="user-menu-button">
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Profile</a
							>
						</li>
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Order History</a
							>
						</li>
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Admin Dashboard</a
							>
						</li>
					</ul>
					<div class="py-1">
						<a
							on:click={handleSignOut}
							class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
							>Sign out</a
						>
					</div>
				</div>
			{:else}
				<button
					on:click={() => goto('/auth')}
					type="button"
					class="shrink-0 rounded-lg bg-blue-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
					>Sign in / Register</button
				>
			{/if}

			<button
				data-collapse-toggle="navbar-cta"
				type="button"
				class="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-lg p-2 text-sm text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 md:hidden dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
				aria-controls="navbar-cta"
				aria-expanded="false"
				on:click={() => (showHamburgerMenu = !showHamburgerMenu)}
			>
				<span class="sr-only">Open main menu</span>
				<svg
					class="h-5 w-5"
					aria-hidden="true"
					xmlns="http://www.w3.org/2000/svg"
					fill="none"
					viewBox="0 0 17 14"
				>
					<path
						stroke="currentColor"
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M1 1h15M1 7h15M1 13h15"
					/>
				</svg>
			</button>
		</div>
		<div
			class:hidden={!showHamburgerMenu}
			class="w-full md:block md:w-auto"
			id="navbar-multi-level"
		>
			<ul
				class="mt-4 flex flex-col divide-y divide-gray-100 rounded-lg border border-gray-100 bg-gray-50 p-4 font-medium md:mt-0 md:flex-row md:space-x-8 md:divide-y-0 md:border-0 md:bg-white md:p-0 rtl:space-x-reverse dark:divide-gray-600 dark:border-gray-700 dark:bg-gray-800 md:dark:bg-gray-900"
			>
				<li>
					<a
						href="/"
						class="block rounded px-3 py-2 text-gray-900 hover:bg-gray-100 md:border-0 md:p-0 md:hover:bg-transparent md:hover:text-blue-700 dark:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent md:dark:hover:text-blue-500"
						class:text-blue-700={$page.url.pathname === '/'}
						aria-current={$page.url.pathname === '/' ? 'page' : undefined}>Home</a
					>
				</li>
				<li class="relative">
					<button
						id="dropdownNavbarLink"
						data-dropdown-toggle="dropdownNavbar"
						class="flex w-full items-center justify-between px-3 py-2 text-gray-900 hover:bg-gray-100 md:w-auto md:border-0 md:p-0 md:hover:bg-transparent md:hover:text-blue-700 dark:text-white dark:hover:bg-gray-700 dark:focus:text-white md:dark:hover:bg-transparent md:dark:hover:text-blue-500"
						>Categories<svg
							class="ms-2.5 h-2.5 w-2.5"
							aria-hidden="true"
							xmlns="http://www.w3.org/2000/svg"
							fill="none"
							viewBox="0 0 10 6"
						>
							<path
								stroke="currentColor"
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="m1 1 4 4 4-4"
							/>
						</svg></button
					>
					<!-- Dropdown menu -->
					<div
						id="dropdownNavbar"
						class="absolute z-10 left-1/3 md:-left-1/3 top-[125%] hidden w-44 divide-y divide-gray-100 rounded-lg bg-white font-normal shadow dark:divide-gray-600 dark:bg-gray-700"
					>
						<ul
							class="py-2 text-sm text-gray-700 dark:text-gray-200"
							aria-labelledby="dropdownLargeButton"
						>
							<li>
								<a
									href="#"
									class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Dashboard</a
								>
							</li>
							<li aria-labelledby="dropdownNavbarLink">
								<button
									id="doubleDropdownButton"
									data-dropdown-toggle="doubleDropdown"
									data-dropdown-placement="right-start"
									type="button"
									class="flex w-full items-center justify-between px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Dropdown<svg
										class="ms-2.5 h-2.5 w-2.5"
										aria-hidden="true"
										xmlns="http://www.w3.org/2000/svg"
										fill="none"
										viewBox="0 0 10 6"
									>
										<path
											stroke="currentColor"
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="m1 1 4 4 4-4"
										/>
									</svg></button
								>
								<div
									id="doubleDropdown"
									class="z-10 hidden w-44 divide-y divide-gray-100 rounded-lg bg-white shadow dark:bg-gray-700"
								>
									<ul
										class="py-2 text-sm text-gray-700 dark:text-gray-200"
										aria-labelledby="doubleDropdownButton"
									>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
												>Overview</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
												>My downloads</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
												>Billing</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
												>Rewards</a
											>
										</li>
									</ul>
								</div>
							</li>
							<li>
								<a
									href="#"
									class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Items Wanted</a
								>
							</li>
							<li>
								<a
									href="#"
									class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Items For Sale</a
								>
							</li>
							<li>
								<a
									href="#"
									class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Academic Services</a
								>
							</li>
						</ul>
						<div class="py-1">
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Sign out</a
							>
						</div>
					</div>
				</li>
				<li>
					<a
						href="#"
						class="block rounded px-3 py-2 text-gray-900 hover:bg-gray-100 md:border-0 md:p-0 md:hover:bg-transparent md:hover:text-blue-700 dark:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent md:dark:hover:text-blue-500"
						>Chatroom</a
					>
				</li>
				<li class="block flex justify-center px-3 py-2 sm:hidden">
					<button
						on:click={() => goto('/auth')}
						type="button"
						class="rounded-lg bg-blue-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
						>Place an Ad</button
					>
				</li>
			</ul>
		</div>
	</div>
</nav>

<slot />

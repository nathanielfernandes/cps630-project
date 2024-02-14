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

<nav class="min-w-[32rem] bg-white border-gray-200 dark:bg-gray-900 dark:border-gray-700">
	<div class="max-w-screen-xl flex flex-wrap items-center justify-between mx-auto p-4">
    <a href="/" class="shrink-0 flex mr-8 items-center space-x-3 rtl:space-x-reverse">
      <img src={TMULogo} class="h-10" alt="TMU Logo" />
      <span class="self-center text-2xl font-semibold whitespace-nowrap text-black dark:text-white"
        >Marketplace</span
      >
    </a>
		<div class="shrink-0 relative flex md:order-2 space-x-3 md:space-x-0 rtl:space-x-reverse">
			{#if session}
				<div class="flex gap-5">
					<button
						on:click={() => goto('/auth')}
						type="button"
						class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-4 py-2 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
						>Place an Ad</button
					>
					<button
						type="button"
						class="flex items-center text-sm bg-gray-800 rounded-full md:me-0 focus:ring-4 focus:ring-gray-300 dark:focus:ring-gray-600"
						id="user-menu-button"
						data-dropdown-toggle="user-dropdown"
						data-dropdown-placement="bottom"
					>
						<span class="sr-only">Open user menu</span>
						<img
							class="w-10 h-10 rounded-full pointer-events-none"
							src="/docs/images/people/profile-picture-3.jpg"
							alt="user photo"
							on:error={handleProfileImageError}
						/>
					</button>
				</div>
				<!-- User dropdown menu -->
				<div
					class="absolute hidden z-50 my-4 top-3/4 right-0 text-base list-none bg-white divide-y divide-gray-100 rounded-lg shadow dark:bg-gray-700 dark:divide-gray-600"
					id="user-dropdown"
				>
					<div class="px-4 py-3">
						<span class="block text-sm text-gray-900 dark:text-white">Bonnie Green</span>
						<span class="block text-sm text-gray-500 truncate dark:text-gray-400"
							>{session.user.email}</span
						>
					</div>
					<ul class="py-2" aria-labelledby="user-menu-button">
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
								>Profile</a
							>
						</li>
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
								>Order History</a
							>
						</li>
						<li>
							<a
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
								>Admin Dashboard</a
							>
						</li>
						<li>
							<a
								on:click={handleSignOut}
								href="#"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
								>Sign out</a
							>
						</li>
					</ul>
				</div>
			{:else}
				<button
					on:click={() => goto('/auth')}
					type="button"
					class="shrink-0 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-4 py-2 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
					>Sign in / Register</button
				>
			{/if}

			<button
				data-collapse-toggle="navbar-cta"
				type="button"
				class="shrink-0 inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
				aria-controls="navbar-cta"
				aria-expanded="false"
				on:click={() => (showHamburgerMenu = !showHamburgerMenu)}
			>
				<span class="sr-only">Open main menu</span>
				<svg
					class="w-5 h-5"
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
				class="flex flex-col font-medium p-4 md:p-0 mt-4 border border-gray-100 rounded-lg bg-gray-50 md:space-x-8 rtl:space-x-reverse md:flex-row md:mt-0 md:border-0 md:bg-white dark:bg-gray-800 md:dark:bg-gray-900 dark:border-gray-700"
			>
				<li>
					<a
						href="/"
						class="block py-2 px-3 text-gray-900 rounded hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-white md:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent"
						class:text-blue-700={$page.url.pathname === '/'}
						aria-current={$page.url.pathname === '/' ? 'page' : undefined}>Home</a
					>
				</li>
				<li>
					<button
						id="dropdownNavbarLink"
						data-dropdown-toggle="dropdownNavbar"
						class="flex items-center justify-between w-full py-2 px-3 text-gray-900 hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 md:w-auto dark:text-white md:dark:hover:text-blue-500 dark:focus:text-white dark:hover:bg-gray-700 md:dark:hover:bg-transparent"
						>Categories<svg
							class="w-2.5 h-2.5 ms-2.5"
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
						class="absolute hidden z-10 font-normal bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700 dark:divide-gray-600"
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
									class="flex items-center justify-between w-full px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
									>Dropdown<svg
										class="w-2.5 h-2.5 ms-2.5"
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
									class="z-10 hidden bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700"
								>
									<ul
										class="py-2 text-sm text-gray-700 dark:text-gray-200"
										aria-labelledby="doubleDropdownButton"
									>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
												>Overview</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
												>My downloads</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
												>Billing</a
											>
										</li>
										<li>
											<a
												href="#"
												class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
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
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-200 dark:hover:text-white"
								>Sign out</a
							>
						</div>
					</div>
				</li>
				<li>
					<a
						href="#"
						class="block py-2 px-3 text-gray-900 rounded hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-white md:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent"
						>Chatroom</a
					>
				</li>
			</ul>
		</div>
	</div>
</nav>

<slot />

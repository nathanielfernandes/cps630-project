<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';

	import { page } from '$app/stores';
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';

	import Alerts from '$lib/Alerts/Alerts.svelte';
	import { successAlert, warningAlert, errorAlert } from '$lib/Alerts/stores.js';
	import { clickOutside } from '$lib/clickOutside';
	import LoginSignup from '$lib/components/LoginSignup.svelte';
	import { isProtectedPage } from '$lib/protectedPages';

	export let data;
	let { supabase, session } = data;
	$: ({ supabase, session } = data);

    $: {
        // Redirect and ask user to login, if user tries to visit a protected page and is not logged in
        if (isProtectedPage($page.url.pathname) && !session) {
            window.location.replace('/?askLogin=true');
        }
    }

	let show_login_modal = false;
	let pathBeforeSignOut = '';

	onMount(() => {
		if ($page.url.searchParams.get('askLogin') === 'true') {
			show_login_modal = true;
			errorAlert('Not authorized to view page');

			// Remove the 'askLogin' search param and update the url
			const params = new URLSearchParams($page.url.searchParams);
			params.delete('askLogin');
			goto(params.size === 0 ? '/' : `/?${params.toString()}`);
		}

		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange((event, _session) => {
			if (_session?.expires_at !== session?.expires_at) {
				if (event === 'SIGNED_IN') {
					successAlert('Sign in successful');
				}
				invalidate('supabase:auth');
			}
			if (event === 'SIGNED_OUT') {
				warningAlert('You have been signed out');
                // If the previous page before signing out was a protected page, show login modal
                if (isProtectedPage(pathBeforeSignOut)) {
                    show_login_modal = true;
                }
			}
		});

		return () => subscription.unsubscribe();
	});

	const DefaultUserImage = '/user.png';

	const handleSignOut = async () => {
		// Keep track of previous page before signing out which will redirect to homepage
		pathBeforeSignOut = window.location.pathname;
		await supabase.auth.signOut();
		dropdownVisibility['user-dropdown'] = false;
	};

	const replaceBadImageWithDefault = (image: HTMLImageElement, defaultImageSrc: string) => {
		if (image.naturalWidth === 0 && image.naturalHeight === 0) {
			image.src = defaultImageSrc;
		}
	};

	const handleProfileImageError = (e: Event) => {
		if (!e.target) {
			return;
		}
		replaceBadImageWithDefault(e.target as HTMLImageElement, DefaultUserImage);
	};

	const dropdownTrigger: { [key: string]: string } = {
		'user-dropdown': 'user-menu-button'
	};
	const dropdownVisibility: { [key: string]: boolean } = {
		'user-dropdown': false
	};
	const handleDropdownClickOutside = ({
		detail: { node, clickedElement }
	}: CustomEvent<ClickOutsideEvent>) => {
		// If user clicked outside of dropdown and it was not the dropdown trigger element
		if (clickedElement.id !== dropdownTrigger[node.id]) {
			dropdownVisibility[node.id] = false;
		}
	};
</script>

<!-- <svelte:head>
	<script src="https://kit.fontawesome.com/3403ec00eb.js" crossorigin="anonymous"></script>
</svelte:head> -->

<Alerts />

<nav class="border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
	<div
		class="mx-auto flex max-w-screen-xl flex-col flex-wrap items-center justify-between gap-y-5 p-4 sm:flex-row"
	>
		<a href="/" class="flex shrink-0 items-center space-x-3 rtl:space-x-reverse">
			<img src="/TMU-rgb.png" class="h-10" alt="TMU Logo" />
			<span class="self-center whitespace-nowrap text-2xl font-semibold text-black dark:text-white"
				>Marketplace</span
			>
		</a>
		<div class="relative flex shrink-0 gap-5 md:order-2 md:space-x-0 rtl:space-x-reverse">
			<button
				on:click={() => goto('/auth')}
				type="button"
				class="rounded-lg bg-yellow-300 px-4 py-2 text-center text-sm font-medium text-gray-900 hover:bg-yellow-500 focus:outline-none focus:ring-4 focus:ring-yellow-300/70 dark:focus:ring-yellow-800/70"
				>Place an Ad</button
			>
			{#if session}
				<button
					data-collapse-toggle="navbar-solid-bg"
					type="button"
					class="inline-flex h-10 w-10 items-center justify-center rounded-lg p-1 text-sm text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
					aria-controls="navbar-solid-bg"
					aria-expanded="false"
				>
					<span class="sr-only">Open chat</span>
					<i class="fa-regular fa-message text-2xl"></i>
				</button>
				<button
					type="button"
					class="order-1 flex items-center rounded-full bg-gray-800 text-sm focus:ring-4 focus:ring-gray-300 md:me-0 dark:focus:ring-gray-600"
					id="user-menu-button"
					data-dropdown-toggle="user-dropdown"
					data-dropdown-placement="bottom"
					on:click={() =>
						(dropdownVisibility['user-dropdown'] = !dropdownVisibility['user-dropdown'])}
					aria-expanded={dropdownVisibility['user-dropdown']}
				>
					<span class="sr-only">Open user menu</span>
					<img
						use:replaceBadImageWithDefault={DefaultUserImage}
						on:error={handleProfileImageError}
						class="pointer-events-none h-10 w-10 rounded-full"
						src="/user.png"
						alt="user"
					/>
				</button>
				<!-- User dropdown menu -->
				<div
					id="user-dropdown"
					class="absolute right-0 top-3/4 z-50 my-4 list-none divide-y divide-gray-100 rounded-lg bg-white text-base shadow dark:divide-gray-600 dark:bg-gray-700"
					class:hidden={!dropdownVisibility['user-dropdown']}
					use:clickOutside
					on:click_outside={handleDropdownClickOutside}
				>
					<div class="px-4 py-3">
						<!-- <span class="block text-sm text-gray-900 dark:text-white">Bonnie Green</span> -->
						<span class="block truncate text-sm text-gray-500 dark:text-gray-400"
							>{session.user.email}</span
						>
					</div>
					<ul class="py-2" aria-labelledby="user-menu-button">
						<li>
							<a
								href="/"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Profile</a
							>
						</li>
						<li>
							<a
								href="/"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Order History</a
							>
						</li>
						<li>
							<a
								href="/admin"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
								>Admin Dashboard</a
							>
						</li>
					</ul>
					<div class="py-1">
						<a
							href="/"
							role="button"
							tabIndex="0"
							on:click={handleSignOut}
							on:keypress={(e) => e.key === 'Enter' && handleSignOut()}
							class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-600 dark:hover:text-white"
							>Sign out</a
						>
					</div>
				</div>
			{:else}
				<button
					on:click={() => (show_login_modal = true)}
					type="button"
					class="shrink-0 rounded-lg bg-blue-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
					>Sign in / Register</button
				>
			{/if}
		</div>
	</div>
</nav>

<nav class="bg-slate-200 dark:bg-gray-700">
	<div
		class="mx-auto flex max-w-screen-xl flex-col-reverse items-stretch gap-x-10 gap-y-5 px-4 py-3 md:flex-row md:items-center md:justify-between md:gap-x-24 lg:gap-x-44"
	>
		<div class="flex items-center">
			<ul class="mt-0 flex flex-row space-x-5 sm:space-x-8 text-center text-sm font-medium rtl:space-x-reverse">
				<li>
					<a
						href="/"
						aria-current={$page.url.pathname === '/' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500"
						>Home</a
					>
				</li>
				<li>
					<a
						rel="external"
						href="/dashboard/items_wanted"
						aria-current={$page.url.pathname === '/dashboard/wanted' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500"
						>Wanted Listings</a
					>
				</li>
				<li>
					<a
						rel="external"
						href="/dashboard/items_for_sale"
						aria-current={$page.url.pathname === '/dashboard/sale' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500"
						>Buy & Sell</a
					>
				</li>
				<li>
					<a
						rel="external"
						href="/dashboard/academic_services"
						aria-current={$page.url.pathname === '/dashboard/service' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500"
						>Academic Services</a
					>
				</li>
			</ul>
		</div>
		<form class="relative flex flex-1 items-center">
			<input
				type="text"
				id="search-navbar"
				class="border-box block w-full rounded-lg border-2 bg-white p-3 text-sm text-gray-900 outline-none focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-900 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
				placeholder="Search..."
			/>
			<button
				type="submit"
				class="absolute right-0 box-border flex h-full items-center justify-center rounded-r-lg border-2 border-white/0 bg-blue-600 p-3 text-white hover:bg-blue-700 focus:border-blue-800 focus:ring focus:ring-blue-800"
			>
				<svg
					class="h-4 w-4 text-white"
					aria-hidden="true"
					xmlns="http://www.w3.org/2000/svg"
					fill="none"
					viewBox="0 0 20 20"
				>
					<path
						stroke="currentColor"
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z"
					/>
				</svg>
				<span class="sr-only">Search icon</span>
			</button>
		</form>
	</div>
</nav>

<slot />

<LoginSignup {supabase} bind:show={show_login_modal} />

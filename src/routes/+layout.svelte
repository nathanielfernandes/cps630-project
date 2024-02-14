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

	const handleSignOut = async (e: MouseEvent) => {
		e.preventDefault();
		await supabase.auth.signOut();
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

	const dropdownTriggers: { [key: string]: string } = {
		'user-dropdown': 'user-menu-button'
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

<nav class="border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
	<div
		class="mx-auto flex max-w-screen-xl flex-col flex-wrap items-center justify-between gap-y-5 p-4 sm:flex-row"
	>
		<a href="/" class="flex shrink-0 items-center space-x-3 rtl:space-x-reverse">
			<img src={TMULogo} class="h-10" alt="TMU Logo" />
			<span class="self-center whitespace-nowrap text-2xl font-semibold text-black dark:text-white"
				>Marketplace</span
			>
		</a>
		<div class="relative flex shrink-0 gap-5 md:order-2 md:space-x-0 rtl:space-x-reverse">
			<button
				on:click={() => goto('/auth')}
				type="button"
				class="rounded-lg bg-yellow-500 px-4 py-2 text-center text-sm font-medium text-white hover:bg-yellow-600 focus:outline-none focus:ring-4 focus:ring-yellow-300/70 dark:focus:ring-yellow-800/70"
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
          <svg class="w-8" xmlns="http://www.w3.org/2000/svg" viewBox="-2 -2.5 24 24" width="28" fill="currentColor"><path d="M9.378 12H17a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1 1 1 0 0 1 1 1v3.013L9.378 12zM3 0h14a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3h-6.958l-6.444 4.808A1 1 0 0 1 2 18.006V14a2 2 0 0 1-2-2V3a3 3 0 0 1 3-3z"></path></svg>
				</button>
				<button
					type="button"
					class="order-1 flex items-center rounded-full bg-gray-800 text-sm focus:ring-4 focus:ring-gray-300 md:me-0 dark:focus:ring-gray-600"
					id="user-menu-button"
					data-dropdown-toggle="user-dropdown"
					data-dropdown-placement="bottom"
				>
					<span class="sr-only">Open user menu</span>
					<img
            use:replaceBadImageWithDefault={DefaultUserImage}
            on:error={handleProfileImageError}
						class="pointer-events-none h-10 w-10 rounded-full"
						src="/docs/images/people/profile-picture-3.jpg"
						alt="user"
					/>
				</button>
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
		</div>
	</div>
</nav>

<nav class="bg-gray-50 dark:bg-gray-700">
	<div
		class="mx-auto flex max-w-screen-xl flex-col-reverse md:justify-between items-stretch gap-x-10 md:gap-x-24 lg:gap-x-44 gap-y-5 px-4 py-3 md:flex-row md:items-center"
	>
		<div class="flex items-center">
			<ul class="mt-0 flex flex-row space-x-8 text-sm font-medium rtl:space-x-reverse text-center">
				<li>
					<a href="/" aria-current={$page.url.pathname === '/' ? 'page' : undefined} class="block py-2 px-3 aria-[current=page]:text-blue-500 text-gray-900 hover:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500"
						>Home</a
					>
				</li>
				<li>
					<a href="/wanted" aria-current={$page.url.pathname === '/wanted' ? 'page' : undefined} class="block py-2 px-3 aria-[current=page]:text-blue-500 text-gray-900 hover:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500">Wanted Listings</a>
				</li>
				<li>
					<a href="/sale" aria-current={$page.url.pathname === '/sale' ? 'page' : undefined} class="block py-2 px-3 aria-[current=page]:text-blue-500 text-gray-900 hover:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500">Buy & Sell</a>
				</li>
				<li>
					<a href="/service" aria-current={$page.url.pathname === '/service' ? 'page' : undefined} class="block py-2 px-3 aria-[current=page]:text-blue-500 text-gray-900 hover:text-blue-500 md:p-0 dark:text-white dark:hover:text-blue-500">Academic Services</a>
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

<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';

	import { page } from '$app/stores';
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';

	import Alerts from '$lib/Alerts/Alerts.svelte';

	import { warningAlert, errorAlert } from '$lib/Alerts/stores.js';
	import { clickOutside } from '$lib/clickOutside';
	import LoginSignup from '$lib/components/LoginSignup.svelte';
	import { disconnect_websocket, uuid, ssecret, connect_websocket, resetChatState, open, ping } from '$lib/chatter/stores';
	import { isProtectedPage } from '$lib/protectedPages';
	import Chat from '$lib/chatter/Chat.svelte';
	import Pfp from '$lib/components/Pfp.svelte';
	import { posts, user_info } from '$lib/stores';

	export let data;
	let { supabase, session } = data;
	$: ({ supabase, session } = data);

	$: email = (session ? session.user.email : '') as string;


	const fetchPosts = async () => {
		const { data, error } = await supabase.from('posts').select(`
            id,
            title,
            content,
            price,
            created_at,
            type,
            location,
            images:images!post_id (link, alt_text),
            user_id,
            email
        `);

        if (error) {
            console.log(error);
            throw error;
        }

		const fetched = data || [];
		posts.update((p) => {
			p = {};
			for (const post of fetched) {
				// @ts-ignore
				p[post.id.toString()] = post;
			}
			return p;
		});
	};

	fetchPosts();


	const fetchUsers = async () => {
		const { data, error } = await supabase.from('user_info').select('id, email, role');

		if (error) {
			console.log(error);
			throw error;
		}

		const fetched = data || [];
		user_info.set(fetched);
	};

	fetchUsers();

	let is_admin = false;
	if (session) {
		const user_id = session.user.id;
		const user = $user_info.find((u) => u.id === user_id);
		if (user) {
			is_admin = user.role === 'admin';
		}
	}
	user_info.subscribe((users) => {
		if (session) {
			const user_id = session.user.id;
			const user = users.find((u) => u.id === user_id);
			if (user) {
				is_admin = user.role === 'admin';
			}
		}
	});

 	function wsAuthAttempt() {
		if ($page.data.session) {
			// select user id and secret
			supabase
				.from('verify')
				.select('id, secret')
				.single()
				.then(({ data, error }) => {
					if (error) {
						console.error('Error fetching user secret:', error);
						return;
					}
					if (data) {
						const { id, secret } = data;
						uuid.set(id);
						ssecret.set(secret);
					}
				});
		}
	}

    let searchValue = "";
    const handleSearch = (e: Event) => {
        e.preventDefault();
        const url = new URL($page.url);
        url.searchParams.set("q", searchValue);
        goto(url);
    }
  
	let show_login_modal = false;
	let pathBeforeSignOut = '';

    $: {
        // Redirect and ask user to login, if user tries to visit a protected page and is not logged in
        if (isProtectedPage($page.url.pathname) && !session) {
            window.location.replace('/?askLogin=true');
        }
    }

	onMount(() => {
		// subscribe to new posts
		const postChannel = supabase
			.channel('posts_listener')
			.on("postgres_changes", 
				{
					event: "*",
					schema: "public",
					table: "posts"
				},
				async ({ eventType, new: npost, old }) => {
					switch (eventType) {
						case "INSERT":
							// get images for the new post
							const { data: images } = await supabase
								.from('images')
								.select('link, alt_text')
								.eq('post_id', npost.id);

							posts.update((p) => {
								// @ts-ignore
								p[npost.id.toString()] =  {
									images: images || [],
									...npost,
								}
								return p;
							});
							break;
						case "UPDATE":
							// get images for the new post
							const { data: images2 } = await supabase
								.from('images')
								.select('link, alt_text')
								.eq('post_id', npost.id);

							posts.update((p) => {
								// @ts-ignore
								p[npost.id.toString()] = {
									images: images2 || [],
									...npost,
								}
								return p;
							});
							break;
						case "DELETE":
							posts.update((p) => {
								delete p[old.id.toString()];
								return p;
							});
							break;
					}
				})
			.subscribe();

		const usersChannel = supabase
			.channel('users_listener')
			.on("postgres_changes", 
				{
					event: "*",
					schema: "public",
					table: "user_info"
				},
				async ({ eventType, new: nuser, old }) => {
					switch (eventType) {
						case "INSERT":
							user_info.update((u) => {
								//@ts-ignore
								u.push(nuser);
								return u;
							});
							break;
						case "DELETE":
							user_info.update((u) => {
								const index = u.findIndex((user) => user.id === old.id);
								u.splice(index, 1);
								return u;
							});
							break;
					}
				})
			.subscribe();

		connect_websocket();

		if ($page.url.searchParams.get('askLogin') === 'true') {
			show_login_modal = true;
			errorAlert('Not authorized to view page');

			// Remove the 'askLogin' search param and update the url
			const params = new URLSearchParams($page.url.searchParams);
			params.delete('askLogin');
			goto(params.size === 0 ? '/' : `/?${params.toString()}`);
		}

		wsAuthAttempt();

		const {
			data: { subscription }
		} = supabase.auth.onAuthStateChange((event, _session) => {
			if (_session?.expires_at !== session?.expires_at) {
				// if (event === 'SIGNED_IN') {
					// successAlert('Signed in successful');
				// }
				invalidate('supabase:auth').then(wsAuthAttempt);
			}
			// If the previous page before signing out was a protected page, show login modal
			if (event === 'SIGNED_OUT') {
				uuid.set("");
				ssecret.set("");
				disconnect_websocket();
				resetChatState();
				warningAlert('You have been signed out');
				// If the previous page before signing out was a protected page, show login modal
				if (isProtectedPage(pathBeforeSignOut)) {
					show_login_modal = true;
				}

			}
		});

		return () => {
			uuid.set("");
			ssecret.set("");
			disconnect_websocket();
			resetChatState();
			subscription.unsubscribe();
			postChannel.unsubscribe();
			usersChannel.unsubscribe();
		};
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

<svelte:head>
	<title>TMU Marketplace</title>
	<meta name="description" content="TMU Marketplace for students to buy and sell items" />
	<meta name="keywords" content="TMU, Marketplace, Student, Buy, Sell, Items" />
</svelte:head>

<Alerts />

<nav class="border-gray-200 bg-white">
	<div
		class="mx-auto flex max-w-screen-xl flex-col flex-wrap items-center justify-between gap-y-5 p-4 sm:flex-row"
	>
		<a href="/" class="flex shrink-0 items-center space-x-3 rtl:space-x-reverse">
			<img src="/TMU-rgb.png" class="h-10" alt="TMU Logo" />
			<span class="self-center whitespace-nowrap text-2xl font-semibold text-black"
				>Marketplace</span
			>
		</a>
		<div class="relative flex shrink-0 gap-5 md:order-2 md:space-x-0 rtl:space-x-reverse">
			<button
				on:click={() => goto('/dashboard/create')}
				type="button"
				class="rounded-lg bg-yellow-300 px-4 py-2 text-center text-sm font-medium text-gray-900 hover:bg-yellow-500 focus:outline-none focus:ring-4 focus:ring-yellow-300/70"
				>Place an Ad</button
			>
			{#if session}
				<button
					data-collapse-toggle="navbar-solid-bg"
					type="button"
					class="relative inline-flex h-10 w-10 items-center justify-center rounded-lg p-1 text-sm text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200"
					aria-controls="navbar-solid-bg"
					aria-expanded="false"
					on:click={() => open.update((v) => !v)}
				>
					<span class="sr-only">Open chat</span>
					<i class="fa-regular fa-message text-3xl"></i>

					{#if $ping}
						<span
							class="absolute top-1 right-1 inline-flex items-center justify-center w-2 h-2 text-xs font-bold leading-none text-white  bg-red-500 rounded-full"
							></span
						>
						<span
							class="absolute top-1 right-1 inline-flex items-center justify-center w-2 h-2 text-xs font-bold leading-none text-white  bg-red-500 rounded-full animate-ping"
							></span
						>
					{/if}
				</button>
				<button
					type="button"
					class="order-1 flex items-center rounded-md text-sm focus:ring-4 focus:ring-gray-300 md:me-0"
					id="user-menu-button"
					data-dropdown-toggle="user-dropdown"
					data-dropdown-placement="bottom"
					on:click={() =>
						(dropdownVisibility['user-dropdown'] = !dropdownVisibility['user-dropdown'])}
					aria-expanded={dropdownVisibility['user-dropdown']}
				>
					<span class="sr-only">Open user menu</span>
					<Pfp email={email} class="h-10 w-10 rounded-md" />
					<!-- <img
						use:replaceBadImageWithDefault={DefaultUserImage}
						on:error={handleProfileImageError}
						class="pointer-events-none h-10 w-10 rounded-full"
						src="/user.png"
						alt="user"
					/> -->
				</button>
				<!-- User dropdown menu -->
				<div
					id="user-dropdown"
					class="absolute right-0 top-3/4 z-50 my-4 list-none divide-y divide-gray-100 rounded-lg bg-white text-base shadow"
					class:hidden={!dropdownVisibility['user-dropdown']}
					use:clickOutside
					on:click_outside={handleDropdownClickOutside}
				>
					<div class="px-4 py-3">
						<!-- <span class="block text-sm text-gray-900 dark:text-white">Bonnie Green</span> -->
						<span class="block truncate text-sm text-gray-500"
							>{session.user.email}</span
						>
					</div>
					<ul class="py-2" aria-labelledby="user-menu-button">
						<!-- <li>
							<a
								href="/"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>Profile</a
							>
						</li> -->
						<!-- <li>
							<a
								href="/"
								class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>Order History</a
							>
						</li> -->
						<li>	
							{#if is_admin}
								<a
									href="/admin"
									class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>Admin Dashboard</a
								>
							{:else}
								<a
									href="/dashboard/create"
									class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>Dashboard</a
								>
							{/if}
						</li>
					</ul>
					<div class="py-1">
						<a
							href="/"
							role="button"
							tabIndex="0"
							on:click={handleSignOut}
							on:keypress={(e) => e.key === 'Enter' && handleSignOut()}
							class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
							>Sign out</a
						>
					</div>
				</div>
			{:else}
				<button
					on:click={() => (show_login_modal = true)}
					type="button"
					class="shrink-0 rounded-lg bg-blue-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300"
					>Sign in / Register</button
				>
			{/if}
		</div>
	</div>
</nav>

<nav class="bg-slate-200">
	<div
		class="mx-auto flex max-w-screen-xl flex-col-reverse items-stretch gap-x-10 gap-y-5 px-4 py-3 md:flex-row md:items-center md:justify-between md:gap-x-24 lg:gap-x-44"
	>
		<div class="flex items-center">
			<ul class="mt-0 flex flex-row space-x-5 sm:space-x-8 text-center text-sm font-medium rtl:space-x-reverse">
				<li>
					<a
						href="/"
						aria-current={$page.url.pathname === '/' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0"
						>Home</a
					>
				</li>
				<li>
					<a
						href="/dashboard/listings/wanted"
						aria-current={$page.url.pathname === '/dashboard/listings/wanted' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0"
						>Wanted Listings</a
					>
				</li>
				<li>
					<a
						href="/dashboard/listings/selling"
						aria-current={$page.url.pathname === '/dashboard/listings/selling' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0"
						>Buy & Sell</a
					>
				</li>
				<li>
					<a
						href="/dashboard/listings/services"
						aria-current={$page.url.pathname === '/dashboard/listings/services' ? 'page' : undefined}
						class="block px-3 py-2 text-gray-900 hover:text-blue-500 aria-[current=page]:text-blue-500 md:p-0"
						>Academic Services</a
					>
				</li>
			</ul>
		</div>
		<form class="relative flex flex-1 items-center">
			<input
				type="search"
				id="search-navbar"
				class="border-box block w-full rounded-lg border-2 bg-white p-3 text-sm text-gray-900 outline-none focus:border-blue-500 focus:ring-blue-500"
				placeholder="Search..."
                bind:value={searchValue}
			/>
			<button
				type="submit"
                on:click={handleSearch}
				class="absolute right-0 box-border flex h-full items-center justify-center rounded-r-lg border-2 border-white/0 bg-blue-600 p-3 text-white hover:bg-blue-700 focus:border-blue-800 focus:ring focus:ring-blue-800"
			>
				<!-- <svg
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
				</svg> -->
				<i class="fa-solid fa-magnifying-glass text-white"></i>
				<span class="sr-only">Search icon</span>
			</button>
		</form>
	</div>
</nav>



<slot />

<Chat />

<LoginSignup {supabase} bind:show={show_login_modal} />


<footer class="bg-white mt-10">
    <div class="mx-auto w-full max-w-screen-xl p-4 py-6 lg:py-8">
        <div class="md:flex md:justify-between">
          <div class="mb-6 md:mb-0">
              <a href="/" class="flex items-center">
				  <!-- <img src="/TMU-rgb.png" class="h-10" alt="TMU Logo" /> -->
                  <span class="self-center text-2xl font-semibold whitespace-nowrap text-gray-900 ml-2">Toronto Metropolitan University</span>
              </a>
          </div>
          <div class="grid grid-cols-2 gap-8 sm:gap-6 sm:grid-cols-1">
              <div>
                  <h2 class="mb-6 text-sm font-semibold text-gray-900 uppercase ">Legal</h2>
                  <ul class="text-gray-500  font-medium">
                      <li class="mb-4">
                          <a href="https://www.torontomu.ca/privacy/" class="hover:underline">Privacy Policy</a>
                      </li>
                      <li>
                          <a href="https://www.torontomu.ca/terms-conditions/" class="hover:underline">Terms &amp; Conditions</a>
                      </li>
                  </ul>
              </div>
          </div>
      </div>
      <hr class="my-6 border-gray-200 sm:mx-auto lg:my-8" />
      <div class="sm:flex sm:items-center sm:justify-between">
          <span class="text-sm text-gray-500 sm:text-center ">© 2024 <a href="/" class="hover:underline">Toronto Metropolitan University</a>
          </span>
      </div>
    </div>
</footer>

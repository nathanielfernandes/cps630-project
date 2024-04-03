<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { successAlert, errorAlert } from '$lib/Alerts/stores';
	import { startChat } from '$lib/chatter/stores';
	import { clickOutside } from '$lib/clickOutside';
	import Carousel from '$lib/components/Carousel.svelte';
	import Pfp from '$lib/components/Pfp.svelte';
	import { posts } from '$lib/stores';


	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);

	const post_id = $page.params.post_id;
	let post = $posts[post_id];
	$: post = $posts[post_id];

	let isOpen = false;
	const toggle = () => (isOpen = !isOpen);
	let desc: HTMLParagraphElement;

	function isEllipsisActive(e: HTMLElement) {
		if (!e) return false;

		var c: any = e.cloneNode(true);
		c.style.display = 'inline';
		c.style.width = 'auto';
		c.style.visibility = 'hidden';
		document.body.appendChild(c);
		const truncated = c.offsetWidth >= e.clientWidth;
		c.remove();
		return truncated;
	}

	function swapListings(type: string) {
		switch (type) {
			case 'items_for_sale':
				return 'selling';
			case 'items_wanted':
				return 'wanted';
			case 'academic_services':
				return 'services';
			default:
				return 'wanted';
		}
	}

    let showActions = session?.user.id === (post || {}).user_id;
	let showActionsDropdown = false;
	$: showActionsDropdown = showActions ? showActionsDropdown : false;

    const IMAGE_URL_PREFIX =
		'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/';

    const handleEdit = async () => {
        goto(`/dashboard/edit/${post_id}`);
    }
	const handleDelete = async () => {
        let response = await supabase.from('images').delete().eq('post_id', post_id).select();
        if (response.error) {
            console.error(response.error);
            errorAlert("Failed to delete post.");
            return;
        }
        // const imagePaths = response.data.map((d) => decodeURIComponent(d.link.replace(IMAGE_URL_PREFIX, "")));
        // supabase.storage.from("images").remove(imagePaths);

		response = await supabase.from('posts').delete().eq('id', post_id).select();
        if (response.error) {
            console.error(response.error);
            errorAlert("Failed to delete post.");
            return;
        }

        successAlert("Successfully deleted post: " + post.title);
        delete $posts[post_id];
        $posts = $posts;

        goto(`/dashboard/listings/${swapListings(post.type)}`);
	};
</script>

<!-- <p class="text-2xl text-black">{post_id}</p> -->

{#if post !== undefined}
	<div class="relative mx-auto w-full max-w-screen-xl px-4 py-7 font-normal">
		{#if showActions}
			<div class="absolute right-5 top-5">
				<button
					id="dropdownMenuIconHorizontalButton"
					data-dropdown-toggle="dropdownDotsHorizontal"
					class="inline-flex items-center rounded-lg p-2 text-center text-sm font-medium text-gray-900 hover:bg-gray-200 focus:outline-none focus:ring-4 focus:ring-blue-200 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700 dark:focus:ring-gray-600"
					type="button"
					on:click={(e) => {
						e.stopPropagation();
						e.preventDefault();
						showActionsDropdown = !showActionsDropdown;
					}}
				>
					<svg
						class="h-5 w-5"
						aria-hidden="true"
						xmlns="http://www.w3.org/2000/svg"
						fill="currentColor"
						viewBox="0 0 16 3"
					>
						<path
							d="M2 0a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Zm6.041 0a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM14 0a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Z"
						/>
					</svg>
				</button>

				<!-- Dropdown menu -->
				<div
					id="dropdownDotsHorizontal"
					class="absolute -right-5 z-10 w-44 divide-y divide-gray-100 rounded-lg bg-white shadow-lg dark:divide-gray-600 dark:bg-gray-700"
					class:hidden={!showActionsDropdown}
                    use:clickOutside
                    on:click_outside={() => showActionsDropdown = false}
				>
					<ul
						class="py-2 text-sm text-gray-700 dark:text-gray-200"
						aria-labelledby="dropdownMenuIconHorizontalButton"
					>
						<li>
							<button
                                on:click={handleEdit}
								class="block w-full px-4 py-2 text-left hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
								>Edit</button
							>
						</li>
						<li>
							<button
                                on:click={handleDelete}
								class="block w-full px-4 py-2 text-left text-red-500 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
								>Delete</button
							>
						</li>
					</ul>
				</div>
			</div>
		{/if}

		<a
			class="mb-4 rounded-lg bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white transition duration-100 ease-in-out hover:bg-blue-700"
			href="/dashboard/listings/{swapListings(post.type)}"
		>
			<i class="fa-solid fa-arrow-left pr-2"></i>
			Back
		</a>

		<h1
			class="mt-7 text-center text-xl font-semibold text-black lg:max-w-[600px] lg:text-justify lg:text-3xl"
		>
			{post.title}
		</h1>

		<div
			class="flex w-full flex-col items-center justify-center sm:space-y-32 lg:flex lg:flex-row lg:items-start lg:justify-between lg:space-y-0"
		>
			<div
				id="default-carousel"
				class="my-3 w-full rounded-lg sm:h-[500px] sm:w-[500px] lg:h-[600px] lg:w-[600px]"
				data-carousel="slide"
			>
				<Carousel images={post.images} />

				<!-- Description Box -->
				<div
					class="relative mt-5 rounded-lg border border-gray-200 bg-white px-6 pb-10 pt-6 shadow sm:my-5"
				>
					<h5 class="mb-2 text-xl font-semibold text-gray-900 lg:text-2xl">Description</h5>

					<p
						class="{isOpen
							? ''
							: 'line-clamp-2'} break-word text-sm font-normal text-gray-700 lg:min-h-[2.5rem] lg:text-base"
						bind:this={desc}
					>
						{post.content}
					</p>

					<button
						class="absolute bottom-0 right-0 px-6 py-1 text-2xl"
						on:click={toggle}
						aria-expanded={isOpen}
						class:hidden={!isEllipsisActive(desc)}
					>
						{#if isOpen}
							<i class="fa-solid fa-caret-up text-black"></i>
						{:else}
							<i class="fa-solid fa-caret-down text-black"></i>
						{/if}
					</button>
					<!-- <button class="text-2xl absolute bottom-0 right-0 py-3 px-6"> <i class="fa-solid fa-caret-up text-black"></i> </button> -->
				</div>
			</div>

			<div class="w-full py-1 sm:w-[525px] sm:p-4 sm:py-4 lg:ml-10 lg:w-full lg:p-0">
				<p class="mb-7 text-xl font-semibold text-blue-600 md:mt-1 lg:my-3 lg:text-3xl">
					CA ${post.price.toFixed(2)}
				</p>

				<!-- Google Maps Embed -->
				<!-- svelte-ignore a11y-missing-attribute -->
				<iframe
					src={`https://www.google.com/maps/embed/v1/place?key=AIzaSyBb63wnxcNQtMa_H3ZNmUShN-aD62Gp5yQ&q=${post.location}`}
					width="600"
					height="450"
					style="border:0;"
					allowfullscreen={false}
					loading="lazy"
					referrerpolicy="no-referrer-when-downgrade"
					class="h-[250px] w-full rounded-lg border border-gray-200 bg-white shadow"
				>
				</iframe>

				<h2 class="mb-5 mt-3 text-base font-semibold text-gray-900 lg:text-lg">
					Location: {post.location}
				</h2>

				<!-- Poster Information Box -->
				<div class="mb-5 mt-7 rounded-lg border border-gray-200 bg-white p-6 shadow lg:mt-8">
					<h2 class="text-lg font-semibold text-gray-900 lg:text-2xl">Poster Information</h2>

					<!-- User Avatar and Name -->
					<div class="mb-3 mt-4 flex">
						<Pfp email={post.email} class="h-10 w-10 rounded-lg lg:h-14 lg:w-14" />
						<p class="content-center px-4 text-base font-semibold text-gray-900 lg:text-lg">
							{post.email}
						</p>
					</div>

					<!-- Contact Button -->
					<button
						class="my-2.5 w-full rounded-lg bg-blue-600 p-3 text-sm font-semibold text-white transition duration-100 ease-in-out hover:bg-blue-700"
						on:click={() => {
							startChat(post.user_id, post.id.toString());
						}}
					>
						Contact
						<i class="fa-solid fa-message mx-2"></i>
					</button>
				</div>

				<!-- Policies Box -->
				<div
					class="my-3 rounded-lg border border-gray-200 bg-white p-6 shadow lg:min-h-[3rem] lg:pb-8"
				>
					<h2 class="mb-2 text-lg font-semibold text-gray-900 lg:text-2xl">Marketplace Policies</h2>
					<li class="text-sm font-normal text-gray-700 lg:text-base">All sales are final</li>
					<li class="text-sm font-normal text-gray-700 lg:text-base">No refunds or exchanges</li>
				</div>
			</div>
		</div>
	</div>
{:else}
	<div class="flex flex-1 items-center justify-center">
		<div class="flex flex-col items-center justify-center gap-2 rounded-md bg-white p-20 shadow-lg">
			<div
				class="flex h-5 w-5 items-center justify-center rounded-full border-2 border-solid border-red-500 p-5"
			>
				<i class="fa-solid fa-x fa-lg text-red-500"></i>
			</div>
			<p class="text-2xl text-red-500">Post {post_id} does not exist!</p>
		</div>
	</div>
{/if}

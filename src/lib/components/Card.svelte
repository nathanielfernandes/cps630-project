<script lang="ts">
	import { clickOutside } from '$lib/clickOutside';
	import { createEventDispatcher } from 'svelte';
	import Pfp from './Pfp.svelte';
	import { startChat } from '$lib/chatter/stores';

	interface Image {
		link: string;
		alt_text: string;
	}
	export let id: number;
	export let title: string;
	$: formattedTitle = title.length > 25 ? title.substring(0, 25) + '...' : title;
	export let description: string;
	export let date: string;
	export let price: number;
	export let images: Image[];
	export let user: string;
	export let email: string;
	export let showActions: boolean = false;
	export let showContactButton: boolean = true;

	let showActionsDropdown = false;
	$: showActionsDropdown = showActions ? showActionsDropdown : false;

	let _ = date;

	$: image_link =
		images.length > 0
			? images[0].link
			: 'https://www.fivebranches.edu/wp-content/uploads/2021/08/default-image.jpg';

	const editDispatch = createEventDispatcher<{ editButtonClick: { id: number; title: string } }>();
	const deleteDispatch = createEventDispatcher<{
		deleteButtonClick: { id: number; title: string };
	}>();
	const handleEdit = (e: Event) => {
		e.preventDefault();
		e.stopPropagation();
		editDispatch('editButtonClick', { id, title });
	};
	const handleDelete = (e: Event) => {
		e.preventDefault();
		e.stopPropagation();
		deleteDispatch('deleteButtonClick', { id, title });
        showActionsDropdown = false;
	};
</script>

<div
    use:clickOutside
    on:click_outside={() => showActionsDropdown = false}
	class="w-[300px] place-self-center rounded-lg bg-white shadow-lg transition duration-200 ease-in-out lg:hover:scale-105"
>
	<a href="/dashboard/listings/posts/{id}">
		<div class="relative h-[250px] w-[300px] rounded-t-lg">
			<img src={image_link} alt={title} class="h-[250px] w-[300px] rounded-t-lg object-cover" />
			<div
				class="absolute bottom-3 left-3 flex items-center space-x-2 rounded-lg bg-white bg-opacity-70 p-2"
			>
				<Pfp {email} class="h-6 w-6 rounded-md" />
				<p class="truncate pr-1 text-xs font-medium text-gray-900">{email}</p>
			</div>
		</div>

		<div class="relative p-5">
			{#if showActions}
				<div class="absolute right-2 top-2">
					<button
						id="dropdownMenuIconHorizontalButton"
						data-dropdown-toggle="dropdownDotsHorizontal"
						class="inline-flex items-center rounded-lg bg-white p-2 text-center text-sm font-medium text-gray-900 hover:bg-gray-100 focus:outline-none focus:ring-4 focus:ring-gray-50 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700 dark:focus:ring-gray-600"
						type="button"
						on:click={(e) => {
							e.stopPropagation();
							e.preventDefault();
							showActionsDropdown = !showActionsDropdown;
						}}
					>
						<svg
							class="h-4 w-4"
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

			<h2 class="mb-2 line-clamp-1 text-xl font-medium text-gray-900">
				{formattedTitle}
			</h2>

			<p class="mb-4 line-clamp-2 break-words min-h-10 text-sm font-normal text-gray-700">
				{description}
			</p>

			<div class="flex items-center justify-between">
				<p class="text-sm font-medium text-gray-700">${price.toFixed(2)}</p>
				<button
					disabled={!showContactButton}
					on:click={() => {
						startChat(user, id.toString());
					}}
					class="rounded-lg bg-blue-600 px-3 py-1.5 text-sm font-normal text-white hover:enabled:bg-blue-700 disabled:opacity-50"
				>
					Contact
					<i class="fa-solid fa-message ml-2"></i>
				</button>
			</div>
		</div>
	</a>
</div>

<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import Pfp from './Pfp.svelte';
	import { startChat } from '$lib/chatter/stores';

	interface Image {
		link: string;
		alt_text: string;
	}
	export let id: number;
	export let title: string;
	export let description: string;
	export let date: string;
	export let price: number;
	export let images: Image[];
	export let user: string;
	export let email: string;
	export let showContactButton: boolean = true;

	let _ = date;

	$: image_link =
		images.length > 0
			? images[0].link
			: 'https://www.fivebranches.edu/wp-content/uploads/2021/08/default-image.jpg';

	
</script>

<div class="w-[300px] place-self-center rounded-lg bg-white shadow-lg transition duration-200 ease-in-out lg:hover:scale-105">
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

		<div class="p-5">
			<h2 class="mb-2 line-clamp-1 text-xl font-medium text-gray-900">
				{title}
			</h2>

			<p class="mb-4 line-clamp-2 min-h-10 text-sm font-normal text-gray-700">
				{description}
			</p>

			<div class="flex items-center justify-between">
				<p class="text-sm font-medium text-gray-700">${price.toFixed(2)}</p>
					<button
					disabled={!showContactButton}
						on:click={() => {
							startChat(user, `Product Inquiry - ${title}`);
						}}
						class="rounded-lg bg-blue-600 px-3 py-1.5 text-sm font-normal text-white hover:enabled:bg-blue-700  disabled:opacity-50"
					>
						Contact
						<i class="fa-solid fa-message ml-2"></i>
					</button>
			</div>
		</div>
	</a>
</div>

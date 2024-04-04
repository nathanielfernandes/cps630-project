<script lang="ts">
	import { onDestroy } from 'svelte';
	import { posts, type Post, user_info, type UserInfo } from '$lib/stores';

	export let table: string;
	export let type: string;
	let allPosts: Post[] = [];
	let allUsers: UserInfo[] = [];
	let cols: string[] = [];

	$: {
		const unsubscribeUsers = user_info.subscribe(($user_info) => {
			if (table === 'user_info') {
				allUsers = Object.values($user_info);
				cols = allUsers.length > 0 ? Object.keys(allUsers[0]) : [];
			}
		});
		console.log(allUsers);

		onDestroy(unsubscribeUsers);
	}

	$: {
		const unsubscribe = posts.subscribe(($posts) => {
			// Filter posts based on the current `type`
			allPosts =
				type !== ''
					? Object.values($posts).filter((post) => post.type === type)
					: Object.values($posts);

			// Update columns based on the new set of posts
			cols = allPosts.length > 0 ? Object.keys(allPosts[0]) : [];
		});

		onDestroy(unsubscribe);
	}
	function truncate(text: string, length: number): string {
		return text.length > length ? `${text.substring(0, length)}...` : text;
	}
</script>

<div class="relative overflow-x-auto shadow-md sm:rounded-lg">
	<table class="w-full text-left text-sm text-gray-500 rtl:text-right">
		<caption class="bg-white p-5 text-left text-lg font-semibold text-gray-900 rtl:text-right">
			{type === ''
				? 'All Listings'
				: type === 'items_for_sale'
					? 'Items for Sale'
					: type === 'items_wanted'
						? 'Items Wanted'
						: 'Academic Services'}

			<p class="mt-1 text-sm font-normal text-gray-500">
				{allPosts.length}
				{type === '' ? 'listings' : type}
			</p>
		</caption>
		<thead class="bg-gray-50 text-xs uppercase text-gray-700">
			<tr>
				{#each cols as col}
					<th scope="col" class="px-6 py-3">{col}</th>
				{/each}
				<th scope="col" class="px-6 py-4">Edit</th>
			</tr>
		</thead>
		<tbody>
			{#if table === 'user_info'}
				{#each allUsers as user}
					<tr class="border-b bg-white">
						{#each cols as col}
							<td class="px-6 py-4">{user[col].toString()}</td>
						{/each}
						<td class="px-6 py-4 text-left">
							<a href="#" class="font-medium text-blue-600 hover:underline">Edit</a>
						</td>
					</tr>
				{/each}
			{:else}
				{#each allPosts as post}
					<tr class="border-b bg-white">
						{#each cols as col}
							<td class="px-6 py-4">{truncate(post[col].toString(), 50)}</td>
						{/each}
						<td class="px-6 py-4 text-center">
							<a href="#" class="font-medium text-blue-600 hover:underline">Edit</a>
						</td>
					</tr>
				{/each}
			{/if}
		</tbody>
	</table>
</div>

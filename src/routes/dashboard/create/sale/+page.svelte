<script lang="ts">
	import { base } from './../../../../../.svelte-kit/adapter-node/manifest.js';
	import Card from '$lib/components/Card.svelte';
	import ImageUpload from '$lib/components/ImageUpload.svelte';
	import { atRule } from 'postcss';

	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);

	let title = '';
	let content = '';
	let price = '';
	let userId = session ? session.user.id : '';

	let images: ImageFile[] = [];

	const ad = {
		id: 1,
		title: 'MTH 140 Textbook',
		description: 'I am looking for Calculus: Early Transcendentals by James Stewart.',
		date: '2024-01-02',
		price: 0,
		profile_image: '',
		images: ['https://source.unsplash.com/random/350x250?textbook&cb=1'],
		user: 'David Smith'
	};
</script>

<div class="flex flex-1 justify-center overflow-hidden">
	<div class="flex max-w-screen-2xl flex-1">
		<div
			class="w-full overflow-y-auto bg-white p-3 text-black shadow-lg md:max-w-[40%] lg:max-w-[30%]"
		>
			<form>
				<div class="mb-6 grid gap-6 md:grid-cols-1">
					<div>
						<label
							for="first_name"
							class="mb-2 block text-sm font-medium text-gray-900 dark:text-white">Photos*</label
						>
						<ImageUpload bind:images />
					</div>
					<div>
						<label for="title" class="mb-2 block text-sm font-medium text-gray-900 dark:text-white"
							>Title*</label
						>
						<input
                            bind:value={title}
							type="text"
							id="title"
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
							placeholder="Post title"
							required
						/>
					</div>
					<div>
						<label
							for="content"
							class="mb-2 block text-sm font-medium text-gray-900 dark:text-white">Content*</label
						>
						<textarea
							id="content"
							bind:value={content}
							rows="4"
							class="block w-full min-h-10 rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
							placeholder="Post Content"
							required
						></textarea>
					</div>
					<div>
						<label for="price" class="mb-2 block text-sm font-medium text-gray-900 dark:text-white"
							>Price*</label
						>
						<input
							type="number"
							id="price"
							bind:value={price}
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
							placeholder="Sale Price"
							required
						/>
					</div>
					<div class="mb-5 flex items-start">
						<div class="flex h-5 items-center">
							<input
								id="terms"
								type="checkbox"
								value=""
								class="focus:ring-3 h-4 w-4 rounded border border-gray-300 bg-gray-50 focus:ring-blue-300 dark:border-gray-600 dark:bg-gray-700 dark:ring-offset-gray-800 dark:focus:ring-blue-600"
								required
							/>
						</div>
						<label for="terms" class="ms-2 text-sm font-medium text-gray-900 dark:text-gray-300"
							>I agree with the <a href="#" class="text-blue-600 hover:underline dark:text-blue-500"
								>terms and conditions</a
							>.</label
						>
					</div>
					<button
						type="submit"
						class="w-full rounded-lg bg-blue-700 px-5 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 sm:w-auto dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
						>Submit</button
					>
				</div>
			</form>
		</div>
		<div class="hidden flex-1 items-center justify-center md:flex">
			<Card
				title={title || "Post Title"}
				description={content || "Post Content"}
				date={Date.now().toLocaleString()}
				price={parseFloat(price) || 5}
				profile_image={ad.profile_image}
				images={images.length > 0 && images[0].url
					? [images[0].url]
					: ['https://source.unsplash.com/random/350x250?textbook&cb=1']}
				user={userId}
			/>
		</div>
	</div>
</div>

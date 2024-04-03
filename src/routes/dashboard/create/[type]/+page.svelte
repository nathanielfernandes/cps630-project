<script lang="ts">
	import { successAlert, errorAlert } from '$lib/Alerts/stores.js';
	import Card from '$lib/components/Card.svelte';
	import ImageUpload from '$lib/components/ImageUpload.svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);

	const IMAGE_URL_PREFIX =
		'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/';

	let type = $page.params.type;
	let title = '';
	let content = '';
	let price = '';
	let location = '';
	let user_id = session ? session.user.id : '';
	let email = (session ? session.user.email : '') as string;
	let images: ImageFile[] = [];

	const insertPost = async () => {
		let { data: postData, error } = await supabase
			.from('posts')
			.insert([
				{
					title,
					content,
					price,
					location,
					type,
					user_id
				}
			])
			.select()
			.single();

		if (error) {
			console.error(error);
			return;
		}

		return postData;
	};

	const uploadImage = async (imageFile: File) => {
		const random_value = Math.floor(Math.random() * 1000000000);
		console.log('uploading', `uploads/${user_id}/${random_value}_${imageFile.name}`);
		const { data, error } = await supabase.storage
			.from('images')
			.upload(`uploads/${user_id}/${random_value}_${imageFile.name}`, imageFile);

		if (error) {
			console.error(error);
			return;
		}
		const imageUrl = IMAGE_URL_PREFIX + encodeURIComponent(data.path);
		return imageUrl;
	};

	const insertImages = async (post_id: string, imageUrls: string[]) => {
		let { error } = await supabase.from('images').insert(
			imageUrls.map((imageUrl) => {
				return {
					post_id,
					link: imageUrl,
					alt_text: 'placeholder'
				};
			})
		);

		if (error) {
			console.error(error);
		}
	};

	const handleSubmit = async () => {
		// Upload images
		let imageUrls: string[] = [];
		if (images.length > 0) {
			const promises = images.map((image) => {
				if (image.file) {
					return uploadImage(image.file);
				}
			});

			const result = await Promise.all(promises);
			if (result.findIndex((url) => url === null || url === undefined) != -1) {
				errorAlert('Image upload failed, please try again later.');
				return;
			}
			imageUrls = result as string[];
		}

		// Create post
		const postData = await insertPost();
		if (!postData) {
			errorAlert('Failed to create Ad post.');
			return;
		}

		// Insert uploaded images into post
		if (imageUrls.length > 0) {
			await insertImages(postData.id, imageUrls);
		}

		successAlert('Your Ad has been posted!');
		goto(`/dashboard/listings/posts/${postData.id}`);
	};

	onMount(() => {
		if (type !== 'items_wanted' && type !== 'items_for_sale' && type !== 'academic_services') {
			goto('/dashboard/create');
		}
	});
</script>

<div class="flex min-h-[75vh] flex-1 justify-center overflow-hidden">
	<div class="flex max-w-screen-2xl flex-1">
		<div
			class="w-full overflow-y-auto bg-white p-3 text-black shadow-lg md:max-w-[40%] lg:max-w-[30%]"
		>
			<form on:submit|preventDefault={handleSubmit}>
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
							maxlength="255"
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
							class="block min-h-10 w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
							placeholder="Post Content"
							maxlength="255"
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
					<div>
						<label
							for="location"
							class="mb-2 block text-sm font-medium text-gray-900 dark:text-white">Location*</label
						>
						<input
							bind:value={location}
							type="text"
							id="location"
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
							placeholder="Postal Code"
							maxlength="255"
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
							>I agree with the <a
								href="https://www.torontomu.ca/terms-conditions/"
								class="text-blue-600 hover:underline dark:text-blue-500">terms and conditions</a
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
				id={-1}
				title={title || 'Post Title'}
				description={content || 'Post Content'}
				date={Date.now().toLocaleString()}
				price={parseFloat(price) || 5}
				images={images.length > 0 && images[0].url
					? [{ link: images[0].url, alt_text: title }]
					: []}
				user={user_id}
				{email}
				showContactButton={false}
			/>
		</div>
	</div>
</div>

<script lang="ts">
	import { successAlert, errorAlert } from '$lib/Alerts/stores.js';
	import Card from '$lib/components/Card.svelte';
	import ImageUpload from '$lib/components/ImageUpload.svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	export let data;
	let { supabase, session } = data;
	$: ({ supabase } = data);

	const IMAGE_URL_PREFIX =
		'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/';

	let post_id = $page.params.post_id;
	let title = '';
	let content = '';
	let price = '';
    let location = '';
	let user_id = session ? session.user.id : '';
	let email = (session ? session.user.email : '') as string;
    let prevImages: any[] = [];
	let images: ImageFile[] = [];

	const fetchPost = async () => {
		let { data: postData, error: postError } = await supabase
			.from('posts')
			.select()
			.eq('id', post_id)
			.single();
		if (postError) {
			console.error(postError);
			throw postError;
		}
        //@ts-ignore
		({ title, content, price, location, user_id, email } = postData);

		let { data: imageData, error: imageError } = await supabase
			.from('images')
			.select()
			.eq('post_id', post_id);
		if (imageError) {
			console.error(imageError);
			throw imageError;
		}

		if (imageData) {
            prevImages = imageData;
			const promises = imageData.map(async (d) => {
				const imageUrl = d.link;
				const image: ImageFile = { file: null, url: imageUrl, isLoaded: false };
				images.push(image);
				images = images;

				// Load image from web page
				const response = await fetch(imageUrl);
				const data = await response.blob();
				const fileName = decodeURIComponent(d.link).split("/").pop()?.split("_").pop();

				image.file = new File([data], fileName || 'product.jpeg', {
					type: data.type || 'image/jpeg'
				});
				image.isLoaded = true;
				images = images;
			});

            const results = await Promise.all(promises.map(p => p.catch(e => e)));
            const errorIndex = results.findIndex((result) => result instanceof Error);
            if (errorIndex != -1) {
                console.error(results[errorIndex]);
                throw results[errorIndex];
            }
		}
	};

	const updatePost = async () => {
		let { data: postData, error } = await supabase
			.from('posts')
			.update([
				{
					title,
					content,
					price,
                    location
				}
			])
			.eq('id', post_id)
			.select()
			.single();

		if (error) {
			console.error(error);
			return;
		}

		return postData;
	};

	const uploadImage = async (imageFile: File) => {
		const random_value = Math.floor(Math.random() * 1000000000000);
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
        // Remove previous images
        let response = await supabase.from('images').delete().eq('post_id', post_id).select();
        if (response.error) {
            console.error(response.error);
            errorAlert("Failed to update post.");
            return;
        }
        //@ts-ignore
        const imagePaths = prevImages.map((image) => decodeURIComponent(image.link.replace(IMAGE_URL_PREFIX, "")));
        supabase.storage.from("images").remove(imagePaths);

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

        // Update post
        const postData = await updatePost();
        if (!postData) {
            errorAlert('Failed to update post.');
			return;
        }
        
        // Insert uploaded images into post
        if (imageUrls.length > 0) {
			await insertImages(postData.id, imageUrls);
		}

		successAlert('Your post has been updated!');
        goto(`/dashboard/listings/posts/${postData.id}`);
	};
</script>

{#await fetchPost()}
	<div class="fixed left-1/2 top-1/2">
		<i class="fa-solid fa-spinner animate-spin text-3xl text-slate-900"></i>
	</div>
{:then}
	<div class="flex flex-1 justify-center overflow-hidden">
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
							<label
								for="title"
								class="mb-2 block text-sm font-medium text-gray-900 dark:text-white">Title*</label
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
							<label
								for="price"
								class="mb-2 block text-sm font-medium text-gray-900 dark:text-white">Price*</label
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
									href="#"
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
					id={parseInt(post_id)}
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
{:catch error}
	<div class="flex flex-1 items-center justify-center">
		<div class="flex flex-col items-center justify-center gap-2 rounded-md bg-white p-20 shadow-lg">
			<div
				class="flex h-5 w-5 items-center justify-center rounded-full border-2 border-solid border-red-500 p-5"
			>
				<i class="fa-solid fa-x fa-lg text-red-500"></i>
			</div>
			<p class="text-2xl text-red-500">Failed to load post!</p>
		</div>
	</div>
{/await}

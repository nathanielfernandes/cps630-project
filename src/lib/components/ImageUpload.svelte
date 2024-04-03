<script lang="ts">
	import type { ChangeEventHandler } from "svelte/elements";

    export let images: ImageFile[] = [];
	export let id = 'file-upload';
	export let maxImages = 5;

	let fileInput: HTMLInputElement;
	const openFileExplorerOnClick = (event: MouseEvent) => {
		event.stopPropagation();
		fileInput?.click();
	};
	const openFileExplorerOnKeydown = (event: KeyboardEvent) => {
		event.stopPropagation();
		if (event.key === 'Enter' || event.key === ' ') {
			fileInput?.click();
		}
	};

	const handleFilesSelection: ChangeEventHandler<HTMLInputElement> = (event: Event & { currentTarget: EventTarget & HTMLInputElement; }) => {
        const fileInput: HTMLInputElement = event.currentTarget;
		if (!fileInput || !fileInput.files) {
			return;
		}

		for (let i = 0; i < fileInput.files.length; i++) {
			const file = fileInput.files[i];
			const image: ImageFile = { file: file, url: null, isLoaded: false };
			images.push(image);
			images = images;

			// Read the image file and get the url
			const reader = new FileReader();
			reader.onload = function () {
				if (reader.result && typeof reader.result === 'string') {
					image.url = reader.result;
					image.isLoaded = true;
					images = images;
				}
			};
			reader.readAsDataURL(file);
		}
	};

	const imageRegex = /src="?([^"\s]+)"?\s*/;
	let draggedContent: boolean = false;
	let draggedImage: ImageFile | undefined;
	const handleContentDragover = (event: DragEvent) => {
		event.preventDefault();
		if (draggedImage !== undefined) {
			return;
		}
		draggedContent = true;
	};
	const handleContentDragleave = (event: DragEvent) => {
		event.preventDefault();
		event.stopPropagation();
		if (draggedImage !== undefined) {
			return;
		}
		draggedContent = false;
	};
	const handleContentDrop = async (event: DragEvent) => {
		event.preventDefault();
		if (draggedImage !== undefined) {
			draggedImage = undefined;
			return;
		}
		draggedContent = false;

		if (event.dataTransfer) {
			[...event.dataTransfer.items].forEach(async (item, i) => {
				if (item.kind === 'file' && item.type.match('image.*')) {
					// Image dropped
					const file = item.getAsFile();
					if (file) {
						const image: ImageFile = { file: file, url: null, isLoaded: false };
						images.push(image);
						images = images;

						// Read the image file and get the url
						const reader = new FileReader();
						reader.onload = function () {
							if (reader.result && typeof reader.result === 'string') {
								image.url = reader.result;
								image.isLoaded = true;
								images = images;
							}
						};
						reader.readAsDataURL(file);
					}
				} else if (item.type === 'text/html') {
					// Image dropped, but it came from a web page
					const html = event.dataTransfer.getData('text/html');
					const result = imageRegex.exec(html);
					if (result) {
						const imageUrl = result[1];
						const image: ImageFile = { file: null, url: imageUrl, isLoaded: false };
						images.push(image);
						images = images;

						// Load image from web page
						const response = await fetch(imageUrl);
						const data = await response.blob();
						const fileName =
							response.headers.get('Content-Type')?.split('/')[1] ||
							imageUrl.split('#')[0].split('?')[0].split('/').pop();

						image.file = new File([data], fileName || 'product.jpg', {
							type: data.type || 'image/jpeg'
						});
						image.isLoaded = true;
						images = images;
					}
				}
			});
		}
	};

	const handleDeleteImageClick = (event: MouseEvent, image: ImageFile) => {
		event.stopPropagation();
		images = images.filter((i) => i !== image);
	};

	const handleRearrangeImageDragstart = (event: DragEvent, image: ImageFile) => {
		event.stopPropagation();
		draggedImage = image;
	};
	const handleRearrangeImageDragend = (event: DragEvent, image: ImageFile) => {
		event.stopPropagation();
		draggedImage = undefined;
	};
	const handleRearrangeImageDrop = (event: DragEvent, dropTargetImage: ImageFile) => {
		event.stopPropagation();
        if (draggedContent) {
            handleContentDrop(event);
        } else if (draggedImage) {
			const index1 = images.findIndex((i) => i === draggedImage);
			const index2 = images.findIndex((i) => i === dropTargetImage);
			images[index1] = dropTargetImage;
			images[index2] = draggedImage;
			images = images;
			draggedImage = undefined;
		}
	};
</script>

<div
	role="button"
	tabindex="0"
	class="relative flex min-h-24 flex-col"
	on:click={openFileExplorerOnClick}
	on:keydown={openFileExplorerOnKeydown}
	on:drop={handleContentDrop}
	on:dragover={handleContentDragover}
	on:dragleave={handleContentDragleave}
>
	<div
		class:opacity-100={draggedContent}
		class:opacity-0={!draggedContent}
		class="pointer-events-none absolute z-10 flex h-full w-full flex-col items-center justify-center gap-3 border-4 border-dashed border-gray-400 bg-white/90 p-5"
	>
		<span class="pointer-events-none text-black"><strong>Drop photos here...</strong></span>
	</div>
	<input
        name={id}
		bind:this={fileInput}
		on:change={handleFilesSelection}
		class="invisible h-0 w-0"
		{id}
		type="file"
		accept="image/*"
		multiple
	/>
	{#if images.length === 0}
		<div
			role="button"
			tabindex="0"
			class="flex flex-col items-center justify-center gap-3 border-2 border-dashed border-gray-400 bg-gray-100 p-5 text-sm"
			on:click={openFileExplorerOnClick}
			on:keydown={openFileExplorerOnKeydown}
		>
			<div>
				<span class="sr-only">Open File Explorer</span>
				<img aria-hidden="true" class="w-12" src="/cloud.png" alt="Cloud" />
			</div>
			<div class="text-center">
				<span class="text-gray-400"
					>Maximum size for a file is 5 MB; formats: .jpg, .jpeg, .png, .gif</span
				>
			</div>
			<div class="text-center">
				<span>The first photo is the thumbnail. Drag photo to reorder.</span>
			</div>
		</div>
	{:else}
		<div class="flex flex-row flex-wrap gap-3">
			{#each images as image}
				{#if image.isLoaded}
					<div
						role="img"
						class="relative flex h-32 w-32 cursor-move items-center justify-center overflow-hidden rounded-md bg-gray-200"
						draggable={true}
						on:dragstart={(e) => handleRearrangeImageDragstart(e, image)}
						on:drop={(e) => handleRearrangeImageDrop(e, image)}
						on:dragend={(e) => handleRearrangeImageDragend(e, image)}
					>
						<div
							aria-hidden="true"
							class="absolute z-10 h-full w-full bg-black/40 opacity-0 hover:opacity-100"
						></div>
						<img class="h-full w-full object-cover" src={image.url} alt="Product" />
						<button
							type="button"
							on:click={(e) => handleDeleteImageClick(e, image)}
							class="absolute right-0 top-0 z-10 flex aspect-square -translate-x-2 translate-y-2 items-center justify-center rounded-full bg-gray-100 p-2 hover:bg-gray-300"
						>
							<span class="sr-only">Delete Photo</span>
							<i class="fa-solid fa-x fa-xs"></i>
						</button>
					</div>
				{:else}
					<div
						class="flex h-32 w-32 items-center justify-center rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800"
						draggable={false}
					>
						<div role="status">
							<svg
								aria-hidden="true"
								class="h-8 w-8 animate-spin fill-blue-600 text-gray-200 dark:text-gray-600"
								viewBox="0 0 100 101"
								fill="none"
								xmlns="http://www.w3.org/2000/svg"
								><path
									d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
									fill="currentColor"
								/><path
									d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
									fill="currentFill"
								/></svg
							>
							<span class="sr-only">Photo Loading...</span>
						</div>
					</div>
				{/if}
			{/each}
			<button
				type="button"
				on:click={openFileExplorerOnClick}
				class="relative flex h-32 w-32 flex-col items-center justify-center gap-2 overflow-hidden rounded-md bg-gray-200 text-gray-500 hover:bg-gray-300"
			>
				<div>
					<i class="fa-regular fa-images fa-lg"></i>
				</div>
				<div>
					<span class="pointer-events-none">Add Photo</span>
				</div>
			</button>
		</div>
	{/if}
</div>

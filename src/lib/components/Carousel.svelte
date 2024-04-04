<script lang="ts">
	interface Image {
		link: string;
		alt_text: string;
	}

	const DEFAULT_IMAGE = "https://www.fivebranches.edu/wp-content/uploads/2021/08/default-image.jpg";

	export let images: Image[];
	$: images =
		images.length > 0
			? images
			: [
					{
						link: DEFAULT_IMAGE,
						alt_text: 'Placeholder'
					}
				];

	$: show_btns = images.length > 1;

	let slide = 0;
	function next() {
		slide = (slide + 1) % images.length;
	}
	function prev() {
		slide = (slide - 1 + images.length) % images.length;
	}
	function select(idx: number) {
		slide = idx;
	}
</script>

<!-- Carousel wrapper -->
<div
	class="relative aspect-square w-full overflow-hidden rounded-lg border border-gray-200 shadow sm:h-[500px] sm:w-[500px] lg:h-[600px] lg:w-[600px]"
>
	<!-- Item 1 -->
	{#each images as image, idx}
		<div class="duration-700 ease-in-out" data-carousel-item class:hidden={idx !== slide}>
			<img
				src={image.link}
				class="aspect-square w-full rounded-lg object-cover sm:h-[500px] sm:w-[500px] lg:h-[600px] lg:w-[600px]"
				alt={image.alt_text}
				on:error={(e) => {
					//@ts-ignore
					e.target.src = DEFAULT_IMAGE;
				}}
			/>
		</div>
	{/each}

	<!-- Slider indicators -->
	<div
		class="absolute bottom-5 left-1/2 z-30 flex -translate-x-1/2 transform space-x-3 rtl:space-x-reverse"
		class:hidden={!show_btns}
	>
		{#each images as _, i}
			<button
				type="button"
				class="h-3 w-3 rounded-full bg-white {i === slide ? '' : 'opacity-45'} shadow-md"
				on:click={() => select(i)}
			></button>
		{/each}
	</div>

	<!-- Slider controls -->
	<button
		type="button"
		class="group absolute start-0 top-0 z-30 flex h-full cursor-pointer items-center justify-center px-4 focus:outline-none"
		data-carousel-prev
		class:hidden={!show_btns}
		on:click={prev}
	>
		<span
			class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/30 group-hover:bg-white/50 group-focus:outline-none group-focus:ring-4 group-focus:ring-white"
		>
			<svg
				class="h-4 w-4 text-white rtl:rotate-180"
				aria-hidden="true"
				xmlns="http://www.w3.org/2000/svg"
				fill="none"
				viewBox="0 0 6 10"
			>
				<path
					stroke="currentColor"
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="M5 1 1 5l4 4"
				/>
			</svg>
			<span class="sr-only">Previous</span>
		</span>
	</button>

	<button
		type="button"
		class="group absolute end-0 top-0 z-30 flex h-full cursor-pointer items-center justify-center px-4 focus:outline-none"
		data-carousel-next
		class:hidden={!show_btns}
		on:click={next}
	>
		<span
			class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/30 group-hover:bg-white/50 group-focus:outline-none group-focus:ring-4 group-focus:ring-white"
		>
			<svg
				class="h-4 w-4 text-white rtl:rotate-180"
				aria-hidden="true"
				xmlns="http://www.w3.org/2000/svg"
				fill="none"
				viewBox="0 0 6 10"
			>
				<path
					stroke="currentColor"
					stroke-linecap="round"
					stroke-linejoin="round"
					stroke-width="2"
					d="m1 9 4-4-4-4"
				/>
			</svg>
			<span class="sr-only">Next</span>
		</span>
	</button>
</div>

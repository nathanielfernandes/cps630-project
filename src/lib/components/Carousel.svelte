<script lang="ts">
    export let images: string[];

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
<div class="relative overflow-hidden rounded-lg w-full aspect-square border border-gray-200 shadow sm:w-[500px] sm:h-[500px] lg:w-[600px] lg:h-[600px]">
    <!-- Item 1 -->
    {#each images as image, idx}
        <div class="duration-700 ease-in-out" data-carousel-item class:hidden={idx !== slide}>
            <img src={image} class="w-full aspect-square rounded-lg sm:w-[500px] sm:h-[500px] lg:w-[600px] lg:h-[600px]" alt="...">
        </div>
    {/each}

    <!-- Slider indicators -->
    <div class="absolute bottom-5 z-30 left-1/2 transform -translate-x-1/2 flex space-x-3 rtl:space-x-reverse">
        {#each images as _, i}
            <button type="button" class="w-3 h-3 bg-white rounded-full {i === slide ? '' : 'opacity-45'} shadow-md" on:click={() => select(i)}></button>
        {/each}
    </div>

    <!-- Slider controls -->
    <button type="button" class="absolute top-0 start-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none" data-carousel-prev on:click={prev}>
        <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 group-hover:bg-white/50  group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
            <svg class="w-4 h-4 text-white rtl:rotate-180" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
                <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 1 1 5l4 4"/>
            </svg>
            <span class="sr-only">Previous</span>
        </span>
    </button>

    <button type="button" class="absolute top-0 end-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none" data-carousel-next on:click={next}>
        <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 group-hover:bg-white/50  group-focus:ring-4 group-focus:ring-white  group-focus:outline-none">
            <svg class="w-4 h-4 text-white rtl:rotate-180" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
                <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 9 4-4-4-4"/>
            </svg>
            <span class="sr-only">Next</span>
        </span>
    </button>

</div>
<script lang="ts">
    import Carousel from '$lib/components/Carousel.svelte';
    import type { PageData } from "../$types";

    let isOpen = false;
    const toggle = () => (isOpen = !isOpen);
    let desc: HTMLParagraphElement;

    export let data: PageData;
    const d: any = data as any;

    
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

    export let images = [
        "https://source.unsplash.com/random/600x600?graduation,gownk&cb=1",
        "https://source.unsplash.com/random/600x600?graduation,gown&cb=2",
        "https://source.unsplash.com/random/600x600?graduation,gown&cb=3"        
    ];

</script>


<div class="mx-auto w-full max-w-screen-xl px-4 py-7 font-normal">

    <button class="bg-blue-600 text-white px-3.5 py-2.5 rounded-lg text-sm font-semibold hover:bg-blue-700 mb-4 transition duration-100 ease-in-out">
        <i class="fa-solid fa-arrow-left pr-2"></i>
        <a href="/dashboard/sale">Back</a>
    </button>

    <h1 class="text-black text-xl font-semibold text-center lg:text-3xl lg:text-justify lg:max-w-[600px]">Graduation Cap and Gown</h1>

    <div class="flex flex-col w-full sm:space-y-32 justify-center items-center lg:flex lg:flex-row lg:justify-between lg:space-y-0 lg:items-start">
        
        <div id="default-carousel" class="my-3 w-full rounded-lg sm:w-[500px] sm:h-[500px] lg:w-[600px] lg:h-[600px]" data-carousel="slide">

            <Carousel images={images} />

            <!-- Description Box -->
            <div class="mt-5 relative sm:my-5 px-6 pt-6 pb-10 bg-white border border-gray-200 rounded-lg shadow">
                <h5 class="mb-2 text-xl font-semibold text-gray-900 lg:text-2xl">Description</h5>
            
                <p class="{isOpen ? '' : 'line-clamp-2'} font-normal text-gray-700 text-sm lg:text-base lg:min-h-[2.5rem]" bind:this={desc}>
                    Selling a navy blue graduation cap. Size is a men's medium
                </p>

           
                <button class="text-2xl absolute bottom-0 right-0 py-1 px-6" on:click={toggle} aria-expanded={isOpen} class:hidden={!isEllipsisActive(desc)}> 
                    {#if isOpen}
                        <i class="fa-solid fa-caret-up text-black"></i>
                    {:else}
                        <i class="fa-solid fa-caret-down text-black"></i>
                    {/if}
                </button>
                <!-- <button class="text-2xl absolute bottom-0 right-0 py-3 px-6"> <i class="fa-solid fa-caret-up text-black"></i> </button> -->
            </div>

        </div>


        <div class="w-full py-1 sm:py-4 sm:p-4 sm:w-[525px] lg:w-full lg:p-0 lg:ml-10">
            <p class="text-blue-600 text-xl font-semibold mb-7 md:mt-1 lg:text-3xl lg:my-3">CA $250.00</p>

                <!-- Google Maps Embed -->
                <!-- svelte-ignore a11y-missing-attribute -->
                <iframe 
                    src="https://www.google.com/maps/embed/v1/place?key=AIzaSyBb63wnxcNQtMa_H3ZNmUShN-aD62Gp5yQ&q=M4T2T1" width="600" height="450" style="border:0;" allowfullscreen={false} loading="lazy" referrerpolicy="no-referrer-when-downgrade"
                    class="w-full h-[250px] bg-white border border-gray-200 rounded-lg shadow "   
                    >
                </iframe>

            <h2 class="text-base font-semibold mt-3 mb-5 text-gray-900 lg:text-lg">Location: M4T 2T1</h2>

            
            <!-- Poster Information Box -->
            <div class="mt-7 mb-5 p-6 bg-white border border-gray-200 rounded-lg shadow lg:mt-8">

                <h2 class="text-lg font-semibold text-gray-900 lg:text-2xl">Poster Information</h2>
                
                <!-- User Avatar and Name -->
                <div class="flex mt-4 mb-3">
                    <img
                        src="https://api.dicebear.com/8.x/initials/svg?seed=DS"
                        alt="avatar"
                        class="h-10 w-10 rounded-lg lg:h-14 lg:w-14"/>
                    <p class="text-gray-900 text-base font-semibold content-center px-4 lg:text-lg">David Smith</p>
                </div>

                <!-- Contact Button -->
                <button class="w-full bg-blue-600 text-white p-3 rounded-lg text-sm font-semibold hover:bg-blue-700 my-2.5 transition duration-100 ease-in-out">
                    Contact
                    <i class="fa-solid fa-message mx-2"></i>
                </button>

            </div>

            <!-- Policies Box -->
            <div class="my-3 p-6 bg-white border border-gray-200 rounded-lg shadow lg:min-h-[3rem] lg:pb-8">
                <h2 class="text-lg font-semibold text-gray-900 mb-2 lg:text-2xl">Marketplace Policies</h2>
                <li class="text-gray-700 font-normal text-sm lg:text-base">All sales are final</li>
                <li class="text-gray-700 font-normal text-sm lg:text-base">No refunds or exchanges</li>
            </div>

        </div>


    </div>

</div>


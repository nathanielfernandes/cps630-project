<script lang="ts">
	import { ping, startChat } from "$lib/chatter/stores";

	const known_ppl = [
		["nathaniel.s.fernandes@gmail.com", "652630e9-a92f-4c3e-ae7a-b74a6fef939d"],
		["hazafa.tanveer123@gmail.com", "c2446533-f749-445a-a437-b16dc18c2440"],
	];

	let person = known_ppl[0];
	let topic = "";
	function handleClick() {
		startChat(person[1], topic);
	}
</script>


<!-- <div class="text-slate-600 m-4 flex flex-col w-80 space-y-4">
	<h1>Debug Chat Panel</h1>

	{$ping}

	<p>Selected: </p>
	<select bind:value={person}>
		{#each known_ppl as p}
			<option value={p}>{p[0]}</option>
		{/each}
	</select>

	<p>Set Chat Topic: </p>
	<input type="text" bind:value={topic} />

	<button class="bg-green-500 text-white px-4 py-2 rounded-lg" on:click={handleClick}>
		Chat with {person[0]}
	</button>
</div> -->


<div class="flex justify-center items-center mx-auto my-20 h-[600px] w-full max-w-screen bg-white border border-gray-200">

	<!-- <div class="mx-auto w-full border-t-4 border-b-4 border-dashed border-blue-600 m-10 bg-transparent p-10"> -->
	<div class="mx-auto w-full  m-10 bg-transparent p-10">
		<div class="grid grid-cols-2 mx-auto w-full max-w-screen-xl my-20 px-4 content-center ">

			<div class="flex flex-col justify-center">
				<h1 class="text-gray-900 text-8xl font-semibold">TMU</h1>
				<h1 class="text-gray-900 text-8xl font-semibold">Marketplace</h1>
				<p class=" text-blue-600 text-3xl font-semibold mt-8">Student Deals: Shop. Sell. Connect.</p>


			</div>
		
			<div class="flex justify-end items-center">
				<img src="/college_students.svg" alt="students" class="h-96" />
			</div> 

		</div>

		
	</div>
	

</div>

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


<div class="text-slate-600 m-4 flex flex-col w-80 space-y-4">
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
	

</div>





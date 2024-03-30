<!-- // src/routes/auth/+page.svelte -->
<script lang="ts">
	export let data;
	let { supabase } = data;
	$: ({ supabase } = data);

	let title: string;
	let content: string;
	let price: number;
	let type: string;
	let location: string;
	let user_id: string;


	const newPost = async () => {
		const { data, error } = await supabase.from('posts').insert([
			{
				title: 'New Post',
				price: 0
			}
		]);
		console.log(data);
	};
</script>

<!-- <form on:submit={handleSignUp}>
	<input name="email" bind:value={email} />
	<input type="password" name="password" bind:value={password} />
	<button>Sign up</button>
</form> -->

<!-- <button on:click={handleSignIn}>Add Post</button>
<button on:click={handleSignOut}>Sign out</button> -->

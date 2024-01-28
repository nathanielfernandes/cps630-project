<script lang="ts">
	export let data;

	console.log('data', data);
	$: if (data.session) {
		console.log('session', data.session);
	}
</script>

<h1>testing</h1>
<a href="/login">login</a>

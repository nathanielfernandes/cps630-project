<script lang="ts">
    let clazz: string = "";
    export { clazz as class };
    export let email: string;

    const backgroundColours = ['2dbcda', '1bd4ab', '5d28e7', 'e44141', 'e4419f', 'ff6f2f'];

    if (!email) {
        email = "NA";
    }
    const initials = email.replace(/[^a-zA-Z]/g, "").substring(0, 2).toUpperCase();
    const color = backgroundColours[email.length % backgroundColours.length];

    const url = `https://api.dicebear.com/7.x/initials/svg?seed=${initials}&backgroundColor=${color}`;
</script>   

<img src={url} alt={email} class={clazz} />
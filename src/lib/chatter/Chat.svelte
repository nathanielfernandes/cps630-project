<script lang="ts">
    import { authenicated, chat_order, messages, open, ping, talking_to, users } from "./stores";
	import { send_message } from "./msg";
	import Pfp from "$lib/components/Pfp.svelte";
	import { page } from '$app/stores';
	import { fly, slide } from "svelte/transition";
	import { onMount, tick } from "svelte";
	import { posts } from "$lib/stores";

    $: uid = $page.data.session ? $page.data.session.user.id : "NA";
    $: email = ($page.data.session ? $page.data.session.user.email : "NA") as string;

    // $: if (uid) console.log("uid", uid);

    let message = "";
    function send() {
        if (!message) return;
        if (!$talking_to) return;
        send_message("DirectMessage", { message, to: $talking_to });
        message = "";
    }

    let bottom: HTMLDivElement;
    const scroll = async () => {
        await tick();
        if (bottom) {
            bottom.scrollIntoView({ behavior: "smooth" });
        }
    };
    onMount(scroll);
    talking_to.subscribe(scroll);
    messages.subscribe(scroll);
</script>

{#if $authenicated}
<div class="fixed bottom-0 sm:right-2 bg-white p-2 rounded-t-lg w-full sm:w-96 text-slate-600 transition-all duration-100 z-50">
    {#if $talking_to && $users[$talking_to]}
        <div class="flex items-center justify-between py-0.5 px-1 ">
            <div class="flex items-center space-x-2 font-bold">
                <Pfp email={$users[$talking_to]} class="h-9 w-9 rounded-md" />
                <div>{$users[$talking_to]}</div>
            </div>
            <button class="bg-slate-100 p-2 rounded-full w-9 h-9 hover:bg-slate-200 active:bg-slate-300 flex items-center justify-center"
                on:click={() => talking_to.set("")}
            >
                <i class="fa-solid fa-chevron-left"></i>
            </button>
        </div>
    {:else}
        <div class="flex items-center justify-between py-0.5 px-1 ">
            <div class="flex items-center space-x-2 font-bold">
                <Pfp email={email} class="h-9 w-9 rounded-md" />
                <div>Messaging</div>
            </div>
            <button class="bg-slate-100 p-2 rounded-full w-9 h-9 hover:bg-slate-200 active:bg-slate-300 relative"
                on:click={() => open.update((v) => !v)}
            >
                {#if $open}
                    <i class="fa-solid fa-chevron-down"></i>
                {:else}
                    <i class="fa-solid fa-chevron-up"></i>
                {/if}

                {#if $ping}
                    <span
                        class="absolute top-1 right-1 inline-flex items-center justify-center w-2 h-2 text-xs font-bold leading-none text-white  bg-red-500 rounded-full"
                        ></span
                    >
                    <span
                        class="absolute top-1 right-1 inline-flex items-center justify-center w-2 h-2 text-xs font-bold leading-none text-white  bg-red-500 rounded-full animate-ping"
                        ></span
                    >
                {/if}
            </button>
        </div>
    {/if}

    {#if $open} 
        <div class="h-[28rem] pb-1" transition:slide={{duration: 200}}>
            <hr class="mt-4 mb-1" />

            {#if $talking_to}
                {@const msgs = $messages[$talking_to] || []}
                <div class="w-full h-full bg-slate-100 rounded-md mt-1.5 flex flex-col justify-between">
                    <div class="h-full overflow-y-scroll no-scrollbar">
                        {#each msgs as msg}
                            {#if msg.type === "User"}
                                {#if msg.from === uid}
                                    <div class="flex justify-end" in:fly|local>
                                        <div class="bg-slate-300 p-2 rounded-lg mx-1 my-0.5 max-w-80">
                                            {msg.message}
                                        </div>
                                    </div>
                                {:else}
                                    <div class="flex justify-start" in:fly|local>
                                        <div class="bg-blue-300 p-2 rounded-lg mx-1 my-0.5 max-w-80">
                                            {msg.message}
                                        </div>
                                    </div>
                                {/if}
                            {:else if msg.type === "Topic"}
                                {@const post = $posts[msg.topic]}
                                <div class="flex justify-center" in:fly|local>
                                    <div class="p-2 rounded-lg mx-1 my-0.5 w-80 text-center ">
                                        <span class="text-sm font-bold text-slate-400">Talking about</span>
                                        <br />
                                        {#if post}
                                            <a class="truncate font-bold hover:underline" href="/dashboard/listings/posts/{msg.topic}">{post.title}</a>
                                        {:else}
                                            <span class="truncate font-bold">{msg.topic}</span>
                                        {/if}
                                    </div>
                                </div>
                            {/if}
                        {/each}
                        {#if msgs.length === 0}
                            <div class="flex justify-center items-center h-full">
                                <div class="text-slate-400">No messages, Say Hi!</div>
                            </div>
                        {/if}
                        <div bind:this={bottom}></div>
                    </div>
                

                    <form class="flex space-x-1 m-1" on:submit|preventDefault={send}>
                        <input type="text" class="w-4/5 rounded-lg p-2" placeholder="Message" bind:value={message} />
                        <button class="bg-blue-500 text-white px-4 py-2 rounded-lg"
                            on:click={send}
                        >Send</button>
                    </form>
                </div>
            {:else}
                {#each $chat_order as id}
                    {@const email = $users[id]}
                    {#if id !== uid}
                        <button class="flex p-2 rounded-lg bg-slate-100 h-min text-left w-full mb-1 items-center justify-between hover:bg-slate-200 active:bg-slate-300"
                            transition:fly
                            on:click={() => talking_to.set(id)}    
                        >
                            <div class="flex items-center space-x-2">
                                <Pfp email={email} class="h-10 w-10 rounded-md" />
                                <div class="flex flex-col">
                                    <div class="text-sm font-bold truncate">{email}</div>
                                    <div class="w-60">
                                        {#if $messages[id]}
                                            {@const last = $messages[id][$messages[id].length - 1]}
                                            {#if last.type === "Topic"}
                                                {@const post = $posts[last.topic]}
                                                {#if post}
                                                    <div class="truncate">
                                                        Talking about {post.title}
                                                    </div>
                                                {:else}
                                                    <div class="truncate">{last.topic}</div>
                                                {/if}
                                            {:else}
                                                <div class="truncate">                                            
                                                    {last.message || "..."}
                                                </div>
                                            {/if}
                                        {:else}
                                            <div class="truncate">No messages</div>
                                        {/if}
                                    </div>
                                </div>
                            </div>
                        
                            <i class="fa-solid fa-chevron-right mr-2"></i>
                        </button>
                    {/if}
                {/each}
            {/if}
        </div>
    {/if}
</div>
{/if}


            <!-- {#if talking_to}
                <div class="flex items center space-x-2">
                    <button class="bg-slate-100 p-2 hover:bg-slate-200 active:bg-slate-300 flex items-center rounded-lg space-x-2 w-full"
                        on:click={() => talking_to = ""}
                    >
                        <i class="fa-solid fa-chevron-left"></i>
                        <Pfp email={$users[talking_to]} class="h-8 w-8 rounded-full" />
                        <div class="font-bold">{$users[talking_to]}</div>
                    </button>
                </div>
            {:else} -->

            
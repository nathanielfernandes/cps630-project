<script lang="ts">
	import { send_message } from "./msg";
	import { messages } from "./stores";


    let to = "c2446533-f749-445a-a437-b16dc18c2440";
    let message = "";


    function send() {
        send_message("DirectMessage", { message, to });
        console.log("Sent message");
    }
</script>



<div class="bg-slate-500 w-96 h-96 rounded-md p-2 flex flex-col space-y-2 text-black">
    <h2>Chat</h2>


    <div>
        Message to:
        <input type="text" class="w-full rounded-lg p-2" placeholder="To" bind:value={to} />
    </div>

    <div>
        <textarea class="w-full rounded-lg p-2" placeholder="Message" bind:value={message}></textarea>
    </div>

    <div>
        <button class="bg-green-500 text-white px-4 py-2 rounded-lg"
            on:click={send}
        >Send</button>
    </div>

</div>

<div class="flex flex-col space-y-2 bg-slate-500 w-96 rounded-md p-2 text-black">
    {#each Object.entries($messages) as [from, msgs]}
        <div class="bg-slate-500 w-96 rounded-md p-2 text-black">
            <h2>Messages for {from}</h2>
            {#each msgs as msg}
                <div class="bg-slate-400 p-2 rounded-lg my-2">
                    {#if msg.type === "User"}
                        <p>{msg.message}</p>
                    {:else}
                        <p>Unknown message type</p>
                    {/if}
                </div>
            {/each}
        </div>
    {/each}
</div>
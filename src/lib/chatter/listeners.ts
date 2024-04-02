import { errorAlert } from "$lib/Alerts/stores";
import { get } from "svelte/store";
import { on_message, send_message } from "./msg";
import { addMessages, addUsers, users, open, ping, authenicated } from "./stores";


export function startListeners() {
    on_message("Authenticated", (_) => {;
        console.log("Websocket Authenticated!");
        send_message("SyncChatUsers", {});
        authenicated.set(true);
    });

    on_message("BulkUsers", ({ users }) => {
        addUsers(users);
        for (const user of users) {
            send_message("SyncChat", { with: user.id });
        }
    });

    on_message("UserMeta", ({ user }) => {
        addUsers([user]);
    });

    on_message("Error", (message) => {
        errorAlert("WS Error");
        console.error("WS Error: ", message);
    });

    on_message("BulkMessages", ({ participants, messages }) => { 
        addMessages(participants, messages);
    });

    on_message("DirectMessage", ({ participants, message }) => {
        const usrs = get(users);
        for (const participant of participants) {
            if (!usrs[participant]) {
                send_message("UserMeta", { with: participant });
            }
        }
        const is_open = get(open);
        if (!is_open) {
            ping.set(true);
        }
        addMessages(participants, [message]);
    });
}
import { infoAlert } from "$lib/Alerts/stores";
import { on_message } from "./msg";
import { addMessages } from "./stores";


export function startListeners() {
    on_message("Authenticated", (_) => {
        // infoAlert("Websocket Authenticated!");
        console.log("Websocket Authenticated!");
    });

    on_message("Error", (message) => {
        infoAlert(`Error: ${message}`);
    });

    on_message("BulkMessages", ({ participants, messages }) => { 
        addMessages(participants, messages);
    });

    on_message("DirectMessage", ({ participants, message }) => {
        addMessages(participants, [message]);
    });
}
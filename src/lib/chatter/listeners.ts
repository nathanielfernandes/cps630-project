import { infoAlert } from "$lib/Alerts/stores";
import { on_message } from "./msg";


export function startListeners() {
    on_message("Authenticated", (_) => {
        infoAlert("Websocket Authenticated!");
    });

    on_message("Error", (message) => {
        infoAlert(`Error: ${message}`);
    });

    on_message("BulkMessages", ({ messages, from }) => {

    });


    // on_message("Message", ({ message }) => {
    //     switch (message.type) {
    //         case "User":
    //             break;
    //         case "Topic":
    //             break;
    //         case "Server":
    //             break;
    //     }
    // });
}
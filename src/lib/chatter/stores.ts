import { PUBLIC_CHATTER_WS_URL } from "$env/static/public";
import { get, writable } from "svelte/store";
import { handle_message, send_message } from "./msg";
import { startListeners } from "./listeners";
import type { ChatMessage, ChatUser } from "$lib/messages";

export let socket: WebSocket | null;
export type SocketState =  "connecting" | "connected" | "authenticated" | "disconnected";

export const socket_state = writable<SocketState>("connecting");

export const authenicated = writable(false);

export const uuid = writable("");
export const ssecret = writable("");

export const open = writable(false);
export const talking_to = writable("");
export const ping = writable(false);

open.subscribe((o) => {
    if (o) {
        ping.set(false);
    }
});

export const messages = writable<{ [from: string]: ChatMessage[] }>({});
export const users = writable<{ [id: string]: string }>({});

export function startChat(user_id: string, topic: string = "") {
    talking_to.set(user_id);
    open.set(true);

    send_message("UserMeta", { with: user_id });

    if (topic.length > 0) {
        send_message("SetTopic", { to: user_id, topic });
    }

    console.log("Starting chat with", user_id);
}

export function resetChatState() {
    authenicated.set(false);
    users.set({});
    messages.set({});

    retry_connect();
}

export function addMessages(participants: string[], bulk_msgs: ChatMessage[], clear: boolean = false) {
    const [from, to] = participants;
    const key = from === get(uuid) ? to : from;

    messages.update((msgs) => {
        if (!msgs[key]) {
            msgs[key] = [];
        }

        if (clear) {
            msgs[key] = [];
        }

        for (const msg of bulk_msgs) {
            msgs[key].push(msg);
        }

        return msgs;
    });
}

export function addUsers(usrs: ChatUser[]) {
    users.update((u) => {
        for (const user of usrs) {
            u[user.id] = user.email;
        }
        return u;
    });
}


let started = false;
export function connect_websocket() {
    if (!started) {
        startListeners();
        started = true;
    }

    if (socket) {
        socket.close();
        socket = null;
    }

    socket_state.set("connecting");

    console.log("Connecting to Websocket", PUBLIC_CHATTER_WS_URL);
    socket = new WebSocket(PUBLIC_CHATTER_WS_URL);

    socket.onopen = (_) => {
        socket_state.set("connected");
        // successAlert("Connected to Websocket");
        send_message("Ping", {})
    }

    socket.onclose = (_) => {
        socket = null;
        socket_state.set("disconnected");
    }

    socket.onmessage = (event) => {
        const message = JSON.parse(event.data);
        handle_message(message);
    }

    socket.onerror = (event) => {
        console.error("WebSocket error", event);
        socket = null;
        socket_state.set("disconnected");
        retry_connect();
    }
}

export function disconnect_websocket() {
    if (socket) {
        socket.close();
        socket = null;
    }
}


function debounce<F extends (...args: any[]) => any>(
    func: F,
    waitFor: number,
    once?: (...args: Parameters<F>) => void
): (...args: Parameters<F>) => void {
    let timeoutId: NodeJS.Timeout | null = null;
    let isFirstCall = true;

    return (...args: Parameters<F>): void => {
        if (isFirstCall && once) {
            once(...args);
            isFirstCall = false;
        }

        if (timeoutId !== null) {
            clearTimeout(timeoutId);
        }

        timeoutId = setTimeout(() => {
            func(...args);
            if (once) {
                isFirstCall = true; // reset the first call flag after the debounced function fires
            }
        }, waitFor);
    };
}

const retry_time = 3;
const retry_connect = debounce(connect_websocket, retry_time * 1000, () => {});

socket_state.subscribe((state) => {
    if (state === "disconnected") {
        retry_connect();
    }
    if (state === "connected") {
        tryAuthenticating();
    }
});


ssecret.subscribe((secret) => {
    tryAuthenticating({ secret });
});

export function tryAuthenticating({ id, secret }: { id?: string, secret?: string } = {}) {
    id = id || get(uuid);
    secret = secret || get(ssecret);

    if (secret.length > 0 && id.length > 0) {
        send_message(
            'Authenticate',
            {
                id,
                secret
            }
        )
    }
}




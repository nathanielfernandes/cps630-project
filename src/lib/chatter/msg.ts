import type { ClientMessage, ClientMessageMap, ClientMessageTypes, ServerErrors, ServerMessage, ServerMessageMap, ServerMessageTypes } from "$lib/messages";

import { socket } from "./stores";

const promises = new Map<string, (value: any) => void>();
const callbacks = new Map<string, ((value: any) => void)[]>();

export function handle_message(message: ServerMessage) {
    // console.log("message from server", message);
    // console.log(callbacks);

    const cbs = callbacks.get(message.type) ?? [];
    for (const cb of cbs) {
        cb(message);
    }
}

export function resolve_message_promise(id: string, value: any) {
    const resolve = promises.get(id);
    if (resolve) {
        promises.delete(id);
        resolve(value);
    }
}

export function on_message<T extends ServerMessageTypes>(type: T, cb: (message: ServerMessageMap<T>) => void) {
    // if the callback is already in the list, don't add it again
    if (callbacks.get(type)?.includes(cb)) {
        return;
    }
    
    const cbs = callbacks.get(type) ?? [];
    cbs.push(cb);
    callbacks.set(type, cbs);
}

export async function send_message<T extends ClientMessageTypes>(type: T, value: ClientMessageMap<T>): Promise<ServerErrors> {
    if (!socket) {
        return "Internal";
    }

    const message_id = Math.random().toString(36).substring(2);

    const message: ClientMessage = { type, ...value } as any;
    const serialized = JSON.stringify(message);

    socket.send(serialized);

    return new Promise((resolve) => {
        promises.set(message_id, resolve);
    });
}
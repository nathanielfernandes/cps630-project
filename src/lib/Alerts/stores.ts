import { writable } from "svelte/store";

export type AlertColor = 'green' | 'red' | 'yellow' | 'blue' | 'dark';
export type Alert = {
    id: number;
    color: AlertColor;

    title: string;
    message: string;

    close: () => void;
}
    
// lazy id generator
const ac = writable(0);
function newId(): number {
    let id = 0;
    ac.update(c => id = c + 1);
    return id;
}

// dunder prefix because i do not want this to be used directly
// it sadly has to be exported for the component to use it
export const __alerts = writable<Alert[]>([]);
function addAlert(alert: Alert) {
    __alerts.update(a => [...a, alert]);
}
function removeAlert(id: number) {
    __alerts.update(a => a.filter(alert => alert.id !== id));
}

// alert function
// create a new alert, and return a function to close it
// if timeout is 0, the alert will not close automatically
export function newAlert(title: string = "", message: string = "", color: AlertColor = "dark", timeout: number = 2000): () => void {
    const id = newId();
    const close = () => removeAlert(id);
    addAlert({ id, color, title, message, close});

    if (timeout > 0) {
        setTimeout(close, timeout);
    }

    return close;
}

// pre-made alerts
export function successAlert(title: string = "", message: string = "", timeout: number = 2000): () => void {
    return newAlert(title, message, "green", timeout);
}

export function errorAlert(title: string = "", message: string = "", timeout: number = 2000): () => void {
    return newAlert(title, message, "red", timeout);
}

export function warningAlert(title: string = "", message: string = "", timeout: number = 2000): () => void {
    return newAlert(title, message, "yellow", timeout);
}

export function infoAlert(title: string = "", message: string = "", timeout: number = 2000): () => void {
    return newAlert(title, message, "blue", timeout);
}

export function darkAlert(title: string = "", message: string = "", timeout: number = 2000): () => void {
    return newAlert(title, message, "dark", timeout);
}
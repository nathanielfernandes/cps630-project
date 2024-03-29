/** this file is automatically generated, do not edit **/

export type ServerMessage = { type: "Pong" } | { type: "Authenticated" } | ({ type: "Error" } & ServerErrors) | { type: "BulkMessages"; from: string; messages: ChatMessage[] } | { type: "DirectMessage"; message: ChatMessage };
export type ServerErrors = "Internal" | "Unauthorized" | "AlreadyAuthenticated" | "InvalidUuid" | "InvalidSecret" | "InvalidMessage" | "InvalidUser" | "RateLimited";
export type ClientMessage = { type: "Ping" } | { type: "Disconnect" } | { type: "Authenticate"; id: string; secret: string } | { type: "SyncChat"; with: string } | { type: "DirectMessage"; to: string; message: string };
export type ChatMessage = { type: "User"; from: string; message: string } | { type: "Topic"; topic: string } | { type: "Server"; message: string };

export type ClientMessageTypes = ClientMessage["type"];
export type ServerMessageTypes = ServerMessage["type"];
export type ChatMessageTypes = ChatMessage["type"];
export type ServerMessageMap<T extends ServerMessageTypes> = Omit<Extract<ServerMessage, { type: T }>, 'type'>;
export type ClientMessageMap<T extends ClientMessageTypes> = Omit<Extract<ClientMessage, { type: T }>, 'type'>;

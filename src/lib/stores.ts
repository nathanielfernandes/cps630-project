import { writable } from "svelte/store";
import { localstate } from "./state";

export interface Image {
    link: string;
    alt_text: string;
}

export type Post = {
  id: number;
  title: string;
  content: string;
  price: number;
  type: 'items_for_sale' | 'items_wanted' | 'academic_services';
  location: string;
  user_id: string;
  email: string;
  created_at: string;
  images: Image[];
}

export const posts = localstate<{[post_id:string]:Post}>({}, "posts");
export const waiting = writable(true);
posts.subscribe((p) => {
  if (Object.keys(p).length > 0) {
    waiting.set(false);
  }
});

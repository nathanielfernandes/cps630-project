import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://kit.svelte.dev/docs/integrations#preprocessors
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		// using node adapter and outputting to the build folder when built
		adapter: adapter({
			out: 'build'
		})
	},

	vitePlugin: {
        experimental: {
            // Allows you to hold ctrl+shift and click on an item in the browser and it then
            // opens that components location in VSCode
            inspector: {
                holdMode: true
            }
        }
    }
};

export default config;

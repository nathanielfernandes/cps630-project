<script lang="ts">
    import { onMount } from 'svelte';
    export let data;

    let { supabase, session } = data;
    $: ({ supabase } = data);

    let default_image_link = "https://t3.ftcdn.net/jpg/02/48/42/64/360_F_248426448_NVKLywWqArG2ADUxDq6QprtIzsF82dMF.jpg"
    let image_prefix = "https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/"
    let title = '';
    let content = '';
    let price = '';
    let type = '';
    //@ts-ignore
    let user_id = session.user.id;
    //@ts-ignore
    let image: any;

    const insertPost = async() => {
        let { data: postData } = await supabase
        .from('posts')
        .insert([
            {
                title,
                content,
                price,
                type,
                user_id
            }
        ])
        .select()
        .single();
        return postData;
    }

    const uploadImage = async() => {
        const random_value = Math.floor(Math.random() * 1000000);
        const { data, error } = await supabase.storage
        .from('images')
        //@ts-ignore
        .upload(`uploads/${session.user.id}/${random_value}_${image.name}`, image);

        if (error) {
            console.error(error);
            return default_image_link;
        }
        const link_to_image = image_prefix + encodeURIComponent(data.path);
        return link_to_image;
    }

    const insertImage = async(post_id: string, imageLink: string = default_image_link) => {
        let { data: imageData, error } = await supabase
        .from('images')
        .insert([
            {
                post_id,
                link: imageLink,
                alt_text: 'placeholder'
            }
        ])
        .single();

        if (error) {
            console.error(error);
            throw error;
        }
        
        return imageData;
    }

    const handleSubmit = async() => {
        const postData = await insertPost();
        const imageLink = await uploadImage();
        await insertImage(postData.id, imageLink);
    };

    // reset file input
    onMount(() => {
        //@ts-ignore
        document.getElementById('image-upload').value = '';
    });
</script>

<form on:submit|preventDefault={handleSubmit} class="space-y-4 bg-blue-100 p-4 rounded-md">
    <div class="flex flex-col">
        <label for="title" class="mb-2 text-sm font-bold text-blue-700 text-black">Title</label>
        <input type="text" id="title" bind:value={title} class="form-input px-4 py-2 rounded-md text-black" placeholder="Post title" required>
    </div>

    <div class="flex flex-col">
        <label for="content" class="mb-2 text-sm font-bold text-blue-700 text-black">Content</label>
        <textarea id="content" bind:value={content} rows="4" class="form-textarea px-4 py-2 rounded-md text-black" placeholder="Content" required></textarea>
    </div>

    <div class="flex flex-col">
        <label for="price" class="mb-2 text-sm font-bold text-blue-700 text-black">Price</label>
        <input type="number" id="price" bind:value={price} class="form-input px-4 py-2 rounded-md text-black" placeholder="0" required>
    </div>

    <div class="flex flex-col">
        <label for="type" class="mb-2 text-sm font-bold text-blue-700 text-black">Type</label>
        <select id="type" bind:value={type} class="form-select px-4 py-2 rounded-md bg-white" required>
            <option value="" disabled selected>Select your option</option>
            <option value="items_for_sale">Items for Sale</option>
            <option value="items_wanted">Items Wanted</option>
            <option value="academic_services">Academic Services</option>
        </select>
    </div>

    <div class="flex flex-col">
        <label for="image-upload" class="mb-2 text-sm font-bold text-blue-700 text-black">Image Upload</label>
        
        <input type="file" id="image-upload" on:change="{e => image = e.target.files[0]}" class="form-file px-4 py-2 rounded-md" required>
    </div>

    <button type="submit" class="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-md">
        Submit
    </button>
</form>
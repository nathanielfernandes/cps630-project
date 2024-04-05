# CPS 630 Project

### Stack

- SvelteKit >> https://kit.svelte.dev/docs/introduction (typescript)
- TailwindCSS >> https://tailwindcss.com/docs/customizing-colors
- Supabase >> https://supabase.com/docs

### Setup

1. Clone the repo

```
git clone https://https://github.com/nathanielfernandes/cps630-project
```

2. Install dependencies

```
cd cps630-project
npm install
```

3. Run the project (dev mode must be running when working on the project)

```
npm run dev
```

4. Run the Websocket server

```
npm run chatter
```

### Project Structure (High Level Overview)

```
cps630-project
├── README.md
├── ...
├── src
│   ├── lib >> (shared code that can be imported anywhere via `$lib/...`)
│   │   ├── databasedefs.ts >> Database definitions (auto-generated)
│   ├── routes (pages)
│   │   ├── admin >> admin dashboard
│   │   ├── auth >> authentication pages
│   │   │   ├── callback >> authentication callback endpoint
│   │   ├── dashboard >> user dashboard
│   │   ├── login >> login page (subject to change)
│   │   ├── +page.svelte >> index page
│   │   ├── +layout* >> don't touch these (unless you know what you're doing)
│   ├── app.css >> global css (no reason you will ever need to touch this)
│   ├── app.html >> (no reason you will ever need to touch this)
│   ├── app.d.ts >> (don't touch unless you know what you're doing)
│   ├── hooks.server.ts >> (no reason you will ever need to touch this)
├── static >> static assets (images, fonts, etc.)
├── .env.local >> local environment variables (you will need to create this)
├── ** >> all other files (don't touch unless you know what you're doing)
```

# User Manual

The following is a user manual of how to use the website.

## Creating an account / Logging in

In order to view and post listings, you must have an account. Click on the blue button on the top right corner "Sign in / Register". Create your account or log in with your existing account.

## Browsing listings

Click on either the "Wanted Listings", "Buy & Sell" or "Academic Services" tabs at the top of the page to browse the respective categories. You are now able to view the postings with their title, description, price, images, and seller email address.

## Searching

While on a listings page, search through the listings using the search bar on the top right corner of the page. You can search keywords related to the title, description, price, or email. 

You can save your particular query by bookmarking the tab.

## Listing information

While on a listings page, click on a listing to view it's full details, including all attached images, location data, and user contact information. 

## Messaging Users

Message users on a platform using the "messaging" tab on the botton right of the website. Here you can view all your existing conversations, and enter any one of them.

To begin a conversation with a seller, click on a listing, and then click "Contact". A new chat will begin related to the specific listing.


## Creating a Listing

To create a listing, click the yellow "Place an Ad" Button on the top left corner of the page.

From here, choose which type of listing you wish to create.

Create your listing by filling in the fields on the left side of the page. View your listing live-update on the right side of the page.

Attach multiple images from your computer, or by dragging and dropping from an online source. 

Fill in all the fields, and click "Submit". Your listing is now viewable by all users on the platform.

## Admin Panel
If you are an admin on the platform, you will have access to the admin dashboard. You can find it by clicking your user icon image and pressing "Admin Dashboard".

View site metrics such as listings count, and user count. View a table of listings related to these metrics.
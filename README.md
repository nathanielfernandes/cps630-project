# CPS 630 Project - TMU Marketplace

![image](https://github.com/nathanielfernandes/cps630-project/assets/16618046/a7c19d77-1509-4d05-8321-754ede20b308)

### Stack

- SvelteKit >> https://kit.svelte.dev/docs/introduction (typescript)
- TailwindCSS >> https://tailwindcss.com/docs/customizing-colors
- Supabase >> https://supabase.com/docs

### Configuration

a `.env` a file is required in the root directory with the following variables:

```
DATABASE_URL=<supabase postgres url>
SUPABASE_DB_PASSWORD=<supabase db password>
```

additionally, a `.env.local` file is required in the root directory with the following variables:

```
PUBLIC_SUPABASE_URL=<supabase url>
PUBLIC_SUPABASE_ANON_KEY=<supabase anon key>
PUBLIC_CHATTER_WS_URL=<websocket server url>
```

Before running the project, make sure you `supabase login` and run:

```
npm run migrate
```

to create the required tables, triggers, policies, and functions in the database.

### Local Setup

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

### Production Deployment

#### Docker

1. Build the docker image for the client

```
docker build -t tmu-marketplace-client -f Dockerfile .
```

2. Run the docker image for the client

```
docker run -p 3000:3000 tmu-marketplace-client
```

3. Build the docker image for the websocket server

```
docker build -t tmu-marketplace-chatter -f ./services/Dockerfile ./services/chatter
```

4. Run the docker image for the websocket server

```
docker run -p 3001:3001 tmu-marketplace-chatter
```

#### Manual

1. Build the client

```
cd cps630-project
npm install
npm run build
```

2. Run the client

```
node ./build/index.js
```

3. Build the websocket server

```
cd cps630-project/services/chatter
cargo build --release
```

4. Run the websocket server

```
./target/release/chatter
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

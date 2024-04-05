# CPS 630 Project - TMU Marketplace

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

### Code Guidelines

- Prettier is used to format code
- Use semicolons
- Use double quotes when possible
- Use `const` and `let` instead of `var`
- Avoid using custom css classes (use tailwind classes instead)
- Use `kebab-case` for file names
- Use `camelCase` for function names
- Use `PascalCase` for component names
- Use `UPPER_CASE` for constants
- Use `snake_case` for everything else
- You are responsible for your own code, so make sure it is readable and well documented
- Use descriptive variable and function names
- Keep your functions small and focused (don't make a function that does everything)
- Please don't yapp in comments, keep them succinct and to the point
- Correctly type your variables and functions (typescript)
- Do not write 'clever' code, write code that is easy to understand and maintain
- Do not write code that you do not understand
- Do not paste chatgpt yapp
- Use the correct html tags for the job (don't spam divs)
- Build reusable components whenever possible (don't repeat yourself)
- Keep components small and focused (don't make a component that does everything)
- Use the `src/lib` folder for shared code (sub folder when necessary)
- Keep components only relevant to a page in that page's folder
- Avoid absolute positioning
- Structure your pages and components while keeping in mind that they will need to be responsive
- Avoid external dependencies (if you need to use one, make sure it is well maintained)
- Use stores to share data between components, not props
- Do not share state by passing props down multiple levels (use stores instead again >:))
- Make sure all accessibility requirements are met (aria labels, etc.)
- CSS transition durations should be 100ms (max 200ms)
- Stick to the stack
- Stick to the Code Style Guidelines

### Contribution Guidelines

- Make sure you are working on the latest version of `master`
- Create an issue for each feature you are working on
- Create a new branch for each feature you are working on
- Branch format should be `t<issue#>_firstname` or `<feature>_firstname`
- Commit often and with descriptive commit messages
- Create a pull request when you are ready to merge your branch into `master`
- Assign atleast 2 reviewers to your pull request
- Once your pull request has been approved, you may merge it into `master`

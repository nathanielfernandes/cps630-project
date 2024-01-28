// src/routes/+layout.server.ts
//@ts-ignore
export const load = async ({ locals: { getSession } }) => {
    return {
      session: await getSession(),
    }
}
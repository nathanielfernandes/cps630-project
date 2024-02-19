export const PROTECTED_PAGES: string[] = ['dashboard', 'admin'];

const PROTECTED_PAGES_REGEX = new RegExp(`^/(?:${PROTECTED_PAGES.join("|")})(?:/.*)?$`);

export const isProtectedPage = (pathname: string) => {
  return PROTECTED_PAGES_REGEX.test(pathname);
}
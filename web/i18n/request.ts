// next-intl's default lookup path is ./i18n/request.ts (project root).
// The implementation lives in src/i18n/request.ts — re-export it here so
// createNextIntlPlugin() can find it without an explicit path argument.
export { default } from "../src/i18n/request";

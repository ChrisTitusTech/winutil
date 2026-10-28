// Shared external links, so astro.config.mjs and Header.astro can't drift out of sync.
export const siteLinks = {
	store: { label: 'Store', href: 'https://christitus.com/downloads/' },
	forums: { label: 'Forums', href: 'https://forum.christitus.com/' },
} as const;

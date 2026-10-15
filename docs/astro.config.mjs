// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import react from '@astrojs/react';
import { siteLinks } from './src/lib/site-links.ts';

// https://astro.build/config
export default defineConfig({
	site: 'https://winutil.christitus.com/',
	integrations: [
		starlight({
			title: 'WinUtil',
			description: "Chris Titus Tech's Windows Utility — install apps, apply tweaks, run fixes, and manage Windows from one place.",
			logo: {
				src: './src/assets/branding/navlogo.png',
				replacesTitle: true,
			},
			favicon: '/favicon.svg',
			head: [
				{ tag: 'meta', attrs: { property: 'og:image', content: 'https://winutil.christitus.com/social-preview.png' } },
				{ tag: 'meta', attrs: { property: 'og:image:width', content: '1200' } },
				{ tag: 'meta', attrs: { property: 'og:image:height', content: '630' } },
				{ tag: 'meta', attrs: { name: 'twitter:image', content: 'https://winutil.christitus.com/social-preview.png' } },
			],
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/ChrisTitusTech/winutil' },
				{ icon: 'discord', label: 'Discord', href: 'https://discord.gg/RUbZUZyByQ' },
			],
			// Global theme overrides (colors, fonts, landing-page section styles).
			customCss: ['./src/styles/theme.css'],
			// Component overrides, all under src/components/overrides/.
			components: {
				ThemeProvider: './src/components/overrides/ThemeProvider.astro',
				Header: './src/components/overrides/Header.astro',
				Hero: './src/components/overrides/Hero.astro',
				Footer: './src/components/overrides/Footer.astro',
				Sidebar: './src/components/overrides/Sidebar.astro',
				MobileMenuToggle: './src/components/overrides/MobileMenuToggle.astro',
				TableOfContents: './src/components/overrides/TableOfContents.astro',
				MobileTableOfContents: './src/components/overrides/MobileTableOfContents.astro',
				PageTitle: './src/components/overrides/PageTitle.astro',
				Pagination: './src/components/overrides/Pagination.astro',
				ThemeSelect: './src/components/overrides/ThemeSelect.astro',
			},
			editLink: {
				baseUrl: 'https://github.com/ChrisTitusTech/winutil/edit/main/docs/',
			},
			// Sidebar groups, top to bottom: User Guide, Code Reference, Help.
			sidebar: [
				{
					label: 'User Guide',
					items: [
						{ label: 'Overview', slug: 'guides' },
						{ label: 'Getting Started', slug: 'guides/getting-started' },
						{ label: 'Applications', slug: 'guides/application' },
						{ label: 'Tweaks', slug: 'guides/tweaks' },
						{ label: 'Features', slug: 'guides/features' },
						{ label: 'Updates', slug: 'guides/updates' },
						{ label: 'Automation', slug: 'guides/automation' },
						{ label: 'Win11 Creator', slug: 'guides/win11creator' },
					],
				},
				{
					label: 'Code Reference',
					items: [
						{ label: 'Architecture & Design', slug: 'code-reference/architecture' },
						{ label: 'Issue Triage Commands', slug: 'code-reference/issue-triage' },
						{ label: 'Tweaks Reference', items: [{ autogenerate: { directory: 'code-reference/tweaks' } }] },
						{ label: 'Features Reference', items: [{ autogenerate: { directory: 'code-reference/features' } }] },
					],
				},
				{
					label: 'Help',
					items: [
						{ label: 'FAQ', slug: 'faq' },
						{ label: 'Known Issues', slug: 'knownissues' },
						{ label: 'Contributing', slug: 'contributing' },
						{ label: siteLinks.forums.label, link: siteLinks.forums.href, attrs: { target: '_blank', rel: 'noreferrer' } },
					],
				},
				{ label: siteLinks.store.label, link: siteLinks.store.href, attrs: { target: '_blank', rel: 'noreferrer' } },
			],
		}),
		// React components for the docs UI and landing page.
		react(),
	],
});

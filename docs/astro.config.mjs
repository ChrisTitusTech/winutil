// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

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
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/ChrisTitusTech/winutil' },
				{ icon: 'discord', label: 'Discord', href: 'https://discord.gg/RUbZUZyByQ' },
			],
			customCss: ['./src/styles/theme.css'],
			components: {
				ThemeProvider: './src/components/ThemeProvider.astro',
				Hero: './src/components/Hero.astro',
				Header: './src/components/Header.astro',
			},
			editLink: {
				baseUrl: 'https://github.com/ChrisTitusTech/winutil/edit/main/docs/',
			},
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
						{ label: 'Tweaks Reference', items: [{ autogenerate: { directory: 'code-reference/tweaks' } }] },
						{ label: 'Features Reference', items: [{ autogenerate: { directory: 'code-reference/features' } }] },
					],
				},
				{
					label: 'Help',
					items: [
						{ label: 'FAQ', slug: 'faq' },
						{ label: 'Known Issues', slug: 'known-issues' },
						{ label: 'Contributing', slug: 'contributing' },
					],
				},
			],
		}),
	],
});

import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';
import { docsChangelogLoader } from './lib/docs-changelog.js';

export const collections = {
	docs: defineCollection({
		loader: docsLoader(),
		schema: docsSchema({
			extend: () =>
				z.object({
					// Small uppercase kicker line above the hero heading, e.g. "Open Source Windows Setup Utility".
					heroEyebrow: z.string().optional(),
					// Muted one-liner below the hero actions, e.g. "Self-hosted. Script-powered. No installer.".
					heroCaption: z.string().optional(),
					// Badge images (shields.io, dcbadge, etc.) shown in a row at the bottom of the hero.
					heroBadges: z
						.array(
							z.object({
								src: z.string(),
								alt: z.string(),
								href: z.string().optional(),
							})
						)
						.optional(),
				}),
		}),
	}),
	// Docs changes read from git history for the Docs Changelog page.
	docsChangelog: defineCollection({
		loader: docsChangelogLoader(),
		schema: z.object({
			title: z.string(),
			date: z.string(),
			pr: z.number().optional(),
		}),
	}),
};

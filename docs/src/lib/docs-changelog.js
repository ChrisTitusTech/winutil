// Loads the Docs Changelog entries from git history.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

// The Astro site starts here (#4892).
const FIRST_COMMIT = '6f0629207ac1411c32a692aa6ec20398483ebe57';
// Keep in step with the code paths in label-pr.yaml.
const CODE = /^(functions|scripts|config|xaml)\/|^(Compile\.ps1|tools\/autounattend\.xml)$/;
// Generated reference pages and dependency bumps.
const UNLISTED = /^docs\/(src\/content\/docs\/code-reference\/(tweaks|features)\/|package(-lock)?\.json$)/;
// No --first-parent: a local "Merge branch 'main'" leaves PRs merged on GitHub on its second parent.
const LOG_ARGS = [
	'--full-diff',
	'--no-renames',
	'--name-only',
	'--format=%x00%H%x09%cI%x09%s',
	`${FIRST_COMMIT}~1..HEAD`,
	'--',
	':(top)docs',
];
// Written by git on the host, since the docs container can't see .git.
const HISTORY_FILE = '.changelog-history';

// Splits the raw log into commits with the files each one changed.
function parseLog(log) {
	return log
		.split('\0')
		.slice(1)
		.map((entry) => {
			const [header, ...files] = entry.split('\n').filter(Boolean);
			const [, hash, date, subject] = header.match(/^(\w+)\t(\S+)\t(.*)$/);
			return { hash, date, subject, files };
		});
}

export function docsChangelogLoader() {
	return {
		name: 'docs-changelog',
		load: async ({ store, logger, parseData }) => {
			store.clear();
			// Read the log from git, or from the history file in local builds.
			let log;
			try {
				log = execFileSync('git', ['log', ...LOG_ARGS], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
			} catch (error) {
				if (process.env.GITHUB_ACTIONS) throw error;
				try {
					log = readFileSync(HISTORY_FILE, 'utf8');
				} catch {
					const args = [`--output=${HISTORY_FILE}`, ...LOG_ARGS].map((arg) => `'${arg}'`).join(' ');
					logger.warn(
						'No git history for the docs changelog. Run this from docs/ on the host to fill it in:\n' +
							`git log ${args}`
					);
					return;
				}
			}
			// Keep the docs-only commits and store each one's title, date and PR number.
			for (const { hash, date, subject, files } of parseLog(log)) {
				if (files.some((file) => CODE.test(file))) continue;
				if (!files.some((file) => file.startsWith('docs/') && !UNLISTED.test(file))) continue;
				const [, title, pr] = subject.match(/^\s*(.*?)\s*(?:\(#(\d+)\))?$/);
				const data = { title, date, pr: pr && Number(pr) };
				store.set({ id: hash, data: await parseData({ id: hash, data }) });
			}
		},
	};
}

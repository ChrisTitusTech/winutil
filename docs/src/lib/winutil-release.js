// Reads config files from the latest stable release, which is what https://christitus.com/win runs.
const REPO = 'ChrisTitusTech/winutil';
export const RATE_LIMITED = 'GitHub rate limit has been reached. Please try again later.';
const RELEASE_KEY = 'winutil-latest-release';

async function fetchText(url) {
	const response = await fetch(url);
	if (response.ok) return response.text();
	// Anonymous API calls are limited per network, which a shared connection can use up.
	if (response.headers.get('x-ratelimit-remaining') === '0') throw new Error(RATE_LIMITED);
	throw new Error(`GitHub returned ${response.status}`);
}

// The release lookup is the only rate-limited request, so it's kept for the rest of the browser session.
async function latestRelease() {
	try {
		const saved = sessionStorage.getItem(RELEASE_KEY);
		if (saved) return JSON.parse(saved);
	} catch {
		// Storage can be blocked; look the release up instead.
	}
	const { tag_name: tag, html_url: url } = JSON.parse(
		await fetchText(`https://api.github.com/repos/${REPO}/releases/latest`)
	);
	try {
		sessionStorage.setItem(RELEASE_KEY, JSON.stringify({ tag, url }));
	} catch {
		// Without storage the next visit looks it up again.
	}
	return { tag, url };
}

// ConvertFrom-Json accepts raw line breaks inside strings, which the multi-line InvokeScript blocks rely on, and
// JSON.parse doesn't, so they're escaped first.
function parseConfig(text) {
	return JSON.parse(
		text.replace(/"(?:[^"\\]|\\.)*"/g, (literal) =>
			literal.replace(/[\u0000-\u001f]/g, (char) => `\\u${char.charCodeAt(0).toString(16).padStart(4, '0')}`)
		)
	);
}

export async function loadReleaseConfig(names) {
	const release = await latestRelease();
	const files = await Promise.all(
		names.map(async (name) =>
			parseConfig(await fetchText(`https://raw.githubusercontent.com/${REPO}/${release.tag}/config/${name}.json`))
		)
	);
	return { release, files };
}

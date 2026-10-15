// Builds a -Config file from the latest release's catalog, so every key it offers is one that release will import.
import { useEffect, useMemo, useState } from 'react';
import Icon from '../docs/Icon.jsx';
import './ConfigBuilder.css';

const REPO = 'ChrisTitusTech/winutil';

// Each download gets its own name. A browser renames a clash to "name (1).json", and the command would then run the
// older file.
function configFileName() {
	const stamp = new Date().toISOString().slice(0, 23).replace(/[-:.]/g, '').replace('T', '-');
	return `winutil-config-${stamp}.json`;
}

async function fetchText(url) {
	const response = await fetch(url);
	if (!response.ok) throw new Error(`GitHub returned ${response.status}`);
	return response.text();
}

// ConvertFrom-Json accepts raw line breaks inside strings, which the multi-line InvokeScript blocks rely on, and
// JSON.parse doesn't, so they're escaped first.
function parseCatalog(text) {
	return JSON.parse(
		text.replace(/"(?:[^"\\]|\\.)*"/g, (literal) =>
			literal.replace(/[\u0000-\u001f]/g, (char) => `\\u${char.charCodeAt(0).toString(16).padStart(4, '0')}`)
		)
	);
}

// Buttons share the WPFFeature prefix but can't be imported, so only checkbox and toggle entries are offered.
function entries(catalog, pattern) {
	return Object.entries(catalog)
		.filter(([key, entry]) => pattern.test(key) && entry.Type !== 'Button')
		.map(([key, entry]) => ({
			key,
			name: entry.Content,
			description: entry.Description,
			category: entry.category ?? entry.Category,
			link: entry.link,
		}));
}

async function loadCatalog() {
	const release = JSON.parse(await fetchText(`https://api.github.com/repos/${REPO}/releases/latest`));
	const [applications, tweaks, features, appx, presets] = await Promise.all(
		['applications', 'tweaks', 'feature', 'appx', 'preset'].map(async (name) =>
			parseCatalog(await fetchText(`https://raw.githubusercontent.com/${REPO}/${release.tag_name}/config/${name}.json`))
		)
	);
	// Tab order matches WinUtil's export order: apps, tweaks, toggles, features, AppX.
	return {
		release: { tag: release.tag_name, url: release.html_url },
		tabs: [
			{
				id: 'apps',
				label: 'Applications',
				items: Object.entries(applications).map(([name, app]) => ({
					key: `WPFInstall${name}`,
					name: app.content,
					description: app.description,
					category: app.category,
					link: app.link,
				})),
			},
			{
				id: 'tweaks',
				label: 'Tweaks',
				items: [...entries(tweaks, /^WPFTweaks/), ...entries(tweaks, /^WPFToggle/)],
				presetScope: 'WPFTweaks',
				presets: ['Standard', 'Minimal', 'Advanced'].map((name) => ({ label: name, keys: presets[name] ?? [] })),
			},
			{ id: 'features', label: 'Features', items: entries(features, /^WPFFeature/) },
			{
				id: 'appx',
				label: 'AppX',
				items: entries(appx, /^WPFAppx/),
				presetScope: 'WPFAppx',
				presets: [{ label: 'Default', keys: presets.AppxDefault ?? [] }],
			},
		],
	};
}

// Current exports are a key or an array of keys; older ones grouped them under WPFInstall, WPFTweaks and so on.
function readConfig(json) {
	if (typeof json === 'string') return [json];
	if (Array.isArray(json)) return json.filter((key) => typeof key === 'string');
	return Object.entries(json)
		.filter(([name]) => /^WPF(?:Install|Tweaks|Toggle|Feature|Appx)/.test(name))
		.flatMap(([, value]) => [value].flat())
		.filter((key) => typeof key === 'string');
}

// WinUtil sorts categories by name; the z__ prefix is only there to push the advanced ones last.
function groupByCategory(items) {
	const groups = new Map();
	for (const item of items) {
		if (!groups.has(item.category)) groups.set(item.category, []);
		groups.get(item.category).push(item);
	}
	return [...groups]
		.sort(([a], [b]) => a.localeCompare(b))
		.map(([category, groupItems]) => ({ name: category.replace(/^z__/, ''), items: groupItems }));
}

export default function ConfigBuilder() {
	const [catalog, setCatalog] = useState(null);
	const [error, setError] = useState(null);
	const [attempt, setAttempt] = useState(0);
	const [tabId, setTabId] = useState('apps');
	const [query, setQuery] = useState('');
	const [selected, setSelected] = useState(() => new Set());
	const [notice, setNotice] = useState(null);
	const [copied, setCopied] = useState(null);
	const [fileName, setFileName] = useState(configFileName);
	const [downloaded, setDownloaded] = useState(false);

	useEffect(() => {
		let cancelled = false;
		setError(null);
		loadCatalog()
			.then((loaded) => !cancelled && setCatalog(loaded))
			.catch((reason) => !cancelled && setError(reason.message));
		return () => {
			cancelled = true;
		};
	}, [attempt]);

	useEffect(() => {
		if (!copied) return;
		const timer = setTimeout(() => setCopied(null), 1500);
		return () => clearTimeout(timer);
	}, [copied]);

	const order = useMemo(() => catalog?.tabs.flatMap((tab) => tab.items.map((item) => item.key)) ?? [], [catalog]);
	const known = useMemo(() => new Set(order), [order]);

	if (error) {
		return (
			<div className="wu-builder not-content">
				<p className="wu-builder-status">
					Couldn't load the catalog from GitHub ({error}). You can still export a config from WinUtil itself.
				</p>
				<button type="button" className="wu-builder-button" onClick={() => setAttempt((count) => count + 1)}>
					Try again
				</button>
			</div>
		);
	}

	if (!catalog) {
		return (
			<div className="wu-builder not-content">
				<p className="wu-builder-status">Loading the catalog from the latest WinUtil release…</p>
			</div>
		);
	}

	const keys = order.filter((key) => selected.has(key));
	const json = JSON.stringify(keys, null, 2);
	// Runs the release the catalog came from, so a release published in the meantime can't reject keys it dropped.
	const script = `https://github.com/${REPO}/releases/download/${catalog.release.tag}/winutil.ps1`;
	const command = `& ([ScriptBlock]::Create((irm "${script}"))) -Config "$env:USERPROFILE\\Downloads\\${fileName}"`;
	const tab = catalog.tabs.find((candidate) => candidate.id === tabId);
	const text = query.trim().toLowerCase();
	const groups = groupByCategory(
		tab.items.filter((item) => !text || `${item.name} ${item.description} ${item.key}`.toLowerCase().includes(text))
	);

	const toggle = (key) =>
		setSelected((current) => {
			const next = new Set(current);
			if (next.has(key)) next.delete(key);
			else next.add(key);
			return next;
		});

	// Like the preset buttons in WinUtil, a preset replaces that part of the selection rather than adding to it.
	const applyPreset = (preset) =>
		setSelected((current) => {
			const next = new Set([...current].filter((key) => !key.startsWith(tab.presetScope)));
			preset.keys.filter((key) => known.has(key)).forEach((key) => next.add(key));
			return next;
		});

	const clearTab = () => {
		const inTab = new Set(tab.items.map((item) => item.key));
		setSelected((current) => new Set([...current].filter((key) => !inTab.has(key))));
	};

	const openConfig = async (event) => {
		const file = event.target.files[0];
		event.target.value = '';
		if (!file) return;
		let loaded;
		try {
			loaded = readConfig(JSON.parse(await file.text()));
		} catch {
			setNotice({ kind: 'error', text: `${file.name} isn't a WinUtil config file.` });
			return;
		}
		const skipped = loaded.filter((key) => !known.has(key));
		// Like WinUtil's import, a file with nothing usable in it leaves the current selection alone.
		if (skipped.length === loaded.length) {
			const text = loaded.length
				? `None of the keys in ${file.name} are in WinUtil ${catalog.release.tag}: ${skipped.join(', ')}`
				: `${file.name} doesn't have any WinUtil selections in it.`;
			setNotice({ kind: 'error', text });
			return;
		}
		setSelected(new Set(loaded.filter((key) => known.has(key))));
		if (skipped.length) {
			const message = `Left out ${skipped.length} key(s) that WinUtil ${catalog.release.tag} doesn't have: ${skipped.join(', ')}`;
			setNotice({ kind: 'warning', text: message });
		} else {
			setNotice({ kind: 'info', text: `Loaded ${loaded.length} selection(s) from ${file.name}.` });
		}
	};

	const copy = async (what, value) => {
		try {
			await navigator.clipboard.writeText(value);
			setCopied(what);
		} catch {
			setCopied(null);
			setNotice({ kind: 'error', text: "Couldn't copy to the clipboard. Select the text and copy it instead." });
		}
	};

	// The first download uses the name the command already shows; later ones get a new name and update the command.
	const download = () => {
		const name = downloaded ? configFileName() : fileName;
		setFileName(name);
		setDownloaded(true);
		const url = URL.createObjectURL(new Blob([json], { type: 'application/json' }));
		const link = Object.assign(document.createElement('a'), { href: url, download: name });
		link.click();
		// Revoking in the same task can cancel the download before the browser has read the blob.
		setTimeout(() => URL.revokeObjectURL(url));
	};

	return (
		<div className="wu-builder not-content">
			<div className="wu-builder-toolbar">
				<p className="wu-builder-release">
					Catalog from{' '}
					<a href={catalog.release.url} target="_blank" rel="noreferrer">
						WinUtil {catalog.release.tag}
					</a>
				</p>
				<label className="wu-builder-button">
					Open a config
					<input type="file" accept=".json,application/json" onChange={openConfig} />
				</label>
			</div>
			{notice && <p className={`wu-builder-notice wu-builder-notice--${notice.kind}`}>{notice.text}</p>}

			<div className="wu-builder-picker">
				<div className="wu-builder-tabs">
					{catalog.tabs.map((candidate) => {
						const count = candidate.items.filter((item) => selected.has(item.key)).length;
						return (
							<button
								key={candidate.id}
								type="button"
								className="wu-builder-tab"
								aria-pressed={candidate.id === tabId}
								onClick={() => setTabId(candidate.id)}
							>
								{candidate.label}
								{count > 0 && <span className="wu-builder-count">{count}</span>}
							</button>
						);
					})}
				</div>
				<div className="wu-builder-controls">
					<div className="wu-builder-search">
						<Icon name="magnifier" />
						<input
							type="search"
							placeholder={`Search ${tab.label.toLowerCase()}`}
							aria-label={`Search ${tab.label.toLowerCase()}`}
							autoComplete="off"
							spellCheck="false"
							value={query}
							onChange={(event) => setQuery(event.target.value)}
						/>
					</div>
					{tab.presets?.map((preset) => (
						<button key={preset.label} type="button" className="wu-builder-chip" onClick={() => applyPreset(preset)}>
							{preset.label}
						</button>
					))}
					<button type="button" className="wu-builder-chip" onClick={clearTab}>
						Clear
					</button>
				</div>
				<div className="wu-builder-list">
					{groups.length === 0 && (
						<p className="wu-builder-status">
							No {tab.label.toLowerCase()} match "{query.trim()}".
						</p>
					)}
					{groups.map((group) => (
						<section key={group.name}>
							<h3 className="wu-builder-group">{group.name}</h3>
							<ul>
								{group.items.map((item) => (
									<li key={item.key} className="wu-builder-item">
										<label>
											<input type="checkbox" checked={selected.has(item.key)} onChange={() => toggle(item.key)} />
											<span className="wu-builder-item-text">
												<span className="wu-builder-item-name">{item.name}</span>
												<span className="wu-builder-item-description">{item.description}</span>
											</span>
										</label>
										{item.link && (
											<a
												href={item.link}
												target="_blank"
												rel="noreferrer"
												className="wu-builder-item-link"
												aria-label={`More about ${item.name}`}
											>
												<Icon name="external" />
											</a>
										)}
									</li>
								))}
							</ul>
						</section>
					))}
				</div>
			</div>

			<div className="wu-builder-output">
				<div className="wu-builder-output-header">
					<span>{keys.length} selected</span>
					<button type="button" className="wu-builder-button" disabled={!keys.length} onClick={() => copy('json', json)}>
						{copied === 'json' ? 'Copied' : 'Copy JSON'}
					</button>
					<button
						type="button"
						className="wu-builder-button wu-builder-button--primary"
						disabled={!keys.length}
						onClick={download}
					>
						Download config
					</button>
				</div>
				{keys.length > 0 ? (
					<pre className="wu-builder-json">{json}</pre>
				) : (
					<p className="wu-builder-status">Select at least one item to build a config.</p>
				)}
				<p className="wu-builder-hint">Then run this in an elevated PowerShell window:</p>
				<div className="wu-builder-command">
					<code>{command}</code>
					<button type="button" className="wu-builder-button" onClick={() => copy('command', command)}>
						{copied === 'command' ? 'Copied' : 'Copy'}
					</button>
				</div>
			</div>
		</div>
	);
}

// Shows what each tweak in the latest release changes, and what Undo puts back, without reading the raw JSON.
import { useEffect, useMemo, useState } from 'react';
import Icon from '../docs/Icon.jsx';
import { RATE_LIMITED, loadReleaseConfig } from '../../lib/winutil-release.js';
import './TweakExplorer.css';

const PRESETS = ['Standard', 'Minimal', 'Advanced'];
const CHANGES = [
	{ id: 'registry', label: 'Registry' },
	{ id: 'services', label: 'Services' },
	{ id: 'script', label: 'Scripts' },
];

// The scripts are stored indented to match the JSON around them.
function dedent(blocks) {
	return blocks
		.map((block) => {
			const lines = block.replace(/^\s*\n|\s+$/g, '').split('\n');
			const indent = Math.min(...lines.filter((line) => line.trim()).map((line) => line.match(/^ */)[0].length));
			return lines.map((line) => line.slice(indent)).join('\n');
		})
		.join('\n\n');
}

function toTweak(key, entry, presets) {
	const registry = entry.registry ?? [];
	const states = entry.Type === 'Combobox' ? Object.keys(registry[0]?.Values ?? {}) : [];
	const services = entry.service ?? [];
	const script = dedent(entry.InvokeScript ?? []);
	const undoScript = dedent(entry.UndoScript ?? []);
	const appx = entry.appx ?? [];
	return {
		key,
		name: entry.Content,
		description: entry.Description,
		category: entry.category,
		toggle: entry.Type === 'Toggle',
		link: entry.link?.replace(/^https?:\/\/[^/]+/, ''),
		registry,
		states,
		services,
		script,
		undoScript,
		appx,
		presets: PRESETS.filter((name) => presets[name]?.includes(key)),
		hasUndo: !states.length && (
			registry.some((item) => !item.Values && Object.hasOwn(item, 'OriginalValue')) ||
			services.some((item) => Object.hasOwn(item, 'OriginalType')) || Boolean(undoScript)
		),
		// Dropdowns use manual state selection rather than the checkbox Undo action.
		oneWay: states.length
			? 'No Undo action'
			: appx.length ? 'AppX removal has no undo' : script && !undoScript ? 'Script has no undo' : null,
		haystack: [
			entry.Content,
			entry.Description,
			key,
			...registry.map((item) => `${item.Path}\\${item.Name}`),
			...services.map((item) => item.Name),
			script,
			undoScript,
			...appx,
		]
			.join('\n')
			.toLowerCase(),
	};
}

function registryValue(value) {
	return value === '<RemoveEntry>' ? <em>removed</em> : value;
}

function TweakDetails({ tweak }) {
	const [applied, undone] = tweak.toggle ? ['When on', 'When off'] : ['Applied', 'Undo restores'];
	return (
		<div className="wu-explorer-details">
			{tweak.registry.length > 0 && (
				<section>
					<h4>Registry</h4>
					<div className="wu-explorer-table">
						<table>
							<thead>
								<tr>
									<th>Value</th>
									<th>Type</th>
									{(tweak.states.length ? tweak.states : [applied, undone]).map((label) => (
										<th key={label}>{label}</th>
									))}
								</tr>
							</thead>
							<tbody>
								{tweak.registry.map((item) => (
									<tr key={`${item.Path}\\${item.Name}`}>
										<td>
											<span className="wu-explorer-path">{item.Path}\</span>
											{item.Name}
										</td>
										<td data-label="Type">{item.Type}</td>
										{tweak.states.length ? (
											tweak.states.map((state) => (
												<td key={state} data-label={state}>{registryValue(item.Values[state])}</td>
											))
										) : (
											<>
												<td data-label={applied}>{registryValue(item.Value)}</td>
												<td data-label={undone}>{registryValue(item.OriginalValue)}</td>
											</>
										)}
									</tr>
								))}
							</tbody>
						</table>
					</div>
					{tweak.states.length > 0 && (
						<p className="wu-explorer-note">
							Changes apply immediately when you choose a state in WinUtil. To revert, choose another state;
							Undo Selected Tweaks does not manage this control.
						</p>
					)}
				</section>
			)}
			{tweak.services.length > 0 && (
				<section>
					<h4>Services</h4>
					<div className="wu-explorer-table">
						<table>
							<thead>
								<tr>
									<th>Service</th>
									<th>{applied}</th>
									<th>{undone}</th>
								</tr>
							</thead>
							<tbody>
								{tweak.services.map((item) => (
									<tr key={item.Name}>
										<td>{item.Name}</td>
										<td data-label={applied}>{item.StartupType}</td>
										<td data-label={undone}>{item.OriginalType}</td>
									</tr>
								))}
							</tbody>
						</table>
					</div>
					<p className="wu-explorer-note">
						Applying skips a service whose startup type isn't the original one, so changes you made yourself are kept.
					</p>
				</section>
			)}
			{tweak.appx.length > 0 && (
				<section>
					<h4>Removes AppX packages</h4>
					<p className="wu-explorer-note">{tweak.appx.join(', ')}. Undo does not reinstall them.</p>
				</section>
			)}
			{tweak.script && (
				<details>
					<summary>Script it runs</summary>
					<pre>{tweak.script}</pre>
				</details>
			)}
			{tweak.undoScript && (
				<details>
					<summary>Undo script</summary>
					<pre>{tweak.undoScript}</pre>
				</details>
			)}
			<div className="wu-explorer-details-footer">
				<code>{tweak.key}</code>
				{tweak.link && <a href={tweak.link}>Reference page</a>}
			</div>
		</div>
	);
}

export default function TweakExplorer() {
	const [data, setData] = useState(null);
	const [error, setError] = useState(null);
	const [attempt, setAttempt] = useState(0);
	const [query, setQuery] = useState('');
	const [category, setCategory] = useState(null);
	const [preset, setPreset] = useState(null);
	const [changes, setChanges] = useState(() => new Set());
	const [hasUndoOnly, setHasUndoOnly] = useState(false);
	const [expanded, setExpanded] = useState(() => new Set());

	useEffect(() => {
		let cancelled = false;
		setError(null);
		loadReleaseConfig(['tweaks', 'preset'])
			.then(({ release, files: [tweaks, presets] }) => {
				if (cancelled) return;
				const list = Object.entries(tweaks)
					.filter(([key, entry]) =>
						/^WPF(?:Tweaks|Toggle)/.test(key) || (entry.Type === 'Combobox' && entry.registry?.[0]?.Values)
					)
					.map(([key, entry]) => toTweak(key, entry, presets));
				setData({ release, tweaks: list });
			})
			.catch((reason) => !cancelled && setError(reason.message));
		return () => {
			cancelled = true;
		};
	}, [attempt]);

	// WinUtil sorts categories by name; the z__ prefix is only there to push the advanced ones last.
	const categories = useMemo(
		() => [...new Set(data?.tweaks.map((tweak) => tweak.category))].sort((a, b) => a.localeCompare(b)),
		[data]
	);

	if (error) {
		return (
			<div className="wu-explorer not-content">
				<p className="wu-explorer-status">
					{error === RATE_LIMITED ? RATE_LIMITED : `Couldn't load the tweaks from GitHub (${error}).`}
				</p>
				<button type="button" className="wu-explorer-chip" onClick={() => setAttempt((count) => count + 1)}>
					Try again
				</button>
			</div>
		);
	}

	if (!data) {
		return (
			<div className="wu-explorer not-content">
				<p className="wu-explorer-status">Loading the tweaks from the latest WinUtil release…</p>
			</div>
		);
	}

	const text = query.trim().toLowerCase();
	const visible = data.tweaks.filter(
		(tweak) =>
			(!text || tweak.haystack.includes(text)) &&
			(!category || tweak.category === category) &&
			(!preset || tweak.presets.includes(preset)) &&
			(!changes.has('registry') || tweak.registry.length > 0) &&
			(!changes.has('services') || tweak.services.length > 0) &&
			(!changes.has('script') || tweak.script) &&
			(!hasUndoOnly || tweak.hasUndo)
	);

	const toggleIn = (setter, value) =>
		setter((current) => {
			const next = new Set(current);
			if (next.has(value)) next.delete(value);
			else next.add(value);
			return next;
		});

	const chip = (label, pressed, onClick) => (
		<button key={label} type="button" className="wu-explorer-chip" aria-pressed={pressed} onClick={onClick}>
			{label}
		</button>
	);

	return (
		<div className="wu-explorer not-content">
			<div className="wu-explorer-filters">
				<div className="wu-explorer-search">
					<Icon name="magnifier" />
					<input
						type="search"
						placeholder="Search names, registry paths, services, and scripts"
						aria-label="Search tweaks"
						autoComplete="off"
						spellCheck="false"
						value={query}
						onChange={(event) => setQuery(event.target.value)}
					/>
				</div>
				<div className="wu-explorer-filter-row">
					<span>Category</span>
					{chip('All', !category, () => setCategory(null))}
					{categories.map((name) =>
						chip(name.replace(/^z__/, ''), category === name, () => setCategory(category === name ? null : name))
					)}
				</div>
				<div className="wu-explorer-filter-row">
					<span>Preset</span>
					{chip('Any', !preset, () => setPreset(null))}
					{PRESETS.map((name) => chip(name, preset === name, () => setPreset(preset === name ? null : name)))}
				</div>
				<div className="wu-explorer-filter-row">
					<span>Changes</span>
					{CHANGES.map(({ id, label }) => chip(label, changes.has(id), () => toggleIn(setChanges, id)))}
					{chip('Has undo', hasUndoOnly, () => setHasUndoOnly(!hasUndoOnly))}
				</div>
			</div>

			<p className="wu-explorer-note">
				An undo action may reset defaults or reinstall software without restoring deleted data or your previous settings.
			</p>
			<p className="wu-explorer-status">
				Showing {visible.length} of {data.tweaks.length} tweaks from{' '}
				<a href={data.release.url} target="_blank" rel="noreferrer">
					WinUtil {data.release.tag}
				</a>
			</p>

			<ul className="wu-explorer-list">
				{visible.map((tweak) => {
					const open = expanded.has(tweak.key);
					return (
						<li key={tweak.key} className="wu-explorer-tweak">
							<button
								type="button"
								className="wu-explorer-summary"
								aria-expanded={open}
								onClick={() => toggleIn(setExpanded, tweak.key)}
							>
								<span className="wu-explorer-summary-text">
									<span className="wu-explorer-name">{tweak.name}</span>
									<span className="wu-explorer-description">{tweak.description}</span>
									<span className="wu-explorer-badges">
										<span className="wu-explorer-badge">{tweak.category.replace(/^z__/, '')}</span>
										{tweak.presets.map((name) => (
											<span key={name} className="wu-explorer-badge wu-explorer-badge--preset">
												{name}
											</span>
										))}
										{tweak.registry.length > 0 && (
											<span className="wu-explorer-badge">{tweak.registry.length} registry</span>
										)}
										{tweak.services.length > 0 && (
											<span className="wu-explorer-badge">
												{tweak.services.length} {tweak.services.length === 1 ? 'service' : 'services'}
											</span>
										)}
										{tweak.script && <span className="wu-explorer-badge">Script</span>}
										{tweak.hasUndo && (
											<span className="wu-explorer-badge wu-explorer-badge--good">Has undo</span>
										)}
										{tweak.oneWay && (
											<span className="wu-explorer-badge wu-explorer-badge--warn">{tweak.oneWay}</span>
										)}
									</span>
								</span>
								<Icon name="down-caret" className="wu-explorer-caret" />
							</button>
							{open && <TweakDetails tweak={tweak} />}
						</li>
					);
				})}
			</ul>
			{visible.length === 0 && <p className="wu-explorer-status">No tweaks match these filters.</p>}
		</div>
	);
}

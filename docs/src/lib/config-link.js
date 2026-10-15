// Config Builder links carry the selection in the hash, e.g. /config-builder/#WPFInstall7zip,WPFTweaksTelemetry.
export function configLink(keys) {
	return `/config-builder/#${keys.join(',')}`;
}

// Starlight puts heading ids in the hash too, so anything that isn't a list of WPF keys is left alone.
export function readConfigLink(hash) {
	const keys = hash.replace(/^#/, '').split(',');
	return keys.every((key) => /^WPF[\w-]+$/.test(key)) ? keys : null;
}

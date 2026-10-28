// Config Builder links carry the selection in the hash, e.g. /config-builder/#WPFInstall7zip,WPFTweaksTelemetry.
export function configLink(keys) {
	return `/config-builder/#${keys.join(',')}`;
}

// Starlight puts heading ids in the hash too, so anything that isn't a list of WPF keys is left alone.
// Some apps encode the commas when passing a link along, so %2C counts as a comma.
export function readConfigLink(hash) {
	const keys = hash.replace(/^#/, '').replace(/%2C/gi, ',').split(',');
	return keys.every((key) => /^WPF[\w-]+$/.test(key)) ? keys : null;
}

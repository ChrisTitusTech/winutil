// Current site theme ('light' or 'dark'), kept in sync with <html data-theme>.
import { useSyncExternalStore } from 'react';

const read = () => (document.documentElement.dataset.theme === 'light' ? 'light' : 'dark');

const subscribe = (onChange) => {
	const observer = new MutationObserver(onChange);
	observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
	return () => observer.disconnect();
};

export default function useStarlightTheme() {
	// The site defaults to dark, so that's what renders on the server.
	return useSyncExternalStore(subscribe, read, () => 'dark');
}

// Shares the `starlight-theme` storage key with ThemeProvider.astro, which applies the theme before first paint.
import Icon from './Icon.jsx';
import useStarlightTheme from '../../hooks/useStarlightTheme.js';

const STORAGE_KEY = 'starlight-theme';

export default function ThemeToggle() {
	const label = `Switch to ${useStarlightTheme() === 'light' ? 'dark' : 'light'} theme`;
	const toggle = () => {
		const next = document.documentElement.dataset.theme === 'light' ? 'dark' : 'light';
		document.documentElement.dataset.theme = next;
		try {
			localStorage.setItem(STORAGE_KEY, next);
		} catch {
			// Storage can be blocked; the theme still changes for this page.
		}
	};
	return (
		<button
			type="button"
			className="docs-theme-toggle"
			onClick={toggle}
			aria-label={label}
			title={label}
		>
			<Icon name="sun" className="docs-theme-sun" />
			<Icon name="moon" className="docs-theme-moon" />
		</button>
	);
}

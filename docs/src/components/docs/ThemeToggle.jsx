// Shares the `starlight-theme` storage key with ThemeProvider.astro, which applies the theme before first paint.
import Icon from './Icon.jsx';

const STORAGE_KEY = 'starlight-theme';

export default function ThemeToggle() {
	const toggle = () => {
		const next = document.documentElement.dataset.theme === 'light' ? 'dark' : 'light';
		document.documentElement.dataset.theme = next;
		try {
			localStorage.setItem(STORAGE_KEY, next);
		} catch {}
	};
	return (
		<button
			type="button"
			className="docs-theme-toggle"
			onClick={toggle}
			aria-label="Toggle light and dark theme"
			title="Toggle theme"
		>
			<Icon name="sun" className="docs-theme-sun" />
			<Icon name="moon" className="docs-theme-moon" />
		</button>
	);
}

// Icons from src/assets/icons/, inlined so they take on the surrounding text color.
const files = import.meta.glob('../../assets/icons/*.svg', { query: '?raw', import: 'default', eager: true });
const icons = Object.fromEntries(
	Object.entries(files).map(([path, svg]) => [path.match(/([\w-]+)\.svg$/)[1], svg.match(/<svg[^>]*>([\s\S]*)<\/svg>/)[1]])
);

export default function Icon({ name, size = '1em', className = '', label }) {
	return (
		<svg
			className={`docs-icon ${className}`.trim()}
			width={size}
			height={size}
			viewBox="0 0 24 24"
			fill="currentColor"
			aria-hidden={label ? undefined : 'true'}
			aria-label={label}
			role={label ? 'img' : undefined}
			dangerouslySetInnerHTML={{ __html: icons[name] ?? '' }}
		/>
	);
}

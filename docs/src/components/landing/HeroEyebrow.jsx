// Hero eyebrow text with a periodic shine. ShinyText can't resolve CSS variables, so colors are picked per theme.
import ShinyText from '../react-bits/ShinyText.jsx';
import useStarlightTheme from '../../hooks/useStarlightTheme.js';
import useAccentColor from '../../hooks/useAccentColor.js';

export default function HeroEyebrow({ text }) {
	const theme = useStarlightTheme();
	const light = theme === 'light';
	const accent = useAccentColor();
	return (
		<ShinyText
			text={text}
			color={light ? '#525252' : '#a3a3a3'}
			shineColor={light ? accent : '#ffffff'}
			speed={3}
			delay={1.5}
		/>
	);
}

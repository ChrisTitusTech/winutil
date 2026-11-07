// Interactive dot field behind the hero.
import DotGrid from '../react-bits/DotGrid.jsx';
import useStarlightTheme from '../../hooks/useStarlightTheme.js';
import useAccentColor from '../../hooks/useAccentColor.js';

export default function HeroDotGrid() {
	const theme = useStarlightTheme();
	const accent = useAccentColor();
	return (
		<DotGrid
			dotSize={3}
			gap={26}
			baseColor={theme === 'light' ? '#cfd6e2' : '#263043'}
			activeColor={accent}
			proximity={150}
			shockRadius={240}
			shockStrength={3}
			glow={0.4}
			fade={0.15}
		/>
	);
}

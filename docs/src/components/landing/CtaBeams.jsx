// Light beams behind the final call to action.
import Beams from '../react-bits/Beams.jsx';
import useStarlightTheme from '../../hooks/useStarlightTheme.js';
import useAccentColor from '../../hooks/useAccentColor.js';

export default function CtaBeams() {
	const theme = useStarlightTheme();
	const accent = useAccentColor();
	return (
		<Beams
			color={accent}
			rotation={28}
			speed={0.6}
			beamWidth={160}
			brightness={1.2}
			grain={0.2}
			fade={0.5}
			opacity={theme === 'light' ? 0.35 : 0.6}
			lightMode={theme === 'light'}
		/>
	);
}

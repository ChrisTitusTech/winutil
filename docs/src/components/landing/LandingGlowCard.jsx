// Solution card whose border lights up near the pointer.
import BorderGlow from '../react-bits/BorderGlow.jsx';
import useStarlightTheme from '../../hooks/useStarlightTheme.js';

const BLUES = ['var(--wu-accent)', '#38bdf8', '#6366f1'];

export default function LandingGlowCard({ children, className = '' }) {
	const theme = useStarlightTheme();
	return (
		<BorderGlow
			className={className}
			backgroundColor={theme === 'light' ? '#ffffff' : '#0d0d0d'}
			glowColor="216 100 62"
			colors={BLUES}
			borderRadius={16}
			glowRadius={28}
			glowIntensity={theme === 'light' ? 0.7 : 1}
			fillOpacity={0.25}
		>
			{children}
		</BorderGlow>
	);
}

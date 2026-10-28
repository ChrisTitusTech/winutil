// The site accent as a hex color, for canvas/WebGL components that can't read CSS variables.
import { useEffect, useState } from 'react';

let accent;

function readAccent() {
	const value = getComputedStyle(document.documentElement).getPropertyValue('--wu-accent').trim();
	// A canvas normalizes any CSS color to hex.
	const context = document.createElement('canvas').getContext('2d');
	context.fillStyle = value;
	return context.fillStyle;
}

export default function useAccentColor() {
	const [color, setColor] = useState(accent);
	useEffect(() => {
		accent ??= readAccent();
		setColor(accent);
	}, []);
	return color;
}

// Returns the id of the last heading that has scrolled past the header.
import { useEffect, useState } from 'react';

export default function useActiveHeading(ids) {
	const [active, setActive] = useState(ids[0]);
	const key = ids.join(' ');

	useEffect(() => {
		const headings = key
			.split(' ')
			.map((id) => document.getElementById(id))
			.filter(Boolean);
		if (!headings.length) return;
		let frame = 0;
		const update = () => {
			frame = 0;
			const line = (document.querySelector('header.header')?.getBoundingClientRect().height ?? 64) + 96;
			let current = headings[0];
			for (const heading of headings) {
				if (heading.getBoundingClientRect().top <= line) current = heading;
				else break;
			}
			// The last heading can't always scroll up to the line, so the bottom of the page counts as reaching it.
			if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) {
				current = headings[headings.length - 1];
			}
			setActive(current.id);
		};
		const onScroll = () => {
			if (!frame) frame = requestAnimationFrame(update);
		};
		update();
		window.addEventListener('scroll', onScroll, { passive: true });
		window.addEventListener('resize', onScroll, { passive: true });
		return () => {
			cancelAnimationFrame(frame);
			window.removeEventListener('scroll', onScroll);
			window.removeEventListener('resize', onScroll);
		};
	}, [key]);

	return active;
}

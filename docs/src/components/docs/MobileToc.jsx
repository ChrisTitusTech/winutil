import { useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';
import { flattenToc } from './TableOfContents.jsx';
import useActiveHeading from '../../hooks/useActiveHeading.js';

export default function MobileToc({ items }) {
	const flat = flattenToc(items);
	const active = useActiveHeading(flat.map((item) => item.slug));
	const [open, setOpen] = useState(false);
	const rootRef = useRef(null);
	const current = flat.find((item) => item.slug === active);

	useEffect(() => {
		if (!open) return;
		const onClick = (event) => {
			if (!rootRef.current?.contains(event.target)) setOpen(false);
		};
		const onKey = (event) => {
			if (event.key !== 'Escape') return;
			// Closing hides a focused link in the list, so focus goes back to the toggle.
			if (rootRef.current?.contains(document.activeElement)) rootRef.current.querySelector('button').focus();
			setOpen(false);
		};
		window.addEventListener('click', onClick);
		window.addEventListener('keydown', onKey);
		return () => {
			window.removeEventListener('click', onClick);
			window.removeEventListener('keydown', onKey);
		};
	}, [open]);

	return (
		<nav className="docs-mobile-toc" aria-label="On this page" ref={rootRef}>
			<button type="button" className="docs-mobile-toc-toggle" aria-expanded={open} onClick={() => setOpen(!open)}>
				<span className="docs-mobile-toc-label">
					On this page
					<Icon name="right-caret" className="docs-mobile-toc-caret" />
				</span>
				<span className="docs-mobile-toc-current">{current?.text}</span>
			</button>
			{open && (
				<ul className="docs-mobile-toc-list">
					{flat.map((item) => (
						<li key={item.slug}>
							<a
								href={`#${item.slug}`}
								className={`docs-toc-link docs-toc-depth-${item.depth}`}
								aria-current={item.slug === active ? 'true' : undefined}
								onClick={() => setOpen(false)}
							>
								{item.text}
							</a>
						</li>
					))}
				</ul>
			)}
		</nav>
	);
}

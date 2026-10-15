import { useLayoutEffect, useRef, useState } from 'react';
import useActiveHeading from '../../hooks/useActiveHeading.js';

export const flattenToc = (items) => items.flatMap((item) => [item, ...flattenToc(item.children)]);

export default function TableOfContents({ items }) {
	const flat = flattenToc(items);
	const active = useActiveHeading(flat.map((item) => item.slug));
	const listRef = useRef(null);
	const [marker, setMarker] = useState(null);

	useLayoutEffect(() => {
		if (!active) return;
		const link = listRef.current?.querySelector(`a[href="#${CSS.escape(active)}"]`);
		if (link) setMarker({ top: link.offsetTop, height: link.offsetHeight });
	}, [active]);

	return (
		<nav className="docs-toc" aria-labelledby="docs-toc-heading">
			<h2 id="docs-toc-heading">On this page</h2>
			<div className="docs-toc-track" ref={listRef}>
				{marker && (
					<span
						className="docs-toc-marker"
						aria-hidden="true"
						style={{ transform: `translateY(${marker.top}px)`, height: marker.height }}
					/>
				)}
				<ul>
					{flat.map((item) => (
						<li key={item.slug}>
							<a
								href={`#${item.slug}`}
								className={`docs-toc-link docs-toc-depth-${item.depth}`}
								aria-current={item.slug === active ? 'true' : undefined}
							>
								{item.text}
							</a>
						</li>
					))}
				</ul>
			</div>
		</nav>
	);
}

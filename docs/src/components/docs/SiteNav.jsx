import { useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';

const externalProps = (link) => (link.external ? { target: '_blank', rel: 'noreferrer' } : {});

function Dropdown({ label, links, open, onToggle }) {
	return (
		<div className={`docs-nav-dropdown${open ? ' is-open' : ''}`}>
			<button type="button" className="docs-nav-link" aria-expanded={open} onClick={onToggle}>
				{label}
				<Icon name="down-caret" className="docs-nav-caret" />
			</button>
			<div className="docs-nav-menu">
				{links.map((link) => (
					<a key={link.href} href={link.href} {...externalProps(link)}>
						{link.label}
						{link.external && <Icon name="external" />}
					</a>
				))}
			</div>
		</div>
	);
}

export default function SiteNav({ groups, store, showMenuButton }) {
	const [openGroup, setOpenGroup] = useState(null);
	const [menuOpen, setMenuOpen] = useState(false);
	const rootRef = useRef(null);

	useEffect(() => {
		const onClick = (event) => {
			if (!rootRef.current?.contains(event.target)) setOpenGroup(null);
		};
		const onKey = (event) => {
			if (event.key === 'Escape') {
				setOpenGroup(null);
				setMenuOpen(false);
			}
		};
		const wide = matchMedia('(min-width: 50em)');
		const onResize = () => setMenuOpen(false);
		window.addEventListener('click', onClick);
		window.addEventListener('keydown', onKey);
		wide.addEventListener('change', onResize);
		return () => {
			window.removeEventListener('click', onClick);
			window.removeEventListener('keydown', onKey);
			wide.removeEventListener('change', onResize);
		};
	}, []);

	return (
		<div className="docs-nav" ref={rootRef}>
			<nav className="docs-nav-desktop" aria-label="Top">
				{groups.map((group) => (
					<Dropdown
						key={group.label}
						label={group.label}
						links={group.links}
						open={openGroup === group.label}
						onToggle={() => setOpenGroup(openGroup === group.label ? null : group.label)}
					/>
				))}
				<a className="docs-nav-link" href={store.href} target="_blank" rel="noreferrer">
					{store.label}
				</a>
			</nav>
			{showMenuButton && (
				<div className="docs-nav-mobile">
					<button
						type="button"
						className="docs-icon-button"
						aria-expanded={menuOpen}
						aria-controls="docs-nav-panel"
						aria-label="Site navigation"
						onClick={() => setMenuOpen(!menuOpen)}
					>
						<Icon name={menuOpen ? 'close' : 'bars'} size="1.25rem" />
					</button>
					<div id="docs-nav-panel" className="docs-nav-panel" hidden={!menuOpen}>
						{groups.map((group) => (
							<div key={group.label} className="docs-nav-panel-group">
								<p>{group.label}</p>
								{group.links.map((link) => (
									<a key={link.href} href={link.href} {...externalProps(link)}>
										{link.label}
									</a>
								))}
							</div>
						))}
						<a className="docs-nav-panel-store" href={store.href} target="_blank" rel="noreferrer">
							{store.label}
						</a>
					</div>
				</div>
			)}
		</div>
	);
}

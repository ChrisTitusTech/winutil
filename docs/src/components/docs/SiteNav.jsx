import { useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';

const externalProps = (link) => (link.external ? { target: '_blank', rel: 'noreferrer' } : {});

// Closes once focus moves out of it, so a keyboard user tabbing on doesn't leave the menu over the page.
const closeOnBlur = (close) => (event) => {
	if (!event.currentTarget.contains(event.relatedTarget)) close();
};

function Dropdown({ label, links, open, onToggle, onClose }) {
	return (
		<div className={`docs-nav-dropdown${open ? ' is-open' : ''}`} onBlur={closeOnBlur(onClose)}>
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

export default function SiteNav({ groups, links, showMenuButton }) {
	const [openGroup, setOpenGroup] = useState(null);
	const [menuOpen, setMenuOpen] = useState(false);
	const rootRef = useRef(null);

	useEffect(() => {
		// The path as it was when clicked: the menu button swaps its icon, so event.target may already be detached.
		const onClick = (event) => {
			if (event.composedPath().includes(rootRef.current)) return;
			setOpenGroup(null);
			setMenuOpen(false);
		};
		const onKey = (event) => {
			if (event.key !== 'Escape') return;
			// Closing hides a focused menu link, so focus goes back to the button that opened that menu.
			const owner = document.activeElement?.closest('.docs-nav-dropdown, .docs-nav-mobile');
			if (owner && rootRef.current?.contains(owner)) owner.querySelector('button')?.focus();
			setOpenGroup(null);
			setMenuOpen(false);
		};
		const wide = matchMedia('(min-width: 50em)');
		// The desktop and mobile menus swap at this width, so neither should still be open on the other side.
		const onResize = () => {
			setOpenGroup(null);
			setMenuOpen(false);
		};
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
						onClose={() => setOpenGroup((current) => (current === group.label ? null : current))}
					/>
				))}
				{links.map((link) => (
					<a key={link.href} className="docs-nav-link" href={link.href} {...externalProps(link)}>
						{link.label}
					</a>
				))}
			</nav>
			{showMenuButton && (
				<div className="docs-nav-mobile" onBlur={closeOnBlur(() => setMenuOpen(false))}>
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
						{links.map((link) => (
							<a key={link.href} href={link.href} {...externalProps(link)}>
								{link.label}
							</a>
						))}
					</div>
				</div>
			)}
		</div>
	);
}

// Opens the sidebar on narrow screens, with the same body attribute and inert handling as Starlight's toggle.
import { useEffect, useState } from 'react';
import Icon from './Icon.jsx';

export default function MobileMenuToggle() {
	const [open, setOpen] = useState(false);

	useEffect(() => {
		document.body.toggleAttribute('data-mobile-menu-expanded', open);
		document.querySelectorAll('.main-frame, .sl-skip-link').forEach((el) => el.toggleAttribute('inert', open));
	}, [open]);

	useEffect(() => {
		const onKey = (event) => event.key === 'Escape' && setOpen(false);
		const wide = matchMedia('(min-width: 50em)');
		const onResize = () => setOpen(false);
		window.addEventListener('keydown', onKey);
		wide.addEventListener('change', onResize);
		return () => {
			window.removeEventListener('keydown', onKey);
			wide.removeEventListener('change', onResize);
		};
	}, []);

	return (
		<button
			type="button"
			className="docs-menu-toggle print:hidden"
			aria-expanded={open}
			aria-controls="starlight__sidebar"
			aria-label="Menu"
			onClick={() => setOpen(!open)}
		>
			<Icon name={open ? 'close' : 'bars'} size="1.25rem" />
		</button>
	);
}

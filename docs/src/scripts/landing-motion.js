// Landing page animations: Lenis smooth scrolling plus GSAP entrance and scroll effects.
// None of it runs for visitors who prefer reduced motion.
import Lenis from 'lenis';
import 'lenis/dist/lenis.css';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { SplitText } from 'gsap/SplitText';
import { DrawSVGPlugin } from 'gsap/DrawSVGPlugin';

const WIDE = '(min-width: 60em)';
const EASE = 'power3.out';

const $ = (selector, scope = document) => scope.querySelector(selector);
const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];

// Fades elements in, in batches, as they scroll into view.
function reveal(targets, from = { opacity: 0, y: 24 }, to = {}) {
	const els = gsap.utils.toArray(targets);
	if (!els.length) return;
	gsap.set(els, from);
	ScrollTrigger.batch(els, {
		start: 'top 88%',
		once: true,
		onEnter: (batch) =>
			gsap.to(batch, {
				opacity: 1,
				x: 0,
				y: 0,
				scale: 1,
				filter: 'blur(0px)',
				duration: 0.9,
				ease: EASE,
				stagger: 0.07,
				overwrite: true,
				...to,
			}),
	});
}

// Words drift up out of a blur, one after another.
function blurWords(el, vars = {}) {
	const split = SplitText.create(el, { type: 'words', tag: 'span' });
	gsap.set(el, { visibility: 'visible' });
	return gsap.from(split.words, {
		opacity: 0,
		y: 18,
		filter: 'blur(10px)',
		duration: 0.9,
		ease: EASE,
		stagger: 0.06,
		...vars,
	});
}

function hero() {
	const section = $('.wu-hero');
	if (!section) return;
	const heading = $('h1', section);
	const tl = gsap.timeline({ defaults: { ease: EASE } });
	tl.fromTo('.wu-eyebrow', { opacity: 0, y: -10 }, { opacity: 1, y: 0, duration: 0.8 }, 0);
	if (heading) tl.add(blurWords(heading, { duration: 1, stagger: 0.07 }), 0.1);
	tl.fromTo('.wu-hero-tagline', { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.9 }, 0.5)
		.fromTo('.wu-hero-actions .wu-btn', { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.8, stagger: 0.08 }, 0.65)
		.fromTo('.wu-hero-caption', { opacity: 0 }, { opacity: 1, duration: 0.8 }, 0.85)
		.fromTo('.wu-hero-media', { opacity: 0, y: 48 }, { opacity: 1, y: 0, duration: 1.4, ease: 'expo.out' }, 0.35)
		.fromTo(
			'.wu-hero-bottom .wu-badges > *',
			{ opacity: 0, y: 12 },
			{ opacity: 1, y: 0, duration: 0.6, stagger: 0.06 },
			0.95
		);

	gsap.to('.wu-hero-dots', {
		opacity: 0.25,
		ease: 'none',
		scrollTrigger: { trigger: section, start: 'top top', end: 'bottom 25%', scrub: 0.6 },
	});
}

// Turns the trust bar into an endless strip that pauses on hover.
function trustStrip() {
	const bar = $('.wu-section--trust .wu-trust-bar');
	// A hidden bar has no width, and the fill loop below would never end.
	if (!bar?.offsetWidth) return;
	const viewport = document.createElement('div');
	viewport.className = 'wu-marquee';
	const track = document.createElement('div');
	track.className = 'wu-marquee-track';
	bar.replaceWith(viewport);
	viewport.append(track);
	track.append(bar);

	const cloneInto = (node) => {
		const copy = node.cloneNode(true);
		copy.setAttribute('aria-hidden', 'true');
		track.append(copy);
	};
	// Fill the width, then double it so sliding by half loops without a jump.
	const fill = () => {
		track.replaceChildren(bar);
		while (bar.offsetWidth && track.scrollWidth < viewport.clientWidth * 1.1) cloneInto(bar);
		[...track.children].forEach(cloneInto);
	};
	fill();
	// Rotating a phone or widening the window can leave half the track narrower than the strip, so refill it.
	window.addEventListener('resize', () => track.scrollWidth / 2 < viewport.clientWidth && fill());

	const loop = gsap.to(track, { xPercent: -50, ease: 'none', duration: 40, repeat: -1 });
	viewport.addEventListener('pointerenter', () => gsap.to(loop, { timeScale: 0, duration: 0.6, ease: 'power2.out' }));
	viewport.addEventListener('pointerleave', () => gsap.to(loop, { timeScale: 1, duration: 0.6, ease: 'power2.in' }));
}

// Rolls each stat digit like an odometer.
function odometers() {
	$$('.wu-stat-value').forEach((el) => {
		const value = el.textContent.trim();
		el.textContent = '';
		const label = document.createElement('span');
		label.className = 'sr-only';
		label.textContent = value;
		el.append(label);

		const strips = [];
		for (const char of value) {
			const digit = document.createElement('span');
			digit.className = 'wu-odo-digit';
			digit.setAttribute('aria-hidden', 'true');
			if (/\d/.test(char)) {
				const strip = document.createElement('span');
				strip.className = 'wu-odo-strip';
				for (let i = 0; i < 20; i++) {
					const numeral = document.createElement('span');
					numeral.textContent = String(i % 10);
					strip.append(numeral);
				}
				digit.append(strip);
				strips.push({ strip, n: Number(char) });
			} else {
				digit.textContent = char;
			}
			el.append(digit);
		}

		// Each strip holds 0-9 twice, 5% of its height per numeral. Stopping in the second set gives a full spin first.
		ScrollTrigger.create({
			trigger: el,
			start: 'top 88%',
			once: true,
			onEnter: () =>
				strips.forEach(({ strip, n }, i) =>
					gsap.to(strip, { yPercent: -(10 + n) * 5, duration: 1.8 + i * 0.25, ease: 'power4.out' })
				),
		});
	});
	reveal('.wu-stat-label', { opacity: 0, y: 10 }, { delay: 0.4 });
}

function headings() {
	$$('.wu-section-head h2, .wu-section--cta h2').forEach((heading) =>
		blurWords(heading, { scrollTrigger: { trigger: heading, start: 'top 85%', once: true } })
	);
	reveal('.wu-section-head p, .wu-cta > p, .wu-cta > a, .wu-btn-row', { opacity: 0, y: 20 });
}

// Problem list items light up one by one as you read down.
function problemList() {
	const items = $$('.wu-problem-list li');
	if (!items.length) return;
	reveal(items, { opacity: 0, x: -16 });
	items.forEach((li) =>
		ScrollTrigger.create({
			trigger: li,
			start: 'top 70%',
			onEnter: () => li.classList.add('is-lit'),
			onLeaveBack: () => li.classList.remove('is-lit'),
		})
	);
}

// On wide screens the feature heading gets a progress bar and counter, and the card being read is highlighted.
function featureFocus(mm) {
	const section = $('.wu-section--features');
	if (!section) return;
	const cards = $$('.wu-feature-grid > *', section);
	reveal(cards, { opacity: 0, y: 32 });

	mm.add(WIDE, () => {
		const pad = (n) => String(n).padStart(2, '0');
		const total = pad(cards.length);
		const progress = document.createElement('div');
		progress.className = 'wu-feature-progress';
		progress.setAttribute('aria-hidden', 'true');
		progress.innerHTML = `
			<span class="wu-feature-count">01 / ${total}</span>
			<span class="wu-feature-bar"><span></span></span>`;
		$('.wu-section-head', section).append(progress);
		const count = $('.wu-feature-count', progress);

		gsap.fromTo(
			$('.wu-feature-bar span', progress),
			{ scaleX: 0 },
			{
				scaleX: 1,
				ease: 'none',
				scrollTrigger: { trigger: $('.wu-feature-grid', section), start: 'top 55%', end: 'bottom 55%', scrub: 0.4 },
			}
		);
		cards.forEach((card, i) =>
			ScrollTrigger.create({
				trigger: card,
				start: 'top 55%',
				end: 'bottom 55%',
				toggleClass: { targets: card, className: 'is-active' },
				onToggle: (self) => {
					if (self.isActive) count.textContent = `${pad(i + 1)} / ${total}`;
				},
			})
		);

		return () => {
			progress.remove();
			cards.forEach((card) => card.classList.remove('is-active'));
		};
	});
}

// The timeline line fills as you scroll, and a ring draws around each step number as you reach it.
function timeline() {
	const line = $('.wu-timeline');
	if (!line) return;
	gsap.fromTo(
		'.wu-timeline-progress',
		{ scaleY: 0 },
		{ scaleY: 1, ease: 'none', scrollTrigger: { trigger: line, start: 'top 60%', end: 'bottom 60%', scrub: 0.4 } }
	);
	$$('.wu-timeline-step', line).forEach((step) => {
		const number = $('.wu-timeline-number', step);
		number.insertAdjacentHTML(
			'beforeend',
			'<svg class="wu-ring" viewBox="0 0 44 44" aria-hidden="true"><circle cx="22" cy="22" r="21" /></svg>'
		);
		gsap.fromTo(
			$('.wu-ring circle', number),
			{ drawSVG: '0%' },
			{ drawSVG: '100%', ease: 'none', scrollTrigger: { trigger: step, start: 'top 80%', end: 'top 60%', scrub: 0.4 } }
		);
		ScrollTrigger.create({ trigger: step, start: 'top 60%', toggleClass: { targets: step, className: 'is-active' } });
	});
	reveal('.wu-timeline-step', { opacity: 0, y: 24 });
}

// The closing wordmark fills in from the bottom as the page runs out.
function outro() {
	if (!$('.wu-outro')) return;
	gsap.fromTo(
		'.wu-outro-fill',
		{ clipPath: 'inset(100% 0 0 0)' },
		{
			clipPath: 'inset(0% 0 0 0)',
			ease: 'none',
			scrollTrigger: { trigger: '.wu-outro', start: 'top 90%', end: 'bottom bottom', scrub: 0.5 },
		}
	);
}

// The back-to-top button's ring shows how far down the page you are.
function backToTop(lenis) {
	const button = $('.wu-to-top');
	if (!button) return;
	gsap.fromTo(
		$('.wu-to-top-ring', button),
		{ drawSVG: '0%' },
		{ drawSVG: '100%', ease: 'none', scrollTrigger: { start: 0, end: 'max', scrub: 0.3 } }
	);
	// Not toggleClass: that would hide the button again on reaching the end, the bottom of the page.
	ScrollTrigger.create({
		start: () => window.innerHeight * 0.8,
		end: 'max',
		onEnter: () => button.classList.add('is-visible'),
		onLeaveBack: () => button.classList.remove('is-visible'),
	});
	// Focus follows the scroll, like a skip link, so the next Tab carries on from the top instead of the footer.
	button.addEventListener('click', () =>
		lenis.scrollTo(0, {
			duration: 1.4,
			onComplete: () => {
				const title = document.getElementById('_top');
				title?.setAttribute('tabindex', '-1');
				title?.focus({ preventScroll: true });
			},
		})
	);
}

if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
	gsap.registerPlugin(ScrollTrigger, SplitText, DrawSVGPlugin);

	const lenis = new Lenis({
		autoRaf: false,
		anchors: true,
		// Let nested scroll areas (code blocks) and the search dialog scroll natively.
		allowNestedScroll: true,
		prevent: (node) => node.closest('dialog') !== null,
	});
	lenis.on('scroll', ScrollTrigger.update);
	gsap.ticker.add((time) => lenis.raf(time * 1000));
	gsap.ticker.lagSmoothing(0);

	const mm = gsap.matchMedia();
	hero();
	trustStrip();
	odometers();
	headings();
	problemList();
	reveal('.wu-solution-grid > astro-island', { opacity: 0, y: 32 });
	featureFocus(mm);
	timeline();
	reveal('.wu-benefit-list li', { opacity: 0, y: 16 });
	outro();
	backToTop(lenis);

	document.fonts.ready.then(() => ScrollTrigger.refresh());
}

// React Bits GlareHover (https://reactbits.dev/animations/glare-hover, JS + CSS variant). See LICENSE.md.
// Local changes: dropped the Next.js 'use client' directive.
import { useEffect, useRef } from 'react';

import './GlareHover.css';

const smootherstep = t => t * t * t * (t * (t * 6 - 15) + 10);

const bump = (t, center, half) => {
  const distance = Math.abs(t - center);
  return distance >= half ? 0 : smootherstep(1 - distance / half);
};

const PROFILES = {
  streak: (t, softness) => bump(t, 0.5, 0.06 + 0.16 * softness) + 0.32 * bump(t, 0.5, 0.5),
  twin: (t, softness) =>
    bump(t, 0.36, 0.08 + 0.18 * softness) + 0.85 * bump(t, 0.7, 0.03 + 0.06 * softness) + 0.26 * bump(t, 0.5, 0.5),
  sheen: (t, softness) => 0.55 * bump(t, 0.5, 0.25 + 0.25 * softness) + 0.3 * bump(t, 0.5, 0.5)
};

const gradient = (color, opacity, variant, softness) => {
  const profile = PROFILES[variant] ?? PROFILES.streak;
  const stops = Array.from({ length: 33 }, (_, index) => {
    const t = index / 32;
    const alpha = Math.round(Math.min(1, profile(t, softness) * opacity) * 1000) / 10;
    return `color-mix(in srgb, ${color} ${alpha}%, transparent) ${(t * 100).toFixed(1)}%`;
  });
  return `linear-gradient(90deg, ${stops.join(', ')})`;
};

const ease = t => (1 - Math.cos(Math.PI * t)) / 2;

const GlareHover = ({
  width = 'auto',
  height = 'auto',
  background = 'transparent',
  borderRadius = '10px',
  borderColor = 'transparent',
  children,
  glareColor = '#ffffff',
  glareOpacity = 0.5,
  glareAngle = -45,
  glareSize = 30,
  softness = 0.6,
  variant = 'streak',
  blendMode = 'screen',
  rimGlint = true,
  mode = 'hover',
  transitionDuration = 650,
  interval = 3,
  playOnce = false,
  intro = false,
  className = '',
  style = {}
}) => {
  const rootRef = useRef(null);
  const glareRef = useRef(null);
  const bandRef = useRef(null);
  const rimRef = useRef(null);
  const engineRef = useRef(null);
  const introRef = useRef(false);
  const settings = { glareAngle, glareSize, transitionDuration, interval, playOnce, intro };
  const settingsRef = useRef(settings);
  settingsRef.current = settings;

  useEffect(() => {
    const root = rootRef.current;
    const glare = glareRef.current;
    if (!root || !glare) return;

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const geometry = { band: 0, reach: 0, ux: 0, uy: -1, angle: 0 };
    const state = { pos: 0, velocity: 0, target: 0, presence: 0, presenceTarget: 0, sweep: null, visible: true };
    let raf = 0;
    let last = 0;
    let timer = 0;

    const bands = () => [bandRef.current, rimRef.current].filter(Boolean);

    const write = () => {
      const transform = `translate(-50%, -50%) rotate(${geometry.angle - 90}deg) translateX(${state.pos.toFixed(2)}px)`;
      for (const band of bands()) band.style.transform = transform;
      glare.style.opacity = state.presence.toFixed(3);
    };

    const measure = () => {
      const { glareAngle: angle, glareSize: size } = settingsRef.current;
      const width = root.clientWidth;
      const height = root.clientHeight;
      const radians = (angle * Math.PI) / 180;
      const ux = Math.sin(radians);
      const uy = -Math.cos(radians);
      const diagonal = Math.hypot(width, height);
      const band = Math.max(8, (diagonal * size) / 100);
      const reach = (Math.abs(width * ux) + Math.abs(height * uy)) / 2 + band / 2 + 2;
      const resting = !state.sweep && mode !== 'follow';
      Object.assign(geometry, { band, reach, ux, uy, angle });
      for (const element of bands()) {
        element.style.width = `${band}px`;
        element.style.height = `${diagonal + band}px`;
      }
      if (resting) state.pos = state.pos > 0 ? reach : -reach;
      write();
    };

    const frame = now => {
      const dt = Math.min(0.05, (now - last) / 1000 || 0);
      last = now;
      let moving = false;
      if (state.sweep) {
        const sweep = state.sweep;
        const t = Math.min(1, (now - sweep.start) / sweep.duration);
        state.pos = sweep.from + (sweep.to - sweep.from) * ease(t);
        if (t < 1) moving = true;
        else state.sweep = null;
      } else if (mode === 'follow') {
        const steps = Math.max(1, Math.ceil(dt / (1 / 120)));
        const h = dt / steps;
        for (let i = 0; i < steps; i++) {
          state.velocity += (170 * (state.target - state.pos) - 24 * state.velocity) * h;
          state.pos += state.velocity * h;
        }
        const tau = state.presenceTarget > state.presence ? 0.18 : 0.4;
        state.presence += (state.presenceTarget - state.presence) * (1 - Math.exp(-dt / tau));
        moving =
          Math.abs(state.target - state.pos) > 0.05 ||
          Math.abs(state.velocity) > 0.05 ||
          Math.abs(state.presenceTarget - state.presence) > 0.002;
        if (!moving) state.presence = state.presenceTarget;
      }
      write();
      raf = moving ? requestAnimationFrame(frame) : 0;
    };

    const wake = () => {
      if (raf) return;
      last = performance.now();
      raf = requestAnimationFrame(frame);
    };

    const sweep = sign => {
      if (reduced || !geometry.reach) return;
      const end = sign * geometry.reach;
      const from = state.sweep || Math.abs(state.pos) < geometry.reach ? state.pos : -end;
      if (from === end) return;
      const share = Math.abs(end - from) / (2 * geometry.reach);
      state.sweep = {
        from,
        to: end,
        start: performance.now(),
        duration: Math.max(120, settingsRef.current.transitionDuration * share)
      };
      wake();
    };

    const along = event => {
      const rect = root.getBoundingClientRect();
      const dx = event.clientX - (rect.left + rect.width / 2);
      const dy = event.clientY - (rect.top + rect.height / 2);
      return dx * geometry.ux + dy * geometry.uy;
    };

    const follow = event => {
      state.target = Math.max(-geometry.reach, Math.min(geometry.reach, along(event)));
      wake();
    };

    const onEnter = event => {
      if (mode === 'hover') sweep(along(event) > 0 ? -1 : 1);
      if (mode === 'follow') {
        if (state.presence < 0.02) {
          state.pos = Math.max(-geometry.reach, Math.min(geometry.reach, along(event)));
          state.velocity = 0;
        }
        state.presenceTarget = reduced ? 0 : 1;
        follow(event);
      }
    };

    const onMove = event => {
      if (mode === 'follow') follow(event);
    };

    const onLeave = event => {
      if (mode === 'hover' && !settingsRef.current.playOnce) sweep(along(event) > 0 ? 1 : -1);
      if (mode === 'follow') {
        state.presenceTarget = 0;
        wake();
      }
    };

    const onDown = event => {
      if (mode === 'click') sweep(along(event) > 0 ? -1 : 1);
    };

    const onFocus = event => {
      if (mode !== 'follow' && event.target.matches?.(':focus-visible')) sweep(1);
    };

    const schedule = () => {
      window.clearTimeout(timer);
      if (mode !== 'loop' || reduced) return;
      timer = window.setTimeout(
        () => {
          if (state.visible && !document.hidden) sweep(1);
          schedule();
        },
        Math.max(0.5, settingsRef.current.interval) * 1000
      );
    };

    root.addEventListener('pointerenter', onEnter);
    root.addEventListener('pointermove', onMove);
    root.addEventListener('pointerleave', onLeave);
    root.addEventListener('pointerdown', onDown);
    root.addEventListener('focusin', onFocus);

    const resizeObserver = new ResizeObserver(measure);
    resizeObserver.observe(root);

    const visibilityObserver = new IntersectionObserver(
      ([entry]) => {
        state.visible = entry.isIntersecting;
        if (entry.isIntersecting && settingsRef.current.intro && !introRef.current) {
          introRef.current = true;
          sweep(1);
        }
      },
      { threshold: 0.4 }
    );
    visibilityObserver.observe(root);

    state.presence = mode === 'follow' ? 0 : 1;
    state.presenceTarget = state.presence;
    state.pos = -1e4;
    measure();
    schedule();
    engineRef.current = { measure };

    return () => {
      cancelAnimationFrame(raf);
      window.clearTimeout(timer);
      resizeObserver.disconnect();
      visibilityObserver.disconnect();
      root.removeEventListener('pointerenter', onEnter);
      root.removeEventListener('pointermove', onMove);
      root.removeEventListener('pointerleave', onLeave);
      root.removeEventListener('pointerdown', onDown);
      root.removeEventListener('focusin', onFocus);
      engineRef.current = null;
    };
  }, [mode]);

  useEffect(() => {
    engineRef.current?.measure();
  }, [glareAngle, glareSize, rimGlint]);

  const glare = gradient(glareColor, glareOpacity, variant, softness);
  const rim = gradient(glareColor, Math.min(1, glareOpacity * 1.8), variant, softness);

  return (
    <div
      ref={rootRef}
      className={`glare-hover ${className}`.trim()}
      style={{
        '--gh-width': width,
        '--gh-height': height,
        '--gh-bg': background,
        '--gh-br': borderRadius,
        '--gh-border': borderColor,
        '--gh-glare': glare,
        '--gh-rim': rim,
        '--gh-blend': blendMode,
        ...style
      }}
    >
      {children}
      <span ref={glareRef} className="glare-hover__glare" aria-hidden="true">
        <span ref={bandRef} className="glare-hover__band" />
        {rimGlint && (
          <span className="glare-hover__rim">
            <span ref={rimRef} className="glare-hover__band glare-hover__band--rim" />
          </span>
        )}
      </span>
    </div>
  );
};

export default GlareHover;

// Design tokens for fixed-dock system design + prototype
window.FD = {
  // Type
  font: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
  mono: 'ui-monospace, "SF Mono", Menlo, "JetBrains Mono", monospace',

  // Surfaces
  paper: '#faf8f4',
  card: '#ffffff',
  ink: '#1c1917',
  ink2: '#44403c',
  muted: '#78716c',
  rule: 'rgba(28,25,23,0.10)',
  ruleSoft: 'rgba(28,25,23,0.06)',

  // Accents (all oklch, equal chroma family)
  accent: 'oklch(0.55 0.16 252)',         // sodalite blue — primary
  accentSoft: 'oklch(0.95 0.025 252)',    // bg tint
  accentInk: 'oklch(0.30 0.10 252)',      // dark accent text
  lock: 'oklch(0.62 0.15 150)',           // green — locked / active
  lockSoft: 'oklch(0.95 0.04 150)',
  warn: 'oklch(0.74 0.14 70)',            // amber — paused
  warnSoft: 'oklch(0.96 0.04 70)',
  danger: 'oklch(0.60 0.18 25)',          // red — jump detected
};

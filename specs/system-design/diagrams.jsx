// System architecture + flow diagrams for fixed-dock
const { font, mono, paper, card, ink, ink2, muted, rule, ruleSoft,
  accent, accentSoft, accentInk, lock, lockSoft, warn, warnSoft, danger } = window.FD;

// ─────────────────────────────────────────────────────────────
// Shared atoms
// ─────────────────────────────────────────────────────────────
function Frame({ children, title, eyebrow, footer, w, h, pad = 56 }) {
  return (
    <div style={{
      width: w, height: h, background: paper, position: 'relative',
      fontFamily: font, color: ink, padding: pad, boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{
        position: 'absolute', top: 24, left: pad, right: pad,
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
        fontFamily: mono, fontSize: 11, color: muted, letterSpacing: 0.3,
      }}>
        <span>{eyebrow}</span>
        <span>fixed-dock · system design</span>
      </div>
      {title && (
        <h2 style={{
          fontSize: 32, fontWeight: 600, letterSpacing: -0.6,
          margin: '24px 0 8px',
        }}>{title}</h2>
      )}
      <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>{children}</div>
      {footer && (
        <div style={{
          fontFamily: mono, fontSize: 11, color: muted, marginTop: 18,
          paddingTop: 14, borderTop: `1px solid ${ruleSoft}`,
        }}>{footer}</div>
      )}
    </div>
  );
}

function Tag({ children, kind = 'neutral' }) {
  const map = {
    neutral: { bg: 'rgba(28,25,23,0.06)', fg: ink2 },
    accent:  { bg: accentSoft, fg: accentInk },
    lock:    { bg: lockSoft, fg: 'oklch(0.32 0.10 150)' },
    warn:    { bg: warnSoft, fg: 'oklch(0.40 0.10 70)' },
  };
  const c = map[kind];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontFamily: mono, fontSize: 10, letterSpacing: 0.4,
      background: c.bg, color: c.fg, padding: '3px 7px', borderRadius: 4,
      textTransform: 'uppercase', fontWeight: 600,
    }}>{children}</span>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. Overview / Problem
// ─────────────────────────────────────────────────────────────
function OverviewArtboard() {
  // Two display rendering: jumping vs locked
  const displaySvg = (mode) => {
    const jumping = mode === 'jumping';
    return (
      <svg viewBox="0 0 520 280" style={{ width: '100%', height: 'auto' }}>
        {/* Display A - primary */}
        <g>
          <rect x="20" y="40" width="200" height="125" rx="6" fill="white" stroke={ink} strokeWidth="1.5"/>
          <rect x="20" y="40" width="200" height="14" rx="6" fill="#e7e5e0"/>
          <rect x="20" y="48" width="200" height="6" fill="#e7e5e0"/>
          {/* menubar dots */}
          <circle cx="28" cy="47" r="2" fill={ink2} opacity="0.4"/>
          {/* stand */}
          <rect x="100" y="165" width="40" height="14" fill={ink2} opacity="0.7"/>
          <rect x="80" y="178" width="80" height="4" rx="2" fill={ink2} opacity="0.7"/>
          {/* dock on display A (always there when locked) */}
          {(!jumping) && (
            <g>
              <rect x="58" y="140" width="124" height="18" rx="9"
                fill={lock} opacity="0.15" stroke={lock} strokeWidth="1"/>
              {[0,1,2,3,4,5,6].map(i => (
                <rect key={i} x={66 + i*15} y="144" width="10" height="10" rx="2" fill={lock} opacity="0.9"/>
              ))}
            </g>
          )}
          {(jumping) && (
            <g opacity="0.35">
              <rect x="58" y="140" width="124" height="18" rx="9"
                fill="none" stroke={ink2} strokeWidth="1" strokeDasharray="3 2"/>
            </g>
          )}
          <text x="120" y="200" fontFamily={mono} fontSize="10" fill={muted} textAnchor="middle">
            Display 1 · Primary
          </text>
        </g>

        {/* Display B - secondary */}
        <g>
          <rect x="280" y="20" width="220" height="145" rx="6" fill="white" stroke={ink} strokeWidth="1.5"/>
          <rect x="280" y="20" width="220" height="14" rx="6" fill="#e7e5e0"/>
          <rect x="280" y="28" width="220" height="6" fill="#e7e5e0"/>
          <circle cx="288" cy="27" r="2" fill={ink2} opacity="0.4"/>
          <rect x="370" y="165" width="40" height="14" fill={ink2} opacity="0.7"/>
          <rect x="350" y="178" width="80" height="4" rx="2" fill={ink2} opacity="0.7"/>
          {/* dock on display B if jumping */}
          {jumping && (
            <g>
              <rect x="318" y="140" width="144" height="18" rx="9"
                fill={danger} opacity="0.15" stroke={danger} strokeWidth="1"/>
              {[0,1,2,3,4,5,6,7].map(i => (
                <rect key={i} x={326 + i*16} y="144" width="10" height="10" rx="2" fill={danger} opacity="0.9"/>
              ))}
            </g>
          )}
          <text x="390" y="200" fontFamily={mono} fontSize="10" fill={muted} textAnchor="middle">
            Display 2 · Secondary
          </text>
        </g>

        {/* cursor on display B */}
        <g transform={`translate(${jumping ? 380 : 380}, ${jumping ? 152 : 152})`}>
          <path d="M0,0 L0,12 L3,9 L5,13 L7,12 L5,8 L9,8 Z"
            fill={ink} stroke="white" strokeWidth="0.8"/>
        </g>

        {/* outcome label */}
        <g>
          <rect x="20" y="232" width="480" height="36" rx="6"
            fill={jumping ? 'rgba(255,80,60,0.05)' : 'rgba(60,180,120,0.06)'}
            stroke={jumping ? danger : lock} strokeWidth="1" strokeOpacity="0.4"/>
          <text x="36" y="255" fontFamily={mono} fontSize="11"
            fill={jumping ? danger : 'oklch(0.32 0.10 150)'} fontWeight="600">
            {jumping ? 'BEFORE  ·  cursor on D2 → dock jumps to D2' : 'AFTER   ·  cursor on D2 → dock stays on D1'}
          </text>
        </g>
      </svg>
    );
  };

  return (
    <Frame
      w={1100} h={720}
      eyebrow="00 · OVERVIEW"
      title="Keep the Dock where you put it."
      footer="Native Swift · macOS 12+ · user-space APIs only · no kernel extensions">
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 40,
        alignItems: 'start', marginTop: 12,
      }}>
        <div>
          <Tag kind="neutral">PROBLEM</Tag>
          <p style={{ fontSize: 17, lineHeight: 1.5, marginTop: 14, color: ink2 }}>
            On multi-display Macs, the Dock follows the cursor. A glance at a
            second monitor pulls it across screens — disrupting muscle memory,
            window layouts, and Mission Control state.
          </p>
          <div style={{ marginTop: 18 }}>{displaySvg('jumping')}</div>
        </div>
        <div>
          <Tag kind="accent">SOLUTION</Tag>
          <p style={{ fontSize: 17, lineHeight: 1.5, marginTop: 14, color: ink2 }}>
            A background engine intercepts the system events that trigger
            Dock relocation, holding it on the display the user assigned —
            without modifying the Dock binary or kernel.
          </p>
          <div style={{ marginTop: 18 }}>{displaySvg('locked')}</div>
        </div>
      </div>
    </Frame>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. System architecture — layered
// ─────────────────────────────────────────────────────────────
function ArchitectureArtboard() {
  const Layer = ({ title, sub, items, color = 'neutral', tag, mono: isMono }) => {
    const palette = {
      neutral: { bg: card, border: rule, dot: ink2 },
      accent:  { bg: card, border: 'rgba(60,80,200,0.30)', dot: accent },
      lock:    { bg: card, border: 'rgba(60,160,110,0.30)', dot: lock },
    };
    const p = palette[color];
    return (
      <div style={{
        background: p.bg, border: `1px solid ${p.border}`, borderRadius: 10,
        padding: '18px 22px', display: 'flex', gap: 24, alignItems: 'flex-start',
      }}>
        <div style={{ flex: '0 0 200px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 8, height: 8, borderRadius: 4, background: p.dot }} />
            <Tag kind={tag || 'neutral'}>{title}</Tag>
          </div>
          <div style={{ fontSize: 14, color: muted, marginTop: 6, lineHeight: 1.4 }}>{sub}</div>
        </div>
        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {items.map(([name, desc]) => (
            <div key={name} style={{
              border: `1px solid ${ruleSoft}`, borderRadius: 6,
              padding: '10px 12px', background: paper,
            }}>
              <div style={{ fontFamily: isMono ? mono : font, fontSize: 13, fontWeight: 600, color: ink }}>{name}</div>
              <div style={{ fontSize: 12, color: muted, marginTop: 3, lineHeight: 1.35 }}>{desc}</div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <Frame
      w={1100} h={820}
      eyebrow="01 · ARCHITECTURE"
      title="System architecture"
      footer="All four layers ship in one signed app bundle · sandboxed where possible">
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 12 }}>
        <Layer
          title="UI" sub="SwiftUI dashboard + menu bar" tag="neutral"
          items={[
            ['DashboardView', 'Main settings window — toggles, status, display map'],
            ['MenuBarController', 'NSStatusItem; popover with quick toggle'],
            ['OnboardingFlow', 'Permissions prompt; 3-step setup'],
          ]} />

        <Layer
          title="State" sub="Observable single source of truth" tag="accent" color="accent"
          items={[
            ['EngineState', 'enum { idle, armed, locked, paused }'],
            ['Settings', 'AppStorage-backed prefs (anchor, launch-at-login)'],
            ['DisplayTopology', 'live NSScreen[] mirror; refreshed on reconfig'],
          ]} />

        <Layer
          title="Engine" sub="Anti-jumping core (background)" tag="accent" color="lock" mono
          items={[
            ['DockMonitor', 'Observes com.apple.dock prefs + window position'],
            ['EventTap', 'CGEventTap on mouseMoved at bottom-edge regions'],
            ['Anchor', 'Re-applies orientation/screen when drift detected'],
          ]} />

        <Layer
          title="System APIs" sub="User-space only — no kexts" tag="neutral" mono
          items={[
            ['CoreGraphics', 'CGEventTap · CGDisplay* · CGSConnection (private)'],
            ['AppKit', 'NSScreen · NSWorkspace · NSDistributedNotification'],
            ['ServiceMgmt', 'SMAppService for launch-at-login (LaunchAgent)'],
          ]} />
      </div>
    </Frame>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. Engine flow — sequence diagram
// ─────────────────────────────────────────────────────────────
function EngineFlowArtboard() {
  // Sequence with 4 actors. Steps go top-to-bottom.
  const actors = [
    { id: 'usr', label: 'User',         x: 90  },
    { id: 'sys', label: 'macOS',        x: 320 },
    { id: 'eng', label: 'fixed-dock\nEngine', x: 580 },
    { id: 'dck', label: 'Dock.app',     x: 840 },
  ];
  const lifelineTop = 60, lifelineBottom = 540;

  const messages = [
    { from: 'usr', to: 'sys', y: 100, label: 'cursor → bottom edge of Display 2', kind: 'neutral' },
    { from: 'sys', to: 'eng', y: 150, label: 'CGEvent.mouseMoved (tap)',  kind: 'accent' },
    { from: 'eng', to: 'eng', y: 200, label: 'eval: would this trigger relocation?', kind: 'thought' },
    { from: 'eng', to: 'sys', y: 250, label: 'mutate event ▸ clip cursor.y',  kind: 'lock' },
    { from: 'sys', to: 'dck', y: 300, label: '(no relocation event fired)',   kind: 'neutral', dashed: true },
    { from: 'dck', to: 'sys', y: 360, label: 'observe: prefs.dock-screen drift', kind: 'warn' },
    { from: 'sys', to: 'eng', y: 410, label: 'NSDistributedNotification', kind: 'accent' },
    { from: 'eng', to: 'dck', y: 460, label: 'restore Anchor (writeDefaults + HUP)', kind: 'lock' },
  ];

  const kindColor = (k) => ({
    neutral: ink2, accent, lock, warn, thought: muted,
  }[k] || ink2);

  return (
    <Frame
      w={1100} h={700}
      eyebrow="02 · CORE FLOW"
      title="Event interception sequence"
      footer="Two-line defense · (a) suppress relocation triggers · (b) repair drift if it occurs">
      <div style={{ position: 'relative', height: 580, marginTop: 12 }}>
        <svg viewBox="0 0 1000 580" style={{ width: '100%', height: '100%' }}>
          {/* lifelines */}
          {actors.map((a) => (
            <g key={a.id}>
              <line x1={a.x} y1={lifelineTop} x2={a.x} y2={lifelineBottom}
                stroke={rule} strokeWidth="1" strokeDasharray="3 4"/>
              <rect x={a.x - 64} y={20} width="128" height="34" rx="6"
                fill={card} stroke={rule} strokeWidth="1"/>
              {a.label.split('\n').map((line, i) => (
                <text key={i} x={a.x} y={a.label.includes('\n') ? 35 + i*12 : 42}
                  fontFamily={mono} fontSize="11" fontWeight="600" fill={ink}
                  textAnchor="middle">{line}</text>
              ))}
            </g>
          ))}

          {messages.map((m, i) => {
            const fromX = actors.find(a => a.id === m.from).x;
            const toX = actors.find(a => a.id === m.to).x;
            const color = kindColor(m.kind);
            if (m.from === m.to) {
              // self-message
              return (
                <g key={i}>
                  <path d={`M${fromX},${m.y} q 40,0 40,18 q 0,18 -40,18`}
                    fill="none" stroke={color} strokeWidth="1.4"/>
                  <polygon points={`${fromX - 4},${m.y + 32} ${fromX + 4},${m.y + 32} ${fromX},${m.y + 38}`}
                    fill={color} transform={`rotate(180 ${fromX} ${m.y + 35})`}/>
                  <text x={fromX + 50} y={m.y + 22} fontFamily={mono} fontSize="11"
                    fill={color} fontStyle="italic">{m.label}</text>
                </g>
              );
            }
            const dir = toX > fromX ? 1 : -1;
            const tip = toX - dir * 6;
            return (
              <g key={i}>
                <line x1={fromX} y1={m.y} x2={tip} y2={m.y}
                  stroke={color} strokeWidth="1.6"
                  strokeDasharray={m.dashed ? '4 3' : 'none'}/>
                <polygon points={`${tip},${m.y - 4} ${tip},${m.y + 4} ${toX},${m.y}`}
                  fill={color}/>
                <text x={(fromX + toX) / 2} y={m.y - 7}
                  fontFamily={mono} fontSize="11.5" fill={color}
                  fontWeight={m.kind === 'lock' ? 600 : 500}
                  textAnchor="middle">{m.label}</text>
              </g>
            );
          })}
        </svg>

        {/* legend */}
        <div style={{
          position: 'absolute', bottom: 4, left: 0, right: 0,
          display: 'flex', gap: 18, justifyContent: 'center',
          fontFamily: mono, fontSize: 11, color: muted,
        }}>
          {[
            ['Input',        ink2],
            ['Tapped',       accent],
            ['Intercepted',  lock],
            ['Drift detected', warn],
          ].map(([l, c]) => (
            <span key={l} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 18, height: 2, background: c }}/>{l}
            </span>
          ))}
        </div>
      </div>
    </Frame>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. Engine state machine
// ─────────────────────────────────────────────────────────────
function StateMachineArtboard() {
  const nodes = [
    { id: 'idle',   label: 'idle',   x: 130, y: 200, color: muted,  desc: 'no permissions / disabled' },
    { id: 'armed',  label: 'armed',  x: 360, y: 120, color: accent, desc: 'observing, not intercepting' },
    { id: 'locked', label: 'locked', x: 620, y: 200, color: lock,   desc: 'anchor enforced' },
    { id: 'paused', label: 'paused', x: 360, y: 320, color: warn,   desc: 'temporary user override' },
  ];

  const edges = [
    { from: 'idle',   to: 'armed',  label: 'grantAccess()', d: 'M 195,180 Q 270,130 305,127' },
    { from: 'armed',  to: 'locked', label: 'engage()',       d: 'M 420,140 Q 510,160 565,180' },
    { from: 'locked', to: 'armed',  label: 'disengage()',    d: 'M 580,200 Q 510,210 420,160', dashed: true },
    { from: 'locked', to: 'paused', label: 'cmd⇧L', d: 'M 600,228 Q 510,290 420,318', dashed: true },
    { from: 'paused', to: 'locked', label: 'auto-resume 30s', d: 'M 420,310 Q 510,280 600,225' },
    { from: 'armed',  to: 'idle',   label: 'revokeAccess', d: 'M 310,143 Q 250,180 200,195', dashed: true },
  ];

  const find = (id) => nodes.find(n => n.id === id);

  return (
    <Frame
      w={1100} h={620}
      eyebrow="03 · STATE"
      title="Engine state machine"
      footer="State is the single source of truth · UI + menu bar render from it">
      <svg viewBox="0 0 800 440" style={{ width: '100%', height: '100%' }}>
        {edges.map((e, i) => {
          return (
            <g key={i}>
              <path d={e.d} fill="none" stroke={ink2} strokeOpacity="0.4"
                strokeWidth="1.4"
                strokeDasharray={e.dashed ? '4 4' : 'none'}
                markerEnd="url(#arrow)"/>
            </g>
          );
        })}

        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
            <path d="M 0 0 L 10 5 L 0 10 z" fill={ink2} fillOpacity="0.6"/>
          </marker>
        </defs>

        {/* edge labels */}
        {edges.map((e, i) => {
          // crude midpoint from path
          const from = find(e.from), to = find(e.to);
          const mx = (from.x + to.x) / 2, my = (from.y + to.y) / 2 - 8;
          return (
            <g key={`l${i}`}>
              <rect x={mx - e.label.length * 3.2 - 4} y={my - 9} width={e.label.length * 6.4 + 8} height="14"
                fill={paper} rx="2"/>
              <text x={mx} y={my + 1} fontFamily={mono} fontSize="10.5"
                fill={ink2} textAnchor="middle">{e.label}</text>
            </g>
          );
        })}

        {nodes.map((n) => (
          <g key={n.id}>
            <circle cx={n.x} cy={n.y} r="52" fill={card} stroke={n.color} strokeWidth="2"/>
            <text x={n.x} y={n.y - 2} fontFamily={mono} fontSize="14"
              fontWeight="700" fill={n.color} textAnchor="middle">{n.label}</text>
            <text x={n.x} y={n.y + 16} fontFamily={font} fontSize="10.5"
              fill={muted} textAnchor="middle">{n.desc}</text>
          </g>
        ))}
      </svg>
    </Frame>
  );
}

Object.assign(window, {
  OverviewArtboard, ArchitectureArtboard,
  EngineFlowArtboard, StateMachineArtboard,
});

// Interactive SwiftUI-style dashboard prototype for fixed-dock
const { font, mono, paper, card, ink, ink2, muted, rule, ruleSoft,
  accent, accentSoft, accentInk, lock, lockSoft, warn, warnSoft, danger } = window.FD;

// macOS traffic lights
function TrafficLights() {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#ff5f57', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#febc2e', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
      <div style={{ width: 12, height: 12, borderRadius: 6, background: '#28c840', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
    </div>
  );
}

// Sidebar item
function SBItem({ icon, label, active, onClick, badge }) {
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '6px 10px', margin: '0 8px', borderRadius: 6,
        cursor: 'pointer', fontSize: 13, color: ink,
        fontWeight: active ? 500 : 400,
        background: active ? 'rgba(0,0,0,0.06)' : 'transparent',
        transition: 'background 0.12s',
      }}
      onMouseEnter={e => { if (!active) e.currentTarget.style.background = 'rgba(0,0,0,0.03)'; }}
      onMouseLeave={e => { if (!active) e.currentTarget.style.background = 'transparent'; }}>
      <span style={{
        width: 18, height: 18, borderRadius: 4,
        background: active ? accent : 'rgba(0,0,0,0.08)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: active ? 'white' : ink2, flexShrink: 0,
      }}>{icon}</span>
      <span style={{ flex: 1 }}>{label}</span>
      {badge && (
        <span style={{
          fontFamily: mono, fontSize: 9, fontWeight: 700,
          background: badge.color, color: 'white',
          padding: '1px 5px', borderRadius: 3,
        }}>{badge.text}</span>
      )}
    </div>
  );
}

// Sidebar header
function SBHeader({ children }) {
  return (
    <div style={{
      padding: '14px 18px 4px',
      fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
      color: muted, textTransform: 'uppercase',
    }}>{children}</div>
  );
}

// macOS-style toggle switch
function Toggle({ value, onChange, large = false }) {
  const w = large ? 50 : 38, h = large ? 30 : 22;
  const thumb = h - 4;
  return (
    <div
      onClick={() => onChange(!value)}
      role="switch"
      aria-checked={value}
      style={{
        width: w, height: h, borderRadius: h / 2,
        background: value ? lock : 'rgba(120,113,108,0.35)',
        position: 'relative', cursor: 'pointer',
        transition: 'background 0.18s ease',
        flexShrink: 0,
      }}>
      <div style={{
        position: 'absolute', top: 2, left: value ? w - thumb - 2 : 2,
        width: thumb, height: thumb, borderRadius: thumb / 2,
        background: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.2), 0 0 0 0.5px rgba(0,0,0,0.06)',
        transition: 'left 0.18s ease',
      }}/>
    </div>
  );
}

// Status pill
function StatusPill({ state }) {
  const map = {
    locked: { bg: lockSoft, dot: lock, fg: 'oklch(0.30 0.10 150)', label: 'Locked' },
    armed:  { bg: accentSoft, dot: accent, fg: accentInk, label: 'Armed' },
    paused: { bg: warnSoft, dot: warn, fg: 'oklch(0.38 0.10 70)', label: 'Paused' },
    idle:   { bg: 'rgba(120,113,108,0.10)', dot: muted, fg: ink2, label: 'Disabled' },
  };
  const s = map[state];
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 7,
      background: s.bg, color: s.fg, padding: '5px 11px',
      borderRadius: 999, fontSize: 12, fontWeight: 600,
      fontFamily: font,
    }}>
      <span style={{
        width: 7, height: 7, borderRadius: 4, background: s.dot,
        boxShadow: state === 'locked' ? `0 0 0 3px ${s.bg}` : 'none',
      }}/>
      {s.label}
    </div>
  );
}

// Display preview tile - shows monitor with dock anchored
function DisplayTile({ display, isAnchor, isPrimary, locked, onClick, cursorOn }) {
  const w = display.w, h = display.h;
  return (
    <div
      onClick={onClick}
      style={{
        width: w, height: h + 28, position: 'relative', cursor: 'pointer',
      }}>
      <div style={{
        width: w, height: h, position: 'relative',
        background: 'linear-gradient(180deg, #2c5278 0%, #4a7ba5 100%)',
        borderRadius: 6, overflow: 'hidden',
        border: isAnchor ? `2px solid ${lock}` : `1px solid ${rule}`,
        boxShadow: isAnchor ? `0 0 0 3px ${lockSoft}` : '0 1px 4px rgba(0,0,0,0.08)',
        transition: 'all 0.2s',
      }}>
        {/* menubar */}
        <div style={{
          height: 8, background: 'rgba(255,255,255,0.18)',
          borderBottom: '0.5px solid rgba(255,255,255,0.2)',
        }}/>
        {/* dock if anchor or locked here */}
        {isAnchor && (
          <div style={{
            position: 'absolute', bottom: 6, left: '50%',
            transform: 'translateX(-50%)',
            background: 'rgba(255,255,255,0.35)',
            backdropFilter: 'blur(4px)',
            borderRadius: 6, padding: 3, display: 'flex', gap: 2,
            border: '0.5px solid rgba(255,255,255,0.4)',
          }}>
            {Array.from({ length: 7 }).map((_, i) => (
              <div key={i} style={{
                width: 6, height: 6, borderRadius: 1.5,
                background: ['#ff5f57','#febc2e','#28c840','#5e9eff','#a98bff','#ff8aae','#7ed4d0'][i],
              }}/>
            ))}
          </div>
        )}
        {/* cursor */}
        {cursorOn && (
          <svg style={{
            position: 'absolute', left: '50%', bottom: 14,
            transform: 'translateX(-50%)',
          }} width="10" height="14" viewBox="0 0 10 14">
            <path d="M0,0 L0,11 L3,8 L5,12 L7,11 L5,7 L9,7 Z"
              fill="white" stroke="black" strokeWidth="0.5"/>
          </svg>
        )}
        {/* primary badge */}
        {isPrimary && (
          <div style={{
            position: 'absolute', top: 12, left: 8,
            fontFamily: mono, fontSize: 8, color: 'rgba(255,255,255,0.7)',
            letterSpacing: 0.4,
          }}>PRIMARY</div>
        )}
      </div>
      <div style={{
        marginTop: 6, display: 'flex', alignItems: 'center',
        justifyContent: 'space-between', fontFamily: font, fontSize: 11,
      }}>
        <span style={{ color: ink, fontWeight: 500 }}>{display.name}</span>
        <span style={{ color: muted, fontFamily: mono, fontSize: 10 }}>
          {display.resolution}
        </span>
      </div>
    </div>
  );
}

// ─── Main dashboard ───────────────────────────────────────
function Dashboard({ initialEnabled = true, initialAnchor = 0, initialView = 'status' }) {
  const [enabled, setEnabled] = React.useState(initialEnabled);
  const [paused, setPaused] = React.useState(false);
  const [anchor, setAnchor] = React.useState(initialAnchor);
  const [view, setView] = React.useState(initialView);
  const [launchAtLogin, setLaunchAtLogin] = React.useState(true);
  const [menuBarIcon, setMenuBarIcon] = React.useState(true);
  const [hapticFeedback, setHapticFeedback] = React.useState(false);
  const [cursorDisplay, setCursorDisplay] = React.useState(0);
  const [interceptCount, setInterceptCount] = React.useState(247);
  const [tickerOn, setTickerOn] = React.useState(false);

  const displays = [
    { name: 'Studio Display',      resolution: '5120 × 2880', w: 200, h: 116 },
    { name: 'LG UltraFine 32"',    resolution: '3840 × 2160', w: 168, h: 95  },
    { name: 'MacBook Pro Retina',  resolution: '3024 × 1964', w: 120, h: 78  },
  ];

  const engineState = !enabled ? 'idle' : paused ? 'paused' : 'locked';

  // simulate counter ticking when locked and cursor on non-anchor
  React.useEffect(() => {
    if (!tickerOn) return;
    if (engineState !== 'locked') return;
    if (cursorDisplay === anchor) return;
    const t = setInterval(() => setInterceptCount(c => c + 1), 600);
    return () => clearInterval(t);
  }, [tickerOn, engineState, cursorDisplay, anchor]);

  return (
    <div style={{
      width: 920, height: 620, borderRadius: 12, overflow: 'hidden',
      background: card, fontFamily: font, color: ink,
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.18), 0 24px 60px rgba(0,0,0,0.25)',
      display: 'flex',
    }}>
      {/* Sidebar */}
      <div style={{
        width: 200, background: '#f6f5f1', borderRight: `0.5px solid ${rule}`,
        display: 'flex', flexDirection: 'column',
      }}>
        {/* titlebar */}
        <div style={{
          height: 44, display: 'flex', alignItems: 'center',
          padding: '0 14px', gap: 10,
        }}>
          <TrafficLights />
        </div>

        <div style={{ flex: 1, overflowY: 'auto', paddingTop: 4 }}>
          <SBHeader>fixed-dock</SBHeader>
          <SBItem icon="●" label="Status" active={view === 'status'}
            onClick={() => setView('status')}
            badge={engineState === 'locked' ? { text: 'ON', color: lock } : null}/>
          <SBItem icon="▢" label="Displays" active={view === 'displays'}
            onClick={() => setView('displays')}/>
          <SBItem icon="≡" label="Behavior" active={view === 'behavior'}
            onClick={() => setView('behavior')}/>
          <SBItem icon="⚑" label="Activity" active={view === 'activity'}
            onClick={() => setView('activity')}/>

          <SBHeader>System</SBHeader>
          <SBItem icon="✓" label="Permissions" active={view === 'perms'}
            onClick={() => setView('perms')}/>
          <SBItem icon="i" label="About" active={view === 'about'}
            onClick={() => setView('about')}/>
        </div>

        {/* engine state footer */}
        <div style={{
          padding: '12px 14px', borderTop: `0.5px solid ${rule}`,
          background: 'rgba(0,0,0,0.015)',
        }}>
          <div style={{ fontSize: 10, color: muted, fontFamily: mono, marginBottom: 6 }}>
            ENGINE
          </div>
          <StatusPill state={engineState}/>
        </div>
      </div>

      {/* Main content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* toolbar */}
        <div style={{
          height: 44, display: 'flex', alignItems: 'center',
          padding: '0 18px', borderBottom: `0.5px solid ${ruleSoft}`,
          fontSize: 13, fontWeight: 600,
        }}>
          {{ status: 'Status', displays: 'Displays', behavior: 'Behavior',
             activity: 'Activity', perms: 'Permissions', about: 'About' }[view]}
        </div>

        {/* view router */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px' }}>
          {view === 'status' && (
            <StatusView
              enabled={enabled} setEnabled={setEnabled}
              paused={paused} setPaused={setPaused}
              anchor={anchor} setAnchor={setAnchor}
              displays={displays}
              cursorDisplay={cursorDisplay} setCursorDisplay={setCursorDisplay}
              engineState={engineState}
              interceptCount={interceptCount}
              tickerOn={tickerOn} setTickerOn={setTickerOn}
            />
          )}
          {view === 'displays' && (
            <DisplaysView
              displays={displays} anchor={anchor} setAnchor={setAnchor}
              cursorDisplay={cursorDisplay} setCursorDisplay={setCursorDisplay}
              engineState={engineState}
            />
          )}
          {view === 'behavior' && (
            <BehaviorView
              launchAtLogin={launchAtLogin} setLaunchAtLogin={setLaunchAtLogin}
              menuBarIcon={menuBarIcon} setMenuBarIcon={setMenuBarIcon}
              hapticFeedback={hapticFeedback} setHapticFeedback={setHapticFeedback}
            />
          )}
          {view === 'activity' && (
            <ActivityView interceptCount={interceptCount}/>
          )}
          {view === 'perms' && <PermissionsView/>}
          {view === 'about' && <AboutView/>}
        </div>
      </div>
    </div>
  );
}

// ─── Status view (main) ───────────────────────────────────
function StatusView({ enabled, setEnabled, paused, setPaused, anchor, setAnchor,
  displays, cursorDisplay, setCursorDisplay, engineState, interceptCount, tickerOn, setTickerOn }) {
  return (
    <div>
      {/* Big toggle card */}
      <div style={{
        background: paper, borderRadius: 10, padding: '20px 24px',
        border: `0.5px solid ${rule}`,
        display: 'flex', alignItems: 'center', gap: 20,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 17, fontWeight: 600, marginBottom: 4 }}>
            Anti-Jumping Engine
          </div>
          <div style={{ fontSize: 13, color: muted, lineHeight: 1.45 }}>
            {!enabled
              ? 'Enable to keep the Dock anchored to one display.'
              : paused
                ? 'Engine is paused. Auto-resume in 00:24.'
                : `Dock is anchored to ${displays[anchor].name}. ${interceptCount} relocations prevented.`}
          </div>
        </div>
        <Toggle value={enabled} onChange={setEnabled} large/>
      </div>

      {/* Display map */}
      <div style={{ marginTop: 24 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 12,
        }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Display map</div>
          <div style={{ fontSize: 11, color: muted, fontFamily: mono }}>
            click a display to anchor · ⌥-click moves cursor
          </div>
        </div>

        <div style={{
          background: 'linear-gradient(180deg, #f7f5f0 0%, #efece6 100%)',
          borderRadius: 10, padding: '36px 24px',
          border: `0.5px solid ${rule}`,
          display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
          gap: 24, position: 'relative', minHeight: 200,
        }}>
          {displays.map((d, i) => (
            <DisplayTile
              key={i}
              display={d}
              isAnchor={enabled && anchor === i}
              isPrimary={i === 0}
              locked={engineState === 'locked'}
              cursorOn={cursorDisplay === i}
              onClick={(e) => {
                if (e.altKey) setCursorDisplay(i);
                else setAnchor(i);
              }}
            />
          ))}
        </div>
      </div>

      {/* Quick actions */}
      <div style={{
        marginTop: 18, display: 'flex', gap: 10, alignItems: 'center',
      }}>
        <button
          disabled={!enabled}
          onClick={() => setPaused(p => !p)}
          style={{
            padding: '7px 14px', fontSize: 12, fontWeight: 500,
            border: `0.5px solid ${rule}`, borderRadius: 7,
            background: card, color: ink, cursor: enabled ? 'pointer' : 'not-allowed',
            opacity: enabled ? 1 : 0.4, fontFamily: font,
          }}>
          {paused ? 'Resume' : 'Pause 30s'}
        </button>
        <button
          onClick={() => setTickerOn(t => !t)}
          style={{
            padding: '7px 14px', fontSize: 12, fontWeight: 500,
            border: `0.5px solid ${rule}`, borderRadius: 7,
            background: tickerOn ? accentSoft : card,
            color: tickerOn ? accentInk : ink, cursor: 'pointer',
            fontFamily: font,
          }}>
          {tickerOn ? '⏸ Stop sim' : '▶ Simulate jump'}
        </button>
        <div style={{ flex: 1 }}/>
        <span style={{
          fontFamily: mono, fontSize: 11, color: muted,
        }}>
          uptime · 3d 14h · 0 crashes
        </span>
      </div>
    </div>
  );
}

// ─── Displays view ────────────────────────────────────────
function DisplaysView({ displays, anchor, setAnchor, cursorDisplay, setCursorDisplay, engineState }) {
  return (
    <div>
      <p style={{ fontSize: 13, color: muted, marginTop: 0, lineHeight: 1.5 }}>
        Choose which display the Dock should stay on. Drag a display
        in System Settings → Displays to change the physical arrangement.
      </p>

      <div style={{ marginTop: 18 }}>
        {displays.map((d, i) => (
          <label key={i} style={{
            display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
            border: `0.5px solid ${anchor === i ? accent : rule}`,
            background: anchor === i ? accentSoft : card,
            borderRadius: 8, marginBottom: 8, cursor: 'pointer',
            transition: 'all 0.12s',
          }}>
            <input type="radio" checked={anchor === i} onChange={() => setAnchor(i)}
              style={{ accentColor: accent, width: 14, height: 14 }}/>
            <div style={{
              width: 56, height: 36, borderRadius: 4,
              background: 'linear-gradient(180deg, #2c5278, #4a7ba5)',
              border: '0.5px solid rgba(0,0,0,0.15)',
            }}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>
                {d.name}
                {i === 0 && <span style={{ marginLeft: 8, fontSize: 11, color: muted, fontWeight: 400 }}>(primary)</span>}
              </div>
              <div style={{ fontSize: 11, color: muted, fontFamily: mono, marginTop: 2 }}>
                {d.resolution} · 60 Hz · {['DisplayPort','HDMI','Internal'][i]}
              </div>
            </div>
            {anchor === i && <StatusPill state={engineState === 'paused' ? 'paused' : 'locked'}/>}
          </label>
        ))}
      </div>

      <div style={{
        marginTop: 20, padding: '12px 14px',
        background: 'rgba(120,113,108,0.06)', borderRadius: 8,
        fontSize: 12, color: ink2, lineHeight: 1.5,
        borderLeft: `2px solid ${muted}`,
      }}>
        <strong>Hot-plug behavior:</strong> If the anchored display disconnects,
        the engine will fall back to the primary display until it reappears.
      </div>
    </div>
  );
}

// ─── Behavior view ───────────────────────────────────────
function BehaviorView({ launchAtLogin, setLaunchAtLogin, menuBarIcon, setMenuBarIcon, hapticFeedback, setHapticFeedback }) {
  const Row = ({ title, sub, value, onChange }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '14px 4px', borderBottom: `0.5px solid ${ruleSoft}`,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>{title}</div>
        <div style={{ fontSize: 12, color: muted, marginTop: 2, lineHeight: 1.4 }}>{sub}</div>
      </div>
      <Toggle value={value} onChange={onChange}/>
    </div>
  );
  return (
    <div>
      <Row title="Launch at login"
        sub="Start fixed-dock automatically when you sign in."
        value={launchAtLogin} onChange={setLaunchAtLogin}/>
      <Row title="Show menu bar icon"
        sub="Quick access to pause, resume, and engine status."
        value={menuBarIcon} onChange={setMenuBarIcon}/>
      <Row title="Haptic feedback on intercept"
        sub="Subtle tap when a jump is blocked (Force Touch trackpads)."
        value={hapticFeedback} onChange={setHapticFeedback}/>

      <div style={{ marginTop: 28 }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: muted, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 12 }}>
          Pause shortcut
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '12px 14px', border: `0.5px solid ${rule}`, borderRadius: 8,
        }}>
          <span style={{ flex: 1, fontSize: 13 }}>Toggle engine pause</span>
          {['⌘','⇧','L'].map((k) => (
            <kbd key={k} style={{
              fontFamily: mono, fontSize: 12, padding: '3px 8px',
              background: paper, border: `0.5px solid ${rule}`, borderRadius: 4,
              minWidth: 20, textAlign: 'center',
            }}>{k}</kbd>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Activity view ────────────────────────────────────────
function ActivityView({ interceptCount }) {
  const events = [
    { t: '2s',   src: 'Cursor → Display 2 edge',  action: 'Intercepted',  kind: 'lock' },
    { t: '14s',  src: 'Cursor → Display 2 edge',  action: 'Intercepted',  kind: 'lock' },
    { t: '1m',   src: 'NSDistributedNotification',action: 'Anchor verified', kind: 'accent' },
    { t: '4m',   src: 'Cursor → Display 3 edge',  action: 'Intercepted',  kind: 'lock' },
    { t: '12m',  src: 'Display reconfig event',   action: 'Topology refreshed', kind: 'accent' },
    { t: '18m',  src: 'Cursor → Display 2 edge',  action: 'Intercepted',  kind: 'lock' },
    { t: '24m',  src: 'Drift detected (prefs)',   action: 'Anchor restored', kind: 'warn' },
    { t: '37m',  src: 'Cursor → Display 2 edge',  action: 'Intercepted',  kind: 'lock' },
  ];
  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 18 }}>
        {[
          { l: 'Intercepts',  v: interceptCount,   k: 'lock' },
          { l: 'Restores',    v: 3,    k: 'warn' },
          { l: 'Uptime',      v: '3d 14h', k: 'accent' },
        ].map((s) => (
          <div key={s.l} style={{
            flex: 1, background: paper, border: `0.5px solid ${rule}`,
            borderRadius: 8, padding: '14px 16px',
          }}>
            <div style={{ fontSize: 10, color: muted, fontFamily: mono, letterSpacing: 0.4, textTransform: 'uppercase' }}>{s.l}</div>
            <div style={{ fontSize: 24, fontWeight: 600, marginTop: 4,
              color: ({lock: lock, warn: 'oklch(0.38 0.10 70)', accent: accentInk})[s.k] }}>
              {s.v}
            </div>
          </div>
        ))}
      </div>

      <div style={{
        background: paper, border: `0.5px solid ${rule}`, borderRadius: 8,
        overflow: 'hidden',
      }}>
        <div style={{
          padding: '10px 14px', borderBottom: `0.5px solid ${ruleSoft}`,
          fontSize: 11, color: muted, fontFamily: mono, letterSpacing: 0.4,
          textTransform: 'uppercase', fontWeight: 600,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>Recent events</span>
          <span style={{ textTransform: 'none', letterSpacing: 0 }}>live · ⌃R refresh</span>
        </div>
        {events.map((e, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '8px 14px', fontSize: 12,
            borderBottom: i === events.length - 1 ? 'none' : `0.5px solid ${ruleSoft}`,
            fontFamily: mono,
          }}>
            <span style={{ width: 40, color: muted }}>{e.t}</span>
            <span style={{
              width: 6, height: 6, borderRadius: 3,
              background: { lock, warn, accent }[e.kind],
            }}/>
            <span style={{ flex: 1, color: ink2 }}>{e.src}</span>
            <span style={{ color: ink, fontWeight: 500 }}>{e.action}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Permissions view ─────────────────────────────────────
function PermissionsView() {
  const Row = ({ title, sub, granted }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 16px', border: `0.5px solid ${rule}`,
      background: card, borderRadius: 8, marginBottom: 8,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 14,
        background: granted ? lockSoft : 'rgba(120,113,108,0.10)',
        color: granted ? lock : muted,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 14, fontWeight: 700,
      }}>{granted ? '✓' : '!'}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>{title}</div>
        <div style={{ fontSize: 12, color: muted, marginTop: 2, lineHeight: 1.4 }}>{sub}</div>
      </div>
      {granted
        ? <StatusPill state="locked"/>
        : <button style={{
            padding: '6px 12px', fontSize: 12, fontWeight: 500,
            background: accent, color: 'white', border: 'none',
            borderRadius: 6, cursor: 'pointer', fontFamily: font,
          }}>Open Settings</button>
      }
    </div>
  );
  return (
    <div>
      <p style={{ fontSize: 13, color: muted, marginTop: 0, lineHeight: 1.5 }}>
        fixed-dock needs Accessibility access to observe and intercept
        cursor events that would otherwise relocate the Dock. We never read
        keystrokes or window contents.
      </p>
      <div style={{ marginTop: 18 }}>
        <Row title="Accessibility"
          sub="Required · grants CGEventTap to observe cursor on display edges."
          granted={true}/>
        <Row title="Input Monitoring"
          sub="Optional · enables haptic-feedback intercepts on trackpad."
          granted={false}/>
      </div>
    </div>
  );
}

function AboutView() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 12 }}>
      <div style={{
        width: 88, height: 88, borderRadius: 20,
        background: `linear-gradient(135deg, ${accent} 0%, ${lock} 100%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 24px rgba(60,80,200,0.25)',
        marginBottom: 18,
      }}>
        <svg width="44" height="44" viewBox="0 0 44 44">
          <rect x="6" y="22" width="32" height="14" rx="4" fill="rgba(255,255,255,0.95)"/>
          <circle cx="22" cy="14" r="6" fill="none" stroke="rgba(255,255,255,0.95)" strokeWidth="2.5"/>
          <path d="M18,14 L26,14" stroke={accentInk} strokeWidth="2.5" strokeLinecap="round"/>
        </svg>
      </div>
      <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.4 }}>fixed-dock</div>
      <div style={{ fontSize: 13, color: muted, marginTop: 4, fontFamily: mono }}>v1.0.0 · build 247</div>
      <div style={{ fontSize: 12, color: muted, marginTop: 18, maxWidth: 340, lineHeight: 1.5 }}>
        A native macOS utility that keeps the Dock from jumping between displays.
        Open-source · MIT licensed. macOS 12.0+
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 22 }}>
        {['Acknowledgements', 'Source', 'Check for updates'].map((l) => (
          <button key={l} style={{
            padding: '6px 12px', fontSize: 12, border: `0.5px solid ${rule}`,
            background: card, borderRadius: 6, cursor: 'pointer', fontFamily: font,
          }}>{l}</button>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  Dashboard,
  StatusPill, Toggle, TrafficLights,
});

// Onboarding flow + menu bar dropdown states for fixed-dock
const { font, mono, paper, card, ink, ink2, muted, rule, ruleSoft,
  accent, accentSoft, accentInk, lock, lockSoft, warn, warnSoft, danger } = window.FD;

// macOS desktop wallpaper backdrop for menu bar shots
function DesktopBackdrop({ w = 640, h = 360, children }) {
  return (
    <div style={{
      width: w, height: h, position: 'relative', overflow: 'hidden',
      background: 'linear-gradient(155deg, #2b3554 0%, #4a5a8a 35%, #7794c4 70%, #b4c8e6 100%)',
      fontFamily: font,
    }}>
      {/* menu bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0,
        height: 24, background: 'rgba(255,255,255,0.10)',
        backdropFilter: 'blur(40px) saturate(180%)',
        WebkitBackdropFilter: 'blur(40px) saturate(180%)',
        borderBottom: '0.5px solid rgba(255,255,255,0.15)',
        display: 'flex', alignItems: 'center', padding: '0 14px',
        fontSize: 12, color: 'white', gap: 16,
      }}>
        <span style={{ fontWeight: 700, fontSize: 13 }}></span>
        <span style={{ fontWeight: 600 }}>fixed-dock</span>
        <span style={{ opacity: 0.85 }}>File</span>
        <span style={{ opacity: 0.85 }}>Edit</span>
        <span style={{ opacity: 0.85 }}>View</span>
        <span style={{ opacity: 0.85 }}>Help</span>
        <span style={{ flex: 1 }}/>
        {children /* menu bar status item lives here */}
      </div>
    </div>
  );
}

// ─── Menu bar dropdown — locked state ────────────────────
function MenuBarDropdown({ state = 'locked', interceptCount = 247, anchor = 'Studio Display' }) {
  const sCfg = {
    locked: { color: lock, label: 'Locked', icon: '●', sub: `Anchored to ${anchor}` },
    paused: { color: warn, label: 'Paused', icon: '⏸', sub: 'Auto-resume in 00:24' },
    idle:   { color: muted, label: 'Disabled', icon: '○', sub: 'Toggle engine to enable' },
  }[state];

  return (
    <div style={{ position: 'absolute', top: 4, right: 80 }}>
      {/* status item icon */}
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        background: 'rgba(255,255,255,0.20)', padding: '2px 7px',
        borderRadius: 4, marginRight: 4,
      }}>
        <div style={{
          width: 7, height: 7, borderRadius: 4, background: sCfg.color,
          boxShadow: state === 'locked' ? `0 0 6px ${lock}` : 'none',
        }}/>
        <span style={{ fontFamily: mono, fontSize: 11, color: 'white', fontWeight: 600 }}>FD</span>
      </div>

      {/* dropdown panel */}
      <div style={{
        position: 'absolute', top: 26, right: -10, width: 280,
        background: 'rgba(245,245,247,0.85)',
        backdropFilter: 'blur(40px) saturate(180%)',
        WebkitBackdropFilter: 'blur(40px) saturate(180%)',
        border: '0.5px solid rgba(0,0,0,0.15)',
        borderRadius: 10,
        boxShadow: '0 8px 28px rgba(0,0,0,0.25), 0 0 0 0.5px rgba(0,0,0,0.05)',
        padding: 6, fontFamily: font, color: ink, overflow: 'hidden',
      }}>
        {/* status row */}
        <div style={{
          padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 10,
          borderRadius: 6,
        }}>
          <div style={{
            width: 30, height: 30, borderRadius: 8,
            background: state === 'locked' ? lockSoft : state === 'paused' ? warnSoft : 'rgba(120,113,108,0.15)',
            color: sCfg.color,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 14, fontWeight: 700,
          }}>{sCfg.icon}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{sCfg.label}</div>
            <div style={{ fontSize: 11, color: muted, marginTop: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {sCfg.sub}
            </div>
          </div>
        </div>

        <div style={{ height: 0.5, background: 'rgba(0,0,0,0.10)', margin: '4px 8px' }}/>

        {/* actions */}
        {[
          state === 'locked'
            ? { label: 'Pause for 30 seconds', shortcut: '⌘⇧L', primary: true }
            : state === 'paused'
              ? { label: 'Resume now', shortcut: '⌘⇧L', primary: true }
              : { label: 'Enable engine', shortcut: '⌘⇧L', primary: true },
          { label: 'Change anchor display…',  detail: anchor },
          { label: 'Open dashboard',          shortcut: '⌘,' },
        ].map((row, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '7px 12px', borderRadius: 6, cursor: 'pointer',
            background: row.primary ? 'rgba(0,0,0,0.04)' : 'transparent',
          }}>
            <span style={{ flex: 1, fontSize: 13, fontWeight: row.primary ? 500 : 400 }}>{row.label}</span>
            <span style={{ fontFamily: mono, fontSize: 11, color: muted }}>{row.shortcut || row.detail}</span>
          </div>
        ))}

        <div style={{ height: 0.5, background: 'rgba(0,0,0,0.10)', margin: '4px 8px' }}/>

        {/* mini stats */}
        <div style={{
          padding: '8px 12px', display: 'flex', gap: 8,
          fontFamily: mono, fontSize: 10, color: muted,
        }}>
          <span>↯ {interceptCount} intercepts</span>
          <span>·</span>
          <span>3d 14h uptime</span>
        </div>

        <div style={{ height: 0.5, background: 'rgba(0,0,0,0.10)', margin: '4px 8px' }}/>

        {[
          { label: 'Preferences…',         shortcut: '⌘,' },
          { label: 'Quit fixed-dock',      shortcut: '⌘Q' },
        ].map((row) => (
          <div key={row.label} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '7px 12px', borderRadius: 6, cursor: 'pointer',
            fontSize: 13,
          }}>
            <span style={{ flex: 1 }}>{row.label}</span>
            <span style={{ fontFamily: mono, fontSize: 11, color: muted }}>{row.shortcut}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MenuBarArtboard({ state = 'locked' }) {
  return (
    <DesktopBackdrop w={640} h={400}>
      <MenuBarDropdown state={state}/>
    </DesktopBackdrop>
  );
}

// ─── Onboarding flow ──────────────────────────────────────
function OnboardingFrame({ step, total, children, footer }) {
  return (
    <div style={{
      width: 640, height: 480, background: card, fontFamily: font,
      color: ink, position: 'relative', overflow: 'hidden',
      borderRadius: 10,
      boxShadow: '0 0 0 0.5px rgba(0,0,0,0.18), 0 20px 50px rgba(0,0,0,0.25)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* traffic lights */}
      <div style={{ position: 'absolute', top: 14, left: 14, zIndex: 2 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#ff5f57', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#febc2e', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
          <div style={{ width: 12, height: 12, borderRadius: 6, background: '#28c840', border: '0.5px solid rgba(0,0,0,0.15)' }}/>
        </div>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 60px 24px', textAlign: 'center' }}>
        {children}
      </div>

      {/* footer */}
      <div style={{
        padding: '16px 24px', borderTop: `0.5px solid ${ruleSoft}`,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        {/* dots */}
        <div style={{ display: 'flex', gap: 6 }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{
              width: 6, height: 6, borderRadius: 3,
              background: i === step ? accent : 'rgba(0,0,0,0.15)',
            }}/>
          ))}
        </div>
        <div style={{ flex: 1 }}/>
        {footer}
      </div>
    </div>
  );
}

function OnbBtn({ children, primary, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '7px 16px', fontSize: 13, fontWeight: 500,
      background: primary ? accent : card,
      color: primary ? 'white' : ink,
      border: primary ? 'none' : `0.5px solid ${rule}`,
      borderRadius: 7, cursor: 'pointer', fontFamily: font,
    }}>{children}</button>
  );
}

// Step 1 — welcome
function OnboardingWelcome() {
  return (
    <OnboardingFrame step={0} total={3} footer={<><OnbBtn>Skip</OnbBtn><OnbBtn primary>Continue</OnbBtn></>}>
      <div style={{
        width: 88, height: 88, borderRadius: 20,
        background: `linear-gradient(135deg, ${accent} 0%, ${lock} 100%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 24px rgba(60,80,200,0.25)',
        marginBottom: 28,
      }}>
        <svg width="44" height="44" viewBox="0 0 44 44">
          <rect x="6" y="22" width="32" height="14" rx="4" fill="rgba(255,255,255,0.95)"/>
          <circle cx="22" cy="14" r="6" fill="none" stroke="rgba(255,255,255,0.95)" strokeWidth="2.5"/>
          <path d="M18,14 L26,14" stroke={accentInk} strokeWidth="2.5" strokeLinecap="round"/>
        </svg>
      </div>
      <h1 style={{ fontSize: 26, fontWeight: 600, letterSpacing: -0.5, margin: 0 }}>
        Welcome to fixed-dock
      </h1>
      <p style={{ fontSize: 14, color: ink2, marginTop: 12, lineHeight: 1.55, maxWidth: 380 }}>
        A tiny background utility that keeps your Mac&rsquo;s Dock on the
        display you actually want it on — and never let it jump again.
      </p>
      <div style={{
        marginTop: 28, display: 'flex', gap: 24, fontSize: 12, color: muted,
        fontFamily: mono,
      }}>
        <span>✓ Native Swift</span>
        <span>✓ No kernel extensions</span>
        <span>✓ macOS 12+</span>
      </div>
    </OnboardingFrame>
  );
}

// Step 2 — permissions
function OnboardingPermission() {
  return (
    <OnboardingFrame step={1} total={3} footer={<><OnbBtn>Back</OnbBtn><OnbBtn primary>Open System Settings</OnbBtn></>}>
      <div style={{
        width: 76, height: 76, borderRadius: 38,
        background: accentSoft, color: accent,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginBottom: 22, fontSize: 30,
      }}>🔓</div>
      <h2 style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.3, margin: 0 }}>
        Grant Accessibility access
      </h2>
      <p style={{ fontSize: 14, color: ink2, marginTop: 12, lineHeight: 1.55, maxWidth: 420 }}>
        To intercept the events that cause the Dock to jump, fixed-dock needs
        Accessibility permission. We <strong>do not</strong> record keystrokes,
        window contents, or send anything off your Mac.
      </p>
      <div style={{
        marginTop: 22, padding: '12px 16px', background: paper,
        border: `0.5px solid ${rule}`, borderRadius: 8,
        display: 'flex', alignItems: 'center', gap: 12, maxWidth: 420,
      }}>
        <div style={{ fontFamily: mono, fontSize: 11, color: muted, lineHeight: 1.4, textAlign: 'left' }}>
          System Settings &nbsp;›&nbsp; Privacy &amp; Security &nbsp;›&nbsp;<br/>
          Accessibility &nbsp;›&nbsp; Allow fixed-dock
        </div>
      </div>
    </OnboardingFrame>
  );
}

// Step 3 — pick anchor display
function OnboardingAnchor() {
  return (
    <OnboardingFrame step={2} total={3} footer={<><OnbBtn>Back</OnbBtn><OnbBtn primary>Finish</OnbBtn></>}>
      <h2 style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.3, margin: 0 }}>
        Where should the Dock live?
      </h2>
      <p style={{ fontSize: 14, color: ink2, marginTop: 10, lineHeight: 1.55, maxWidth: 420 }}>
        Pick the display you want the Dock anchored to. You can change this
        anytime from the menu bar.
      </p>

      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 16, marginTop: 26 }}>
        {[
          { name: 'Studio Display',     w: 130, h: 78,  selected: true,  primary: true },
          { name: 'LG UltraFine',       w: 108, h: 62,  selected: false, primary: false },
          { name: 'MacBook Pro',        w: 86,  h: 56,  selected: false, primary: false },
        ].map((d, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
            <div style={{
              width: d.w, height: d.h, position: 'relative',
              background: 'linear-gradient(180deg, #2c5278 0%, #4a7ba5 100%)',
              borderRadius: 4,
              border: d.selected ? `2px solid ${lock}` : `0.5px solid rgba(0,0,0,0.2)`,
              boxShadow: d.selected ? `0 0 0 3px ${lockSoft}` : 'none',
            }}>
              <div style={{ height: 6, background: 'rgba(255,255,255,0.18)' }}/>
              {d.selected && (
                <div style={{
                  position: 'absolute', bottom: 4, left: '50%',
                  transform: 'translateX(-50%)',
                  background: 'rgba(255,255,255,0.4)', backdropFilter: 'blur(2px)',
                  padding: 2, borderRadius: 3, display: 'flex', gap: 1.5,
                }}>
                  {Array.from({length: 6}).map((_, j) => (
                    <div key={j} style={{ width: 4, height: 4, borderRadius: 1, background: ['#ff5f57','#febc2e','#28c840','#5e9eff','#a98bff','#ff8aae'][j] }}/>
                  ))}
                </div>
              )}
            </div>
            <div style={{ fontSize: 11, fontWeight: d.selected ? 600 : 400, color: ink }}>{d.name}</div>
            {d.primary && <div style={{ fontFamily: mono, fontSize: 9, color: muted, letterSpacing: 0.4 }}>PRIMARY</div>}
          </div>
        ))}
      </div>
    </OnboardingFrame>
  );
}

Object.assign(window, {
  MenuBarDropdown, MenuBarArtboard, DesktopBackdrop,
  OnboardingWelcome, OnboardingPermission, OnboardingAnchor,
});

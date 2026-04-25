// Focux Personal — design tokens & shared UI primitives

const FX = {
  // Neutral — warm, subtle
  ink:        '#0B1220',    // primary text
  inkSoft:    '#3A455C',    // secondary text
  inkMute:    '#6B7689',    // tertiary
  line:       '#E6E6E0',    // hairlines
  lineSoft:   '#F0EFEA',
  paper:      '#FAFAF8',    // warm off-white (canvas)
  card:       '#FFFFFF',

  // Brand blue — Electric Royal, vibrant & modern
  brand:      '#3B5FE2',    // primary (electric royal)
  brandInk:   '#2440B8',    // darker for text on light
  brandSoft:  '#EAF0FE',    // tint
  brandSofter:'#F4F7FE',
  brandDeep:  '#0D1B5C',    // deepest navy for heroes
  brandAccent:'#7CC0FF',    // lighter cyan-blue accent for highlights

  // Dark mode (Midnight)
  darkBg:     '#0A0F1E',
  darkCard:   '#121A30',
  darkCardHi: '#1A2442',
  darkLine:   '#1F2B4A',
  darkInk:    '#F3F4F8',
  darkInkMute:'#8A94AE',

  // Semantic (subtle, low-sat)
  good:       '#2B6A3F',
  goodSoft:   '#E4F1E9',
  warn:       '#8A5A12',
  warnSoft:   '#FBEED6',
  bad:        '#9E2B2B',
  badSoft:    '#F7E3E3',
};

// Typography — Space Grotesk (display) + Inter (text)
const FXFonts = `
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
`;

const FxDisplay = {
  fontFamily: '"Space Grotesk", system-ui, sans-serif',
  letterSpacing: '-0.02em',
};
const FxText = {
  fontFamily: '"Inter", system-ui, sans-serif',
  letterSpacing: '-0.005em',
};
const FxMono = {
  fontFamily: '"JetBrains Mono", ui-monospace, monospace',
};

// Avatar — deterministic color + initials (no images, on-brand)
function FxAvatar({ name, size = 44, dark = false }) {
  const hash = [...(name || 'A')].reduce((a, c) => a + c.charCodeAt(0), 0);
  const palette = dark
    ? ['#2B4A9E', '#3D5FBE', '#1F3881', '#4A6FD1', '#243B7A', '#6482D9']
    : ['#2B4A9E', '#3D5FBE', '#6482D9', '#1F3881', '#4A6FD1', '#8DA4E2'];
  const bg = palette[hash % palette.length];
  const initials = (name || '?')
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map(s => s[0].toUpperCase())
    .join('');
  return (
    <div style={{
      width: size, height: size, borderRadius: size,
      background: bg, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: '"Space Grotesk", system-ui',
      fontSize: size * 0.38, fontWeight: 600,
      letterSpacing: '0.02em',
      flexShrink: 0,
    }}>{initials}</div>
  );
}

// Status pill — active / inactive / overdue
function FxStatus({ kind = 'active', dark = false, small = false }) {
  const map = {
    active:   { text: 'Ativo',         c: dark ? '#6FE296' : FX.good, bg: dark ? 'rgba(111,226,150,0.12)' : FX.goodSoft },
    inactive: { text: 'Inativo',       c: dark ? '#E2B46F' : FX.warn, bg: dark ? 'rgba(226,180,111,0.14)' : FX.warnSoft },
    overdue:  { text: 'Inadimplente',  c: dark ? '#FF8B8B' : FX.bad,  bg: dark ? 'rgba(255,139,139,0.14)' : FX.badSoft },
    risk:     { text: 'Risco alto',    c: dark ? '#FFB77A' : FX.warn, bg: dark ? 'rgba(255,183,122,0.14)' : FX.warnSoft },
    new:      { text: 'Novo',          c: dark ? '#8DA4E2' : FX.brand, bg: dark ? 'rgba(141,164,226,0.14)' : FX.brandSoft },
  };
  const m = map[kind] || map.active;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: small ? '3px 8px' : '4px 10px',
      borderRadius: 999, background: m.bg, color: m.c,
      ...FxText, fontSize: small ? 10 : 11, fontWeight: 600,
      letterSpacing: '0.02em', textTransform: 'uppercase',
      lineHeight: 1,
    }}>
      <span style={{ width: 5, height: 5, borderRadius: 5, background: m.c }} />
      {m.text}
    </span>
  );
}

// Sparkline — tiny line chart for cards
function FxSparkline({ data = [], w = 90, h = 28, color = FX.brand, fill = true }) {
  if (!data.length) return null;
  const min = Math.min(...data), max = Math.max(...data);
  const range = max - min || 1;
  const pts = data.map((v, i) => {
    const x = (i / (data.length - 1)) * w;
    const y = h - ((v - min) / range) * h * 0.85 - 2;
    return [x, y];
  });
  const path = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
  const area = path + ` L ${w} ${h} L 0 ${h} Z`;
  return (
    <svg width={w} height={h} style={{ display: 'block' }}>
      {fill && <path d={area} fill={color} opacity={0.12} />}
      <path d={path} fill="none" stroke={color} strokeWidth={1.75} strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={pts[pts.length-1][0]} cy={pts[pts.length-1][1]} r={2.5} fill={color} />
    </svg>
  );
}

// Segmented control (YT-Music-ish chip row)
function FxChips({ items, active, onPick, dark = false }) {
  return (
    <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '0 20px',
      scrollbarWidth: 'none', msOverflowStyle: 'none',
    }}>
      <style>{`.fx-chips::-webkit-scrollbar{display:none}`}</style>
      {items.map((t, i) => {
        const on = i === active;
        return (
          <button key={t} onClick={() => onPick && onPick(i)} style={{
            padding: '8px 14px', borderRadius: 999, whiteSpace: 'nowrap',
            border: 'none', cursor: 'pointer',
            background: on ? (dark ? '#fff' : FX.ink) : (dark ? 'rgba(255,255,255,0.06)' : '#fff'),
            color: on ? (dark ? FX.ink : '#fff') : (dark ? FX.darkInk : FX.ink),
            ...FxText, fontSize: 13, fontWeight: 600,
            boxShadow: on ? 'none' : (dark ? 'inset 0 0 0 1px rgba(255,255,255,0.09)' : 'inset 0 0 0 1px ' + FX.line),
            flexShrink: 0, letterSpacing: '-0.01em',
          }}>{t}</button>
        );
      })}
    </div>
  );
}

// Bottom dock — floating glass nav (iOS 26 vibe)
function FxDock({ active = 0, dark = false }) {
  const items = [
    { label: 'Hoje',     icon: 'home'    },
    { label: 'Alunos',   icon: 'users'   },
    { label: 'Treinos',  icon: 'dumbbell'},
    { label: 'Finance',  icon: 'coin'    },
    { label: 'IA',       icon: 'spark'   },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 18, left: 14, right: 14, zIndex: 30,
      borderRadius: 28, overflow: 'hidden',
      background: dark ? 'rgba(20,26,48,0.72)' : 'rgba(255,255,255,0.78)',
      backdropFilter: 'blur(24px) saturate(180%)',
      WebkitBackdropFilter: 'blur(24px) saturate(180%)',
      boxShadow: dark
        ? '0 10px 32px rgba(0,0,0,0.5), inset 0 0 0 0.5px rgba(255,255,255,0.08)'
        : '0 10px 32px rgba(15,30,74,0.14), inset 0 0 0 0.5px rgba(0,0,0,0.04)',
    }}>
      <div style={{ display: 'flex', padding: '10px 6px 14px', justifyContent: 'space-around' }}>
        {items.map((it, i) => {
          const on = i === active;
          const c = on ? (dark ? '#fff' : FX.brand) : (dark ? FX.darkInkMute : FX.inkMute);
          return (
            <div key={it.label} style={{ display: 'flex', flexDirection: 'column',
              alignItems: 'center', gap: 4, padding: '6px 10px', minWidth: 54,
            }}>
              <FxIcon name={it.icon} color={c} size={22} stroke={on ? 2.2 : 1.8} />
              <div style={{
                ...FxText, fontSize: 10.5, fontWeight: on ? 600 : 500,
                color: c, letterSpacing: '-0.005em',
              }}>{it.label}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Tiny icon set — stroke-based, monoline
function FxIcon({ name, size = 20, color = 'currentColor', stroke = 1.8 }) {
  const p = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
    stroke: color, strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'home':     return <svg {...p}><path d="M3 11l9-7 9 7v9a2 2 0 01-2 2h-4v-6h-6v6H5a2 2 0 01-2-2z"/></svg>;
    case 'users':    return <svg {...p}><circle cx="9" cy="8" r="4"/><path d="M2 21v-1a6 6 0 016-6h2a6 6 0 016 6v1"/><circle cx="17" cy="6" r="3"/><path d="M22 16v-1a4 4 0 00-4-4h-1"/></svg>;
    case 'dumbbell': return <svg {...p}><path d="M4 9v6M2 11v2M20 9v6M22 11v2M6 8v8h3V8zM15 8v8h3V8zM9 12h6"/></svg>;
    case 'coin':     return <svg {...p}><ellipse cx="12" cy="6" rx="8" ry="3"/><path d="M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6"/><path d="M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6"/></svg>;
    case 'spark':    return <svg {...p}><path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9zM19 3l.9 2.1L22 6l-2.1.9L19 9l-.9-2.1L16 6l2.1-.9z"/></svg>;
    case 'search':   return <svg {...p}><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.5-4.5"/></svg>;
    case 'bell':     return <svg {...p}><path d="M6 8a6 6 0 0112 0c0 7 3 7 3 9H3c0-2 3-2 3-9zM10 21a2 2 0 004 0"/></svg>;
    case 'chev':     return <svg {...p}><path d="M9 6l6 6-6 6"/></svg>;
    case 'chevDown': return <svg {...p}><path d="M6 9l6 6 6-6"/></svg>;
    case 'plus':     return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
    case 'more':     return <svg {...p}><circle cx="5" cy="12" r="1.2"/><circle cx="12" cy="12" r="1.2"/><circle cx="19" cy="12" r="1.2"/></svg>;
    case 'play':     return <svg {...p} fill={color} stroke="none"><path d="M7 5v14l12-7z"/></svg>;
    case 'calendar': return <svg {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case 'chat':     return <svg {...p}><path d="M21 12a8 8 0 01-11.5 7.2L3 21l1.8-6.5A8 8 0 1121 12z"/></svg>;
    case 'trend':    return <svg {...p}><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></svg>;
    case 'check':    return <svg {...p}><path d="M5 12l4 4 10-10"/></svg>;
    case 'warn':     return <svg {...p}><path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18v.5" /></svg>;
    case 'clock':    return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case 'pix':      return <svg {...p}><path d="M5 5l7 7 7-7M5 19l7-7 7 7"/></svg>;
    case 'flame':    return <svg {...p}><path d="M12 3c1 4 5 5 5 10a5 5 0 11-10 0c0-2 1-3 2-4 0 2 1 3 3 3 0-4-1-6 0-9z"/></svg>;
    case 'timer':    return <svg {...p}><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2M9 2h6"/></svg>;
    case 'dots3':    return <svg {...p} fill={color} stroke="none"><circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/></svg>;
    case 'filter':   return <svg {...p}><path d="M3 5h18M6 12h12M10 19h4"/></svg>;
    case 'send':     return <svg {...p}><path d="M4 12l16-8-6 18-3-8z"/></svg>;
    default:         return <svg {...p}><circle cx="12" cy="12" r="9"/></svg>;
  }
}

// FX Monogram — X-based variants + official F-eagle image mark.
// variant: 'official' (real logo image) | 'blade' | 'prism' | 'arrow' | 'cross' | 'target'
function FxMark({ size = 28, color = FX.brand, gradient = false, id = 'fxm', variant = 'official', onDark = false }) {
  // OFFICIAL — real brand mark (F-eagle, circuit + moon/sun details)
  if (variant === 'official') {
    // Use real logo image with mix-blend-mode:screen so black background disappears.
    // The F (blue/white glow) renders on top of the tile background.
    const tileBg = onDark
      ? `radial-gradient(ellipse at 35% 25%, #1A3A7A 0%, #070E2A 100%)`
      : `radial-gradient(ellipse at 35% 25%, #162D6B 0%, #060C1E 100%)`;
    return (
      <div style={{
        width: size, height: size, borderRadius: size * 0.26,
        background: tileBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden', flexShrink: 0, position: 'relative',
        boxShadow: `0 2px 12px rgba(59,95,226,0.28), inset 0 0 0 1px rgba(124,192,255,0.12)`,
      }}>
        <img
          src="uploads/IMG_3696.png"
          alt="Focux"
          style={{
            width: '130%', height: '130%',
            objectFit: 'cover', objectPosition: 'center',
            mixBlendMode: 'screen',
            position: 'absolute',
            top: '-15%', left: '-15%',
          }}
        />
      </div>
    );
  }

  const gid = `${id}-${variant}`;
  const fg = '#fff';
  const bg = gradient ? `url(#${gid}-g)` : color;
  const grad = gradient && (
    <defs>
      <linearGradient id={`${gid}-g`} x1="0" y1="0" x2="40" y2="40" gradientUnits="userSpaceOnUse">
        <stop offset="0" stopColor={FX.brandAccent} />
        <stop offset="0.5" stopColor={FX.brand} />
        <stop offset="1" stopColor={FX.brandDeep} />
      </linearGradient>
    </defs>
  );

  if (variant === 'blade') {
    // Sharp X with asymmetric blade-like strokes
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        {grad}
        <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
        {/* main blade stroke (top-left to bottom-right), tapered */}
        <path d="M10 9 L14 9 L31 30 L27 31 Z" fill={fg}/>
        {/* counter-stroke (top-right to bottom-left), thinner & lighter */}
        <path d="M30 9 L26 9 L9 30 L13 31 Z" fill={fg} opacity="0.72"/>
        {/* center accent dot — focal point */}
        <circle cx="20" cy="20" r="2.2" fill={fg}/>
      </svg>
    );
  }

  if (variant === 'prism') {
    // X as two overlapping triangular prisms — geometric, sculptural
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        {grad}
        <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
        {/* left prism — top + bottom triangles meeting at center */}
        <path d="M8 8 L20 20 L8 32 Z" fill={fg} opacity="0.55"/>
        <path d="M32 8 L20 20 L32 32 Z" fill={fg} opacity="0.55"/>
        {/* right prism — mirrored, brighter */}
        <path d="M8 8 L20 20 L32 8 Z" fill={fg}/>
        <path d="M8 32 L20 20 L32 32 Z" fill={fg}/>
      </svg>
    );
  }

  if (variant === 'arrow') {
    // 4 arrowheads pointing inward → forming an X at center (FOCUS metaphor)
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        {grad}
        <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
        {/* 4 chevrons pointing to center */}
        <path d="M7 7 L14 7 L20 13 L14 19 L7 12 L11 12 Z M20 13 L20 20" stroke={fg} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
        {/* simpler: 4 triangles arranged as X */}
        <g fill={fg}>
          <path d="M8 8 L16 8 L20 16 Z"/>
          <path d="M32 8 L24 8 L20 16 Z" opacity="0.72"/>
          <path d="M8 32 L16 32 L20 24 Z" opacity="0.72"/>
          <path d="M32 32 L24 32 L20 24 Z"/>
        </g>
        <circle cx="20" cy="20" r="2.4" fill={fg}/>
      </svg>
    );
  }

  if (variant === 'cross') {
    // Bold crosshair X — sniper focus, aligns with eagle-eye concept
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        {grad}
        <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
        {/* X strokes, thick and geometric */}
        <path d="M10 8 L12.5 8 L32 28 L32 30 L29.5 30 L10 10 Z" fill={fg}/>
        <path d="M30 8 L27.5 8 L8 28 L8 30 L10.5 30 L30 10 Z" fill={fg}/>
        {/* crosshair lines extending from X — reinforces precision */}
        <rect x="19.2" y="5" width="1.6" height="5" fill={fg} opacity="0.5"/>
        <rect x="19.2" y="30" width="1.6" height="5" fill={fg} opacity="0.5"/>
        <rect x="5" y="19.2" width="5" height="1.6" fill={fg} opacity="0.5"/>
        <rect x="30" y="19.2" width="5" height="1.6" fill={fg} opacity="0.5"/>
      </svg>
    );
  }

  if (variant === 'target') {
    // X inside concentric rings — precision target
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        {grad}
        <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
        {/* outer ring */}
        <circle cx="20" cy="20" r="13.5" stroke={fg} strokeWidth="1.3" opacity="0.35" fill="none"/>
        {/* inner ring */}
        <circle cx="20" cy="20" r="9" stroke={fg} strokeWidth="1.3" opacity="0.55" fill="none"/>
        {/* bold X */}
        <path d="M13 13 L27 27" stroke={fg} strokeWidth="3.2" strokeLinecap="round"/>
        <path d="M27 13 L13 27" stroke={fg} strokeWidth="3.2" strokeLinecap="round"/>
        {/* center dot */}
        <circle cx="20" cy="20" r="1.8" fill={fg}/>
      </svg>
    );
  }

  // fallback
  return (
    <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
      {grad}
      <rect x="1" y="1" width="38" height="38" rx="11" fill={bg}/>
      <path d="M11 11 L29 29 M29 11 L11 29" stroke={fg} strokeWidth="3.5" strokeLinecap="round"/>
    </svg>
  );
}

// Focux wordmark — "FOCUX PERSONAL" inline (matching the official lockup)
function FxWordmark({ size = 18, color = FX.ink, subtitle = false, tagline = false, subtitleColor, personalWeight = 400 }) {
  const sc = subtitleColor || (color === '#fff' ? 'rgba(255,255,255,0.7)' : FX.inkMute);
  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', lineHeight: 1 }}>
      <div style={{
        ...FxDisplay, fontSize: size, color,
        letterSpacing: '-0.01em',
        display: 'inline-flex', alignItems: 'baseline', gap: size * 0.28,
      }}>
        <span style={{ fontWeight: 700 }}>FOCUX</span>
        {subtitle && (
          <span style={{ fontWeight: personalWeight, letterSpacing: '0.02em', opacity: 0.92 }}>PERSONAL</span>
        )}
      </div>
      {tagline && (
        <div style={{
          ...FxText, fontSize: size * 0.34, fontWeight: 500,
          color: sc, letterSpacing: '0.01em',
          marginTop: size * 0.26, fontStyle: 'italic',
        }}>Treine com dados. Evolua com inteligência.</div>
      )}
    </div>
  );
}

// Lockup — mark + wordmark horizontally aligned
function FxLockup({ size = 22, color = FX.ink, markColor, gradient = false, subtitle = false, tagline = false, variant = 'official', onDark = false }) {
  const mc = markColor || FX.brand;
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: size * 0.55 }}>
      <FxMark size={size * 1.8} color={mc} gradient={gradient} id={'lk-' + size + '-' + variant} variant={variant} onDark={onDark}/>
      <FxWordmark size={size} color={color} subtitle={subtitle} tagline={tagline} />
    </div>
  );
}

Object.assign(window, {
  FX, FXFonts, FxDisplay, FxText, FxMono,
  FxAvatar, FxStatus, FxSparkline, FxChips,
  FxDock, FxIcon, FxMark, FxWordmark, FxLockup,
});

// Treino detail — exercise list with volume, grouping, timer

function FxTreinoDetail({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const t = FxData.treino;

  // group by muscle
  const grouped = {};
  t.exercicios.forEach(ex => {
    (grouped[ex.grupo] = grouped[ex.grupo] || []).push(ex);
  });

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 130 }}>
      {/* Hero — full-bleed dark card (YT Music playlist cover vibe) */}
      <div style={{ position: 'relative',
        background: dark
          ? `linear-gradient(160deg, #1C3273 0%, #0A0F1E 85%)`
          : `linear-gradient(160deg, ${FX.brand} 0%, ${FX.brandDeep} 85%)`,
        padding: '58px 22px 26px',
        color: '#fff',
      }}>
        <svg style={{ position: 'absolute', inset: 0, opacity: 0.06 }} width="100%" height="100%">
          <defs><pattern id="gg3" width="24" height="24" patternUnits="userSpaceOnUse">
            <path d="M 24 0 L 0 0 0 24" fill="none" stroke="#fff" strokeWidth="0.5"/>
          </pattern></defs>
          <rect width="100%" height="100%" fill="url(#gg3)" />
        </svg>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative' }}>
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="10" height="16" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 12px 6px 8px', borderRadius: 999,
            background: 'rgba(255,255,255,0.15)', ...FxText, fontSize: 12, color: '#fff', fontWeight: 600 }}>
            <FxIcon name="spark" size={12} color="#fff" stroke={2} />
            Sugestão IA
          </div>
        </div>

        {/* Cover tile — visual placeholder */}
        <div style={{ marginTop: 22, display: 'flex', alignItems: 'flex-end', gap: 16, position: 'relative' }}>
          <div style={{ width: 108, height: 108, borderRadius: 16, background: 'rgba(255,255,255,0.1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', overflow: 'hidden',
            boxShadow: '0 12px 30px -10px rgba(0,0,0,0.4)',
          }}>
            <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.5" opacity="0.9">
              <path d="M4 9v6M2 11v2M20 9v6M22 11v2M6 8v8h3V8zM15 8v8h3V8zM9 12h6"/>
            </svg>
            <div style={{ position: 'absolute', bottom: 6, left: 8,
              ...FxDisplay, fontSize: 10, color: 'rgba(255,255,255,0.7)', fontWeight: 600,
              textTransform: 'uppercase', letterSpacing: '0.1em',
            }}>Treino A</div>
          </div>
          <div style={{ flex: 1, paddingBottom: 4 }}>
            <div style={{ ...FxText, fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Beatriz Carvalho</div>
            <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 600, color: '#fff', letterSpacing: '-0.025em', marginTop: 2, lineHeight: 1.1 }}>{t.nome}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 8, ...FxText, fontSize: 12, color: 'rgba(255,255,255,0.7)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <FxIcon name="timer" size={13} color="rgba(255,255,255,0.7)" stroke={2} />
                {t.tempoEstimado}min
              </div>
              <div>·</div>
              <div>{t.exercicios.length} exercícios</div>
              <div>·</div>
              <div>{(t.volumeKg/1000).toFixed(1)}t volume</div>
            </div>
          </div>
        </div>

        {/* Action row */}
        <div style={{ display: 'flex', gap: 10, marginTop: 22, position: 'relative' }}>
          <div style={{ flex: 1, height: 48, borderRadius: 14, background: '#fff',
            color: FX.brand, ...FxText, fontSize: 14, fontWeight: 700,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
          }}>
            <FxIcon name="play" size={14} color={FX.brand} />
            Iniciar treino
          </div>
          <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(255,255,255,0.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <FxIcon name="send" size={17} color="#fff" stroke={1.8} />
          </div>
          <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(255,255,255,0.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <FxIcon name="more" size={18} color="#fff" stroke={2} />
          </div>
        </div>
      </div>

      {/* Stats ribbon */}
      <div style={{ padding: '18px 16px 8px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
        <MiniMetric dark={dark} label="Nível" value="Interm." />
        <MiniMetric dark={dark} label="Grupos" value="3" />
        <MiniMetric dark={dark} label="Última" value="Qua 15/4" />
      </div>

      {/* Exercise list — grouped with section headers */}
      <div style={{ padding: '18px 20px 10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>Exercícios</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, ...FxText, fontSize: 12.5, fontWeight: 600, color: dark ? '#8DA4E2' : FX.brand }}>
          <FxIcon name="plus" size={14} color="currentColor" stroke={2.2} /> Adicionar
        </div>
      </div>

      {Object.entries(grouped).map(([grupo, items]) => (
        <div key={grupo} style={{ padding: '0 16px', marginBottom: 14 }}>
          <div style={{ padding: '4px 4px 10px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ ...FxText, fontSize: 11, color: mute, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{grupo}</div>
            <div style={{ flex: 1, height: 0.5, background: line }} />
            <div style={{ ...FxText, fontSize: 11, color: mute, fontWeight: 500 }}>{items.length} ex.</div>
          </div>
          <div style={{ background: cardBg, borderRadius: 20, overflow: 'hidden',
            boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
          }}>
            {items.map((ex, i) => (
              <ExRow key={ex.n} ex={ex} dark={dark} isLast={i === items.length - 1} />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function ExRow({ ex, dark, isLast }) {
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '14px 14px',
      borderBottom: isLast ? 'none' : '0.5px solid ' + line,
    }}>
      <div style={{ width: 36, height: 36, borderRadius: 10,
        background: dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft,
        color: dark ? '#8DA4E2' : FX.brand,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        ...FxDisplay, fontSize: 14, fontWeight: 600,
      }}>{ex.n}</div>
      <div style={{ flex: 1, marginLeft: 12, minWidth: 0 }}>
        <div style={{ ...FxText, fontSize: 14, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>{ex.nome}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 3 }}>
          <div style={{ ...FxText, fontSize: 12, color: mute }}>
            <span style={{ color: ink, fontWeight: 600 }}>{ex.series}×{ex.reps}</span>
          </div>
          <div style={{ width: 3, height: 3, borderRadius: 3, background: mute, opacity: 0.5 }} />
          <div style={{ ...FxText, fontSize: 12, color: mute }}>
            <span style={{ color: ink, fontWeight: 600 }}>{ex.carga}kg</span>
          </div>
          <div style={{ width: 3, height: 3, borderRadius: 3, background: mute, opacity: 0.5 }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 3, ...FxText, fontSize: 11.5, color: mute }}>
            <FxIcon name="clock" size={11} color="currentColor" stroke={2} />
            {ex.desc}s
          </div>
        </div>
      </div>
      <div style={{ width: 32, height: 32, borderRadius: 32,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <FxIcon name="more" size={16} color={mute} stroke={2} />
      </div>
    </div>
  );
}

window.FxTreinoDetail = FxTreinoDetail;

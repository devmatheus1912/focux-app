// Aluno detail — hero + stats + modules list

function FxAlunoDetail({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const a = FxData.alunoFoco;

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      {/* HERO — gradient with back/more buttons */}
      <div style={{ position: 'relative',
        background: dark
          ? `linear-gradient(180deg, #1C3273 0%, #0F1E4A 100%)`
          : `linear-gradient(180deg, ${FX.brand} 0%, ${FX.brandDeep} 100%)`,
        padding: '62px 20px 32px',
      }}>
        {/* decorative grid */}
        <svg style={{ position: 'absolute', inset: 0, opacity: 0.06 }} width="100%" height="100%">
          <defs>
            <pattern id="gg2" width="28" height="28" patternUnits="userSpaceOnUse">
              <path d="M 28 0 L 0 0 0 28" fill="none" stroke="#fff" strokeWidth="0.5"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#gg2)" />
        </svg>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, position: 'relative' }}>
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.15)',
            backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="10" height="16" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.15)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FxIcon name="chat" size={17} color="#fff" stroke={1.8} />
            </div>
            <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.15)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FxIcon name="more" size={17} color="#fff" stroke={2} />
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 14, position: 'relative' }}>
          <div style={{ width: 72, height: 72, borderRadius: 72, background: '#fff', color: FX.brand,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            ...FxDisplay, fontSize: 26, fontWeight: 600,
            boxShadow: '0 8px 20px -8px rgba(0,0,0,0.3)',
          }}>BC</div>
          <div>
            <div style={{ ...FxText, fontSize: 11, color: 'rgba(255,255,255,0.6)', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Desde {a.inicio}</div>
            <div style={{ ...FxDisplay, fontSize: 26, color: '#fff', fontWeight: 600, letterSpacing: '-0.025em', marginTop: 2 }}>{a.nome}</div>
            <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.75)', marginTop: 2 }}>{a.idade} anos · {a.obj}</div>
          </div>
        </div>

        {/* stat strip */}
        <div style={{ display: 'flex', marginTop: 22, gap: 16, position: 'relative' }}>
          <HeroStat label="Aderência" value={`${a.aderencia}%`} />
          <div style={{ width: 1, background: 'rgba(255,255,255,0.18)' }} />
          <HeroStat label="Streak" value={`${a.streak}d`} icon="flame" />
          <div style={{ width: 1, background: 'rgba(255,255,255,0.18)' }} />
          <HeroStat label="PRs · mês" value={`${a.prMes}`} />
          <div style={{ width: 1, background: 'rgba(255,255,255,0.18)' }} />
          <HeroStat label="Treinos" value={`${a.treinosTotal}`} />
        </div>
      </div>

      {/* Weight evolution card */}
      <div style={{ padding: '20px 16px 0' }}>
        <div style={{ background: cardBg, borderRadius: 22, padding: 18,
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ ...FxText, fontSize: 11.5, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Peso · últimas 7 semanas</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
                <div style={{ ...FxDisplay, fontSize: 32, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>{a.peso}<span style={{ fontSize: 14, color: mute, fontWeight: 400, marginLeft: 3 }}>kg</span></div>
                <div style={{ display: 'inline-flex', alignItems: 'center', gap: 3,
                  ...FxText, fontSize: 12, fontWeight: 600,
                  color: dark ? '#6FE296' : FX.good,
                  background: dark ? 'rgba(111,226,150,0.12)' : FX.goodSoft,
                  padding: '3px 8px', borderRadius: 999,
                }}>
                  <svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M5 7V3M3 5l2-2 2 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  −3.9 kg
                </div>
              </div>
            </div>
            <div style={{ ...FxText, fontSize: 11.5, color: mute, fontWeight: 500 }}>Meta · 62 kg</div>
          </div>
          <div style={{ marginTop: 14 }}>
            <FxSparkline data={a.evolucao} w={320} h={72} color={dark ? '#8DA4E2' : FX.brand} fill />
          </div>
        </div>
      </div>

      {/* Measurements */}
      <div style={{ padding: '16px 16px 0', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
        {Object.entries(a.medidas).map(([k, v]) => (
          <div key={k} style={{ background: cardBg, borderRadius: 14, padding: '12px 10px',
            boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line, textAlign: 'center',
          }}>
            <div style={{ ...FxText, fontSize: 10, color: mute, textTransform: 'uppercase', fontWeight: 600, letterSpacing: '0.06em' }}>{k}</div>
            <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, marginTop: 4, letterSpacing: '-0.02em' }}>{v}<span style={{ fontSize: 10, color: mute, fontWeight: 400 }}>cm</span></div>
          </div>
        ))}
      </div>

      {/* Modules grid */}
      <div style={{ padding: '24px 20px 12px', ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>Ferramentas</div>

      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <ModuleTile dark={dark} icon="dumbbell" label="Treinos" sub="Push A ativo" />
        <ModuleTile dark={dark} icon="spark"    label="IA · Progressão" sub="Sugerir cargas" highlight />
        <ModuleTile dark={dark} icon="trend"    label="Evolução" sub="Medidas e PRs" />
        <ModuleTile dark={dark} icon="users"    label="Anamnese" sub="Completa ✓" />
        <ModuleTile dark={dark} icon="coin"     label="Mensalidades" sub="Em dia" />
        <ModuleTile dark={dark} icon="chat"     label="Chat" sub="2 não lidas" badge />
      </div>
    </div>
  );
}

function HeroStat({ label, value, icon }) {
  return (
    <div style={{ flex: 1 }}>
      <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 3, ...FxDisplay, fontSize: 20, fontWeight: 600, color: '#fff', marginTop: 3, letterSpacing: '-0.02em' }}>
        {icon && <FxIcon name={icon} size={14} color="#FFD37A" stroke={2.2} />}
        {value}
      </div>
    </div>
  );
}

function ModuleTile({ icon, label, sub, dark, highlight, badge }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const accent = dark ? '#8DA4E2' : FX.brand;
  return (
    <div style={{
      background: highlight ? (dark ? '#1C3273' : FX.brandSoft) : cardBg,
      borderRadius: 16, padding: 14, position: 'relative',
      boxShadow: dark ? (highlight ? 'none' : 'none') : ('inset 0 0 0 1px ' + (highlight ? 'transparent' : line)),
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 32, height: 32, borderRadius: 10,
          background: highlight ? (dark ? 'rgba(255,255,255,0.12)' : FX.brand) : (dark ? 'rgba(141,164,226,0.12)' : FX.brandSofter),
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <FxIcon name={icon} size={16} color={highlight ? '#fff' : accent} stroke={1.9} />
        </div>
        {badge && <div style={{ width: 8, height: 8, borderRadius: 8, background: FX.brand }} />}
      </div>
      <div style={{ ...FxText, fontSize: 13.5, fontWeight: 600, color: highlight && !dark ? FX.brand : ink, marginTop: 10, letterSpacing: '-0.01em' }}>{label}</div>
      <div style={{ ...FxText, fontSize: 11.5, color: highlight && !dark ? FX.brandInk : mute, marginTop: 2, opacity: highlight && !dark ? 0.75 : 1 }}>{sub}</div>
    </div>
  );
}

window.FxAlunoDetail = FxAlunoDetail;

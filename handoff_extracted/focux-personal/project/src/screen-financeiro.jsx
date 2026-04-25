// Financeiro dashboard

function FxFinanceiro({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const d = FxData.financeiro;

  const maxBar = Math.max(...d.evolucao.map(x => x.v));

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{ padding: '8px 20px 18px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ ...FxText, fontSize: 12, color: mute, fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{d.mesAtual}</div>
          <div style={{ ...FxDisplay, fontSize: 32, color: ink, fontWeight: 600, letterSpacing: '-0.03em', marginTop: 2 }}>Financeiro</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 12px',
          background: dark ? 'rgba(255,255,255,0.05)' : '#fff', borderRadius: 999,
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
        }}>
          <div style={{ ...FxText, fontSize: 12, color: ink, fontWeight: 600 }}>abril</div>
          <FxIcon name="chevDown" size={14} color={mute} stroke={2} />
        </div>
      </div>

      {/* Hero — ring with received amount */}
      <div style={{ padding: '0 16px 18px' }}>
        <div style={{ background: cardBg, borderRadius: 28, padding: '22px 20px',
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
          display: 'flex', alignItems: 'center', gap: 22,
        }}>
          {/* Ring */}
          <svg width="120" height="120" viewBox="0 0 120 120">
            <circle cx="60" cy="60" r="48" fill="none" stroke={dark ? 'rgba(255,255,255,0.08)' : FX.brandSoft} strokeWidth="10" />
            <circle cx="60" cy="60" r="48"
              fill="none"
              stroke={dark ? '#8DA4E2' : FX.brand}
              strokeWidth="10" strokeLinecap="round"
              strokeDasharray={`${2 * Math.PI * 48 * (d.recebido / d.previsto)} ${2 * Math.PI * 48}`}
              transform="rotate(-90 60 60)"
            />
            <text x="60" y="55" textAnchor="middle" fill={ink} style={{ ...FxDisplay }} fontSize="11" fontWeight="600" letterSpacing="0.1em">RECEBIDO</text>
            <text x="60" y="76" textAnchor="middle" fill={ink} style={{ ...FxDisplay }} fontSize="21" fontWeight="600" letterSpacing="-0.03em">{Math.round(100 * d.recebido / d.previsto)}%</text>
          </svg>
          <div style={{ flex: 1 }}>
            <div style={{ ...FxText, fontSize: 11, color: mute, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Recebido em abril</div>
            <div style={{ ...FxDisplay, fontSize: 32, fontWeight: 600, color: ink, letterSpacing: '-0.03em', marginTop: 3, lineHeight: 1 }}>R$ 8.420</div>
            <div style={{ ...FxText, fontSize: 12.5, color: mute, marginTop: 6 }}>Previsto <span style={{ color: ink, fontWeight: 600 }}>R$ 11.750</span></div>
            <div style={{ marginTop: 10, padding: '7px 12px', borderRadius: 10, background: dark ? 'rgba(255,139,139,0.12)' : FX.badSoft,
              ...FxText, fontSize: 12, fontWeight: 600, color: dark ? '#FF8B8B' : FX.bad, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <FxIcon name="warn" size={12} color="currentColor" stroke={2} />
              2 inadimpl. · R$ 830
            </div>
          </div>
        </div>
      </div>

      {/* Tri-grid metrics */}
      <div style={{ padding: '0 16px 22px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
        <MiniMetric dark={dark} label="Pendente" value="R$ 3.330" />
        <MiniMetric dark={dark} label="Ticket" value="R$ 349" />
        <MiniMetric dark={dark} label="Acumul." value="R$ 39k" />
      </div>

      {/* Evolução — bar chart */}
      <div style={{ padding: '0 16px' }}>
        <div style={{ background: cardBg, borderRadius: 22, padding: '18px 16px 14px',
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>Evolução · 6 meses</div>
            <div style={{ ...FxText, fontSize: 11, color: mute }}>+60% vs nov</div>
          </div>
          <div style={{ marginTop: 16, height: 130, display: 'flex', alignItems: 'flex-end', gap: 10 }}>
            {d.evolucao.map((e, i) => {
              const h = (e.v / maxBar) * 100;
              const current = i === d.evolucao.length - 1;
              return (
                <div key={e.m} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <div style={{ ...FxText, fontSize: 9.5, color: current ? ink : mute, fontWeight: current ? 600 : 400 }}>
                    {(e.v/1000).toFixed(1)}k
                  </div>
                  <div style={{ width: '100%', height: `${h}%`, position: 'relative',
                    background: current
                      ? (dark ? `linear-gradient(180deg, #8DA4E2 0%, #3D5FBE 100%)` : `linear-gradient(180deg, ${FX.brand} 0%, ${FX.brandInk} 100%)`)
                      : (dark ? 'rgba(141,164,226,0.2)' : FX.brandSoft),
                    borderRadius: '6px 6px 2px 2px',
                  }} />
                  <div style={{ ...FxText, fontSize: 10, color: current ? ink : mute, fontWeight: current ? 600 : 500, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{e.m}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Vencimentos próximos */}
      <div style={{ padding: '22px 20px 10px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>Vencimentos</div>
        <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: dark ? '#8DA4E2' : FX.brand }}>Cobrar todos →</div>
      </div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {d.vencimentos.map((v, i) => <VencimentoRow key={i} v={v} dark={dark} />)}
      </div>

      {/* Top alunos */}
      <div style={{ padding: '22px 20px 10px' }}>
        <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>Top alunos · acumulado</div>
      </div>
      <div style={{ padding: '0 16px' }}>
        <div style={{ background: cardBg, borderRadius: 20, overflow: 'hidden',
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
        }}>
          {d.topAlunos.map((t, i) => (
            <div key={t.nome} style={{ display: 'flex', alignItems: 'center', padding: '12px 14px',
              borderBottom: i < d.topAlunos.length - 1 ? '0.5px solid ' + line : 'none',
            }}>
              <div style={{ width: 26, height: 26, borderRadius: 26,
                background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
                color: dark ? '#8DA4E2' : FX.brand,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                ...FxDisplay, fontSize: 12, fontWeight: 600,
              }}>{i + 1}</div>
              <FxAvatar name={t.nome} size={32} dark={dark} />
              <div style={{ flex: 1, marginLeft: 10, ...FxText, fontSize: 13.5, fontWeight: 500, color: ink }}>{t.nome}</div>
              <div style={{ ...FxDisplay, fontSize: 14, fontWeight: 600, color: ink }}>R$ {(t.total/1000).toFixed(1)}k</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function MiniMetric({ label, value, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  return (
    <div style={{ background: cardBg, borderRadius: 14, padding: '11px 12px',
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + FX.line,
    }}>
      <div style={{ ...FxText, fontSize: 10.5, color: mute, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{label}</div>
      <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, color: ink, marginTop: 4, letterSpacing: '-0.02em' }}>{value}</div>
    </div>
  );
}

function VencimentoRow({ v, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const atrasado = v.status === 'atrasado';
  const c = atrasado ? (dark ? '#FF8B8B' : FX.bad) : (dark ? '#E2B46F' : FX.warn);
  return (
    <div style={{ background: cardBg, borderRadius: 16, padding: '12px 14px',
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <FxAvatar name={v.nome} size={38} dark={dark} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ ...FxText, fontSize: 13.5, fontWeight: 600, color: ink }}>{v.nome}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 2 }}>
          <span style={{ width: 5, height: 5, borderRadius: 5, background: c }} />
          <div style={{ ...FxText, fontSize: 11.5, color: c, fontWeight: 600 }}>
            {atrasado ? `Atraso de ${v.dias}d` : `Vence em ${v.dias}d`}
          </div>
          <div style={{ ...FxText, fontSize: 11.5, color: mute }}>· {v.mes}</div>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
        <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>R$ {v.valor}</div>
        <div style={{ padding: '4px 10px', borderRadius: 999,
          background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
          color: dark ? '#8DA4E2' : FX.brand, ...FxText, fontSize: 11, fontWeight: 600,
        }}>Cobrar</div>
      </div>
    </div>
  );
}

window.FxFinanceiro = FxFinanceiro;

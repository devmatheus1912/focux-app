// IA Copiloto — geração de treino/dieta personalizado com Claude AI

function FxIAGerador({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const resultado = {
    tipo: 'Treino',
    aluno: 'Beatriz Carvalho',
    titulo: 'Superior Push B — Ciclo de Hipertrofia',
    semanas: 4,
    dias: 3,
    exercicios: [
      { grupo: 'Peito', nome: 'Supino declinado c/ halteres', series: 4, reps: '10-12', progressao: '+2.5kg/semana' },
      { grupo: 'Ombro', nome: 'Arnold press',                series: 3, reps: '8-10',  progressao: '+1.25kg/semana' },
      { grupo: 'Ombro', nome: 'Face pull no cabo',           series: 3, reps: '15-20', progressao: 'manter RPE 7' },
      { grupo: 'Tríceps', nome: 'Tríceps corda supinado',   series: 3, reps: '12-15', progressao: '+2kg/semana' },
    ],
    obs: 'Baseado em 58 treinos históricos e progressão de carga das últimas 12 semanas. RPE alvo: 7-8. Descansada de 5-6 dias antes do teste de 1RM.',
  };

  // Simulated streaming state — "gerado"
  const progresso = 100;

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{ padding: '10px 20px 18px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <div style={{ width: 30, height: 30, borderRadius: 10,
              background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <FxIcon name="spark" size={15} color={brand} stroke={1.8} />
            </div>
            <div style={{ ...FxText, fontSize: 12, color: brand, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase' }}>IA Focux</div>
          </div>
          <div style={{ ...FxDisplay, fontSize: 28, color: ink, fontWeight: 600, letterSpacing: '-0.03em', lineHeight: 1 }}>Copiloto</div>
        </div>
        <div style={{ padding: '8px 14px', borderRadius: 999,
          background: dark ? 'rgba(255,255,255,0.06)' : '#fff', border: `1px solid ${line}`,
          ...FxText, fontSize: 12, fontWeight: 600, color: ink, display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <FxAvatar name="Beatriz Carvalho" size={18} dark={dark} />
          Beatriz
        </div>
      </div>

      {/* Mode selector */}
      <div style={{ padding: '0 16px 18px' }}>
        <div style={{ background: cardBg, borderRadius: 16, padding: 4, border: `1px solid ${line}`,
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
        }}>
          {['Treino', 'Dieta', 'Progressão'].map((t, i) => (
            <div key={t} style={{ padding: '10px', borderRadius: 12, textAlign: 'center',
              background: i === 0 ? brand : 'transparent',
              color: i === 0 ? '#fff' : mute,
              ...FxText, fontSize: 13, fontWeight: 600,
            }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Context chips */}
      <div style={{ padding: '0 16px 20px', display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {[
          { label: 'Hipertrofia', icon: '💪' },
          { label: 'Push/Pull/Legs', icon: '🔄' },
          { label: '3x semana', icon: '📅' },
          { label: 'Intermediária', icon: '⚡' },
          { label: '58 treinos histórico', icon: '📊' },
        ].map(c => (
          <div key={c.label} style={{ display: 'flex', alignItems: 'center', gap: 5,
            padding: '7px 11px', borderRadius: 999,
            background: dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft,
            border: `1px solid ${dark ? 'rgba(141,164,226,0.2)' : 'rgba(59,95,226,0.15)'}`,
            ...FxText, fontSize: 12, fontWeight: 500, color: ink,
          }}>
            <span style={{ fontSize: 11 }}>{c.icon}</span>
            {c.label}
          </div>
        ))}
      </div>

      {/* Generation progress — complete */}
      <div style={{ padding: '0 16px 18px' }}>
        <div style={{ background: cardBg, borderRadius: 20, padding: '16px 18px', border: `1px solid ${line}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: 8, background: '#2BB673' }}/>
              <div style={{ ...FxText, fontSize: 12, fontWeight: 600, color: ink }}>Geração concluída</div>
            </div>
            <div style={{ ...FxMono, fontSize: 11, color: mute }}>1.2s</div>
          </div>
          <div style={{ height: 5, borderRadius: 5, background: dark ? 'rgba(255,255,255,0.07)' : FX.brandSoft, overflow: 'hidden' }}>
            <div style={{ width: '100%', height: '100%', background: '#2BB673', borderRadius: 5 }}/>
          </div>
          <div style={{ display: 'flex', gap: 14, marginTop: 12 }}>
            {['Analisando histórico…', 'Calibrando carga…', 'Gerando treino…'].map((s, i) => (
              <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 4, ...FxText, fontSize: 10.5, color: '#2BB673', fontWeight: 500 }}>
                <svg width="10" height="8" viewBox="0 0 12 10" fill="none"><path d="M1 5l3 4L11 1" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                {s}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Result card */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{ background: cardBg, borderRadius: 22, overflow: 'hidden', border: `1px solid ${line}` }}>
          {/* result header */}
          <div style={{
            background: dark ? `linear-gradient(135deg, #1A2852, #0F1A3C)` : `linear-gradient(135deg, ${FX.brand}, ${FX.brandDeep})`,
            padding: '18px 18px 16px', color: '#fff', position: 'relative', overflow: 'hidden',
          }}>
            <svg style={{ position: 'absolute', right: -10, top: -10, opacity: 0.08 }} width="130" height="130" viewBox="0 0 40 40">
              <rect x="1" y="1" width="38" height="38" rx="11" fill="#fff"/>
              <path d="M10 9 L14 9 L31 30 L27 31 Z" fill="#000"/>
              <path d="M30 9 L26 9 L9 30 L13 31 Z" fill="#000" opacity="0.7"/>
            </svg>
            <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.7)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 6 }}>
              RESULTADO · {resultado.tipo}
            </div>
            <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 600, letterSpacing: '-0.02em', lineHeight: 1.2, marginBottom: 12 }}>
              {resultado.titulo}
            </div>
            <div style={{ display: 'flex', gap: 16 }}>
              <div>
                <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Duração</div>
                <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600 }}>{resultado.semanas} sem.</div>
              </div>
              <div style={{ width: 1, background: 'rgba(255,255,255,0.15)' }}/>
              <div>
                <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Freq.</div>
                <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600 }}>{resultado.dias}x/sem</div>
              </div>
              <div style={{ width: 1, background: 'rgba(255,255,255,0.15)' }}/>
              <div>
                <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Exerc.</div>
                <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600 }}>{resultado.exercicios.length}</div>
              </div>
            </div>
          </div>

          {/* exercises */}
          <div style={{ padding: '12px 0' }}>
            {resultado.exercicios.map((ex, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', padding: '11px 16px',
                borderBottom: i < resultado.exercicios.length - 1 ? `0.5px solid ${line}` : 'none',
              }}>
                <div style={{ width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                  background: dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  ...FxDisplay, fontSize: 12, fontWeight: 700, color: brand,
                }}>{i+1}</div>
                <div style={{ flex: 1, marginLeft: 12, minWidth: 0 }}>
                  <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: ink }}>{ex.nome}</div>
                  <div style={{ ...FxText, fontSize: 11, color: mute, marginTop: 1 }}>
                    {ex.series}× · {ex.reps} reps ·
                    <span style={{ color: dark ? '#6FE296' : FX.good, fontWeight: 600 }}> {ex.progressao}</span>
                  </div>
                </div>
                <div style={{ ...FxText, fontSize: 10, color: mute, padding: '3px 8px', borderRadius: 999,
                  background: dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft,
                }}>{ex.grupo}</div>
              </div>
            ))}
          </div>

          {/* obs */}
          <div style={{ margin: '0 14px 14px', padding: '12px 14px', borderRadius: 14,
            background: dark ? 'rgba(141,164,226,0.08)' : FX.brandSofter,
            border: `1px solid ${dark ? 'rgba(141,164,226,0.15)' : 'rgba(59,95,226,0.12)'}`,
          }}>
            <div style={{ ...FxText, fontSize: 11.5, color: mute, lineHeight: 1.5 }}>
              <span style={{ color: brand, fontWeight: 700 }}>Nota IA: </span>{resultado.obs}
            </div>
          </div>
        </div>
      </div>

      {/* Action row */}
      <div style={{ padding: '0 16px', display: 'flex', gap: 10 }}>
        <div style={{ flex: 1, height: 50, borderRadius: 14, background: brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          color: '#fff', ...FxText, fontSize: 14, fontWeight: 700,
          boxShadow: `0 6px 16px -6px rgba(59,95,226,0.5)`,
        }}>
          <FxIcon name="dumbbell" size={16} color="#fff" stroke={2} />
          Atribuir à Beatriz
        </div>
        <div style={{ width: 50, height: 50, borderRadius: 14, background: cardBg,
          border: `1px solid ${line}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <FxIcon name="more" size={18} color={mute} stroke={2} />
        </div>
      </div>
    </div>
  );
}

window.FxIAGerador = FxIAGerador;

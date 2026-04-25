// Check-in / IA — aluno executando treino em tempo real, com sugestão da IA

function FxCheckinIA({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  // current exercise state
  const exercicio = { nome: 'Supino reto com barra', grupo: 'Peito', n: 1, total: 7 };
  const series = [
    { n: 1, reps: 10, carga: 65, status: 'done', rpe: 7 },
    { n: 2, reps: 10, carga: 70, status: 'done', rpe: 8 },
    { n: 3, reps: 9,  carga: 70, status: 'current' },
    { n: 4, reps: '-', carga: 70, status: 'pending' },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 130 }}>
      {/* Top status bar — workout in progress */}
      <div style={{
        padding: '58px 20px 16px',
        background: dark
          ? `linear-gradient(180deg, #0A0F1E 0%, ${FX.darkBg} 100%)`
          : `linear-gradient(180deg, #F2F6FF 0%, ${bg} 100%)`,
        position: 'relative',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 34, height: 34, borderRadius: 34, background: cardBg,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: dark ? 'none' : '0 1px 2px rgba(0,0,0,0.04)',
              border: `1px solid ${line}`,
            }}>
              <svg width="8" height="14" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke={ink} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
            <div>
              <div style={{ ...FxText, fontSize: 10, color: mute, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Treino em andamento</div>
              <div style={{ ...FxDisplay, fontSize: 15, color: ink, fontWeight: 600 }}>Push A · Superior</div>
            </div>
          </div>
          {/* LIVE pulse */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '5px 10px', borderRadius: 999,
            background: dark ? 'rgba(255,107,107,0.16)' : '#FEE4E4',
          }}>
            <div style={{ width: 6, height: 6, borderRadius: 6, background: '#E64545',
              animation: 'fxpulse 1.2s ease-in-out infinite',
            }}/>
            <div style={{ ...FxMono, fontSize: 11, color: '#E64545', fontWeight: 700, letterSpacing: '0.08em' }}>AO VIVO</div>
          </div>
        </div>
        <style>{`@keyframes fxpulse { 0%,100%{opacity:1} 50%{opacity:0.3} }`}</style>

        {/* Giant timer */}
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 14 }}>
          <div style={{ ...FxDisplay, fontSize: 56, fontWeight: 600, color: ink, letterSpacing: '-0.04em', lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>
            18<span style={{ color: mute, fontWeight: 500 }}>:</span>42
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <div style={{ ...FxText, fontSize: 11, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>decorrido</div>
            <div style={{ ...FxMono, fontSize: 12, color: brand, fontWeight: 600 }}>est. 52 min · 36% ✓</div>
          </div>
        </div>

        {/* progress bar */}
        <div style={{ height: 4, background: dark ? 'rgba(255,255,255,0.08)' : 'rgba(43,74,158,0.12)',
          borderRadius: 4, marginTop: 14, overflow: 'hidden',
        }}>
          <div style={{ height: '100%', width: '36%', background: brand, borderRadius: 4 }}/>
        </div>
      </div>

      {/* Current exercise card — big hero */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{ background: cardBg, borderRadius: 24, padding: 20, border: `1px solid ${line}`,
          boxShadow: dark ? 'none' : '0 1px 3px rgba(12,20,50,0.04)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14 }}>
            <div>
              <div style={{ ...FxText, fontSize: 11, color: brand, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                {exercicio.n}/{exercicio.total} · {exercicio.grupo}
              </div>
              <div style={{ ...FxDisplay, fontSize: 22, fontWeight: 600, color: ink, letterSpacing: '-0.02em', marginTop: 4, lineHeight: 1.15 }}>
                {exercicio.nome}
              </div>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: dark ? 'rgba(255,255,255,0.06)' : FX.paperSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center', border: `1px solid ${line}`,
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke={ink} strokeWidth="1.8"/><path d="M12 8v4l2 2" stroke={ink} strokeWidth="1.8" strokeLinecap="round"/></svg>
            </div>
          </div>

          {/* Series grid */}
          <div style={{ display: 'grid', gap: 8 }}>
            {series.map(s => {
              const isCurrent = s.status === 'current';
              const isDone = s.status === 'done';
              const isPending = s.status === 'pending';
              return (
                <div key={s.n} style={{
                  display: 'grid', gridTemplateColumns: '36px 1fr 1fr 1fr 36px', alignItems: 'center', gap: 10,
                  padding: '12px 14px', borderRadius: 14,
                  background: isCurrent ? (dark ? 'rgba(122,150,220,0.14)' : '#EEF2FF') : (isDone ? 'transparent' : 'transparent'),
                  border: isCurrent ? `1.5px solid ${brand}` : `1px solid ${line}`,
                  opacity: isPending ? 0.55 : 1,
                }}>
                  <div style={{ ...FxMono, fontSize: 13, fontWeight: 700, color: isCurrent ? brand : mute }}>
                    {String(s.n).padStart(2,'0')}
                  </div>
                  <div>
                    <div style={{ ...FxText, fontSize: 10, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>reps</div>
                    <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, fontVariantNumeric: 'tabular-nums' }}>{s.reps}</div>
                  </div>
                  <div>
                    <div style={{ ...FxText, fontSize: 10, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>carga</div>
                    <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, fontVariantNumeric: 'tabular-nums' }}>
                      {s.carga}<span style={{ fontSize: 11, color: mute, fontWeight: 500, marginLeft: 2 }}>kg</span>
                    </div>
                  </div>
                  <div>
                    <div style={{ ...FxText, fontSize: 10, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>RPE</div>
                    <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, fontVariantNumeric: 'tabular-nums' }}>
                      {s.rpe || '–'}
                    </div>
                  </div>
                  <div>
                    {isDone && (
                      <div style={{ width: 28, height: 28, borderRadius: 28, background: '#2BB673',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        <svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5l3 3 7-7" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                      </div>
                    )}
                    {isCurrent && (
                      <div style={{ width: 28, height: 28, borderRadius: 28, background: brand,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        <div style={{ width: 8, height: 8, borderRadius: 2, background: '#fff' }}/>
                      </div>
                    )}
                    {isPending && (
                      <div style={{ width: 28, height: 28, borderRadius: 28, border: `1.5px dashed ${line}` }}/>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* IA suggestion card — the magic */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          position: 'relative', overflow: 'hidden',
          background: dark
            ? `linear-gradient(135deg, #1A2852 0%, #0F1A3C 100%)`
            : `linear-gradient(135deg, ${FX.brand} 0%, ${FX.brandDeep} 100%)`,
          borderRadius: 24, padding: 20, color: '#fff',
        }}>
          {/* ambient eagle-wing grid */}
          <svg style={{ position: 'absolute', right: -20, top: -20, opacity: 0.12 }} width="160" height="160" viewBox="0 0 160 160" fill="none">
            <circle cx="80" cy="80" r="50" stroke="#fff" strokeWidth="1"/>
            <circle cx="80" cy="80" r="70" stroke="#fff" strokeWidth="1"/>
            <path d="M40 80 Q80 40 120 80 Q80 120 40 80" stroke="#fff" strokeWidth="1" fill="none"/>
          </svg>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            {/* IA sparkle icon */}
            <div style={{ width: 28, height: 28, borderRadius: 10, background: 'rgba(255,255,255,0.18)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', backdropFilter: 'blur(8px)',
            }}>
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                <path d="M7 1l1.4 3.6L12 6l-3.6 1.4L7 11 5.6 7.4 2 6l3.6-1.4L7 1z" fill="#fff"/>
                <circle cx="11.5" cy="11.5" r="1" fill="#fff"/>
              </svg>
            </div>
            <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.85)', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
              IA Focux · Sugestão ao vivo
            </div>
          </div>

          <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, lineHeight: 1.35, letterSpacing: '-0.01em', marginBottom: 12 }}>
            Beatriz subiu a carga 5kg em 2 semanas. Nos últimos 3 treinos o RPE caiu de 8 → 7. Sugiro <span style={{ color: '#BBD0FF' }}>+2.5kg na próxima série</span> pra manter estímulo.
          </div>

          {/* mini evidence graph */}
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 44, marginBottom: 14 }}>
            {[{rpe:8, h:36},{rpe:8, h:36},{rpe:7.5, h:32},{rpe:7, h:28},{rpe:7, h:28}].map((d,i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{ width: '100%', height: d.h, background: 'rgba(255,255,255,0.35)',
                  borderRadius: 4, border: i === 4 ? '1.5px solid #fff' : 'none',
                }}/>
                <div style={{ ...FxMono, fontSize: 9, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>{d.rpe}</div>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', gap: 8 }}>
            <button style={{ flex: 1, padding: '12px', borderRadius: 12, border: 'none',
              background: '#fff', color: FX.brand,
              ...FxText, fontSize: 13, fontWeight: 700, cursor: 'pointer',
            }}>
              Aplicar sugestão
            </button>
            <button style={{ padding: '12px 16px', borderRadius: 12,
              background: 'rgba(255,255,255,0.12)', color: '#fff', border: '1px solid rgba(255,255,255,0.25)',
              ...FxText, fontSize: 13, fontWeight: 600, cursor: 'pointer',
            }}>
              Ignorar
            </button>
          </div>
        </div>
      </div>

      {/* Aluno card — who's doing it */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{ background: cardBg, borderRadius: 20, padding: '14px 16px', border: `1px solid ${line}`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <FxAvatar name="Beatriz Carvalho" size={44} color={FX.brand} />
          <div style={{ flex: 1 }}>
            <div style={{ ...FxText, fontSize: 10, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Aluna</div>
            <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink, marginTop: 1 }}>Beatriz Carvalho</div>
            <div style={{ ...FxText, fontSize: 12, color: mute, marginTop: 1 }}>Aderência 92% · streak 12 dias 🔥</div>
          </div>
          <button style={{ width: 40, height: 40, borderRadius: 12,
            background: dark ? 'rgba(255,255,255,0.06)' : FX.paperSoft, border: `1px solid ${line}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" stroke={ink} strokeWidth="1.8" strokeLinejoin="round"/></svg>
          </button>
        </div>
      </div>

      {/* Rest timer active — sticky above dock */}
      <div style={{
        position: 'absolute', left: 16, right: 16, bottom: 100,
        background: dark ? 'rgba(18,28,56,0.92)' : 'rgba(20,26,44,0.92)',
        backdropFilter: 'blur(20px)',
        borderRadius: 20, padding: '14px 18px',
        display: 'flex', alignItems: 'center', gap: 14,
        color: '#fff',
        boxShadow: '0 12px 40px rgba(0,0,0,0.25)',
      }}>
        <div style={{ width: 44, height: 44, borderRadius: 44, background: 'rgba(255,255,255,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
        }}>
          <svg width="44" height="44" viewBox="0 0 44 44" fill="none" style={{ position: 'absolute', inset: 0, transform: 'rotate(-90deg)' }}>
            <circle cx="22" cy="22" r="19" stroke="rgba(255,255,255,0.2)" strokeWidth="2"/>
            <circle cx="22" cy="22" r="19" stroke="#7AD19B" strokeWidth="2.5"
              strokeDasharray={`${0.6 * 119.4} ${119.4}`} strokeLinecap="round"/>
          </svg>
          <div style={{ ...FxMono, fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>0:36</div>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.7)', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>Descanso</div>
          <div style={{ ...FxDisplay, fontSize: 14, fontWeight: 600 }}>Próxima: série 4 · 70kg</div>
        </div>
        <button style={{ padding: '8px 14px', borderRadius: 10,
          background: '#fff', color: FX.ink, border: 'none',
          ...FxText, fontSize: 12, fontWeight: 700, cursor: 'pointer',
        }}>Pular</button>
      </div>
    </div>
  );
}

window.FxCheckinIA = FxCheckinIA;

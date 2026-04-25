// Perfil do Personal — identidade, plano, estatísticas, configurações

function FxPerfil({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const p = FxData.personal;

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>

      {/* HERO — gradient cover com avatar grande */}
      <div style={{ position: 'relative',
        background: dark
          ? `linear-gradient(160deg, #1C3273 0%, #060D28 100%)`
          : `linear-gradient(160deg, ${FX.brand} 0%, ${FX.brandDeep} 100%)`,
        paddingTop: 54, paddingBottom: 0,
      }}>
        {/* grid texture */}
        <svg style={{ position: 'absolute', inset: 0, opacity: 0.06 }} width="100%" height="100%">
          <defs><pattern id="gg-pf" width="26" height="26" patternUnits="userSpaceOnUse">
            <path d="M 26 0 L 0 0 0 26" fill="none" stroke="#fff" strokeWidth="0.5"/>
          </pattern></defs>
          <rect width="100%" height="100%" fill="url(#gg-pf)" />
        </svg>

        {/* top actions */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 18px 0', position: 'relative' }}>
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.14)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="10" height="16" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <FxLockup size={12} color="#fff" markColor="#fff" subtitle variant={window.FX_LOGO_VARIANT || 'official'} onDark />
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.14)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <FxIcon name="more" size={17} color="#fff" stroke={2} />
          </div>
        </div>

        {/* avatar + name block */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '22px 0 0', position: 'relative' }}>
          <div style={{ position: 'relative', marginBottom: 14 }}>
            <div style={{ width: 88, height: 88, borderRadius: 88, background: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              ...FxDisplay, fontSize: 32, fontWeight: 700, color: FX.brand,
              boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
            }}>MR</div>
            {/* edit badge */}
            <div style={{ position: 'absolute', bottom: 2, right: 2, width: 26, height: 26,
              borderRadius: 26, background: '#fff', border: `2px solid ${dark ? '#1C3273' : FX.brand}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="11" height="11" viewBox="0 0 14 14" fill="none">
                <path d="M9.5 1.5L12.5 4.5L5 12H2V9L9.5 1.5Z" stroke={FX.brand} strokeWidth="1.5" strokeLinejoin="round"/>
              </svg>
            </div>
          </div>
          <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: '#fff', letterSpacing: '-0.025em' }}>
            {p.nome}
          </div>
          <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.7)', marginTop: 3 }}>
            Personal Trainer · São Paulo, SP
          </div>

          {/* plano badge */}
          <div style={{ marginTop: 10, marginBottom: 22, display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 14px', borderRadius: 999,
            background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(8px)',
          }}>
            <svg width="12" height="12" viewBox="0 0 14 14" fill="none">
              <path d="M7 1l1.5 3.5L12 5l-2.5 2.4.6 3.4L7 9.3l-3.1 1.5.6-3.4L2 5l3.5-.5L7 1z" fill="#FFD37A"/>
            </svg>
            <div style={{ ...FxText, fontSize: 12, fontWeight: 700, color: '#FFD37A', letterSpacing: '0.06em' }}>
              PLANO PRO
            </div>
          </div>
        </div>

        {/* stat strip */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
          background: 'rgba(0,0,0,0.18)', backdropFilter: 'blur(12px)',
          borderTop: '1px solid rgba(255,255,255,0.12)', position: 'relative',
        }}>
          {[
            { label: 'Alunos', value: '24' },
            { label: 'Treinos', value: '312' },
            { label: 'Meses ativo', value: '8' },
            { label: 'Avaliação', value: '4.9' },
          ].map((s, i) => (
            <div key={s.label} style={{
              padding: '14px 10px', textAlign: 'center',
              borderRight: i < 3 ? '1px solid rgba(255,255,255,0.1)' : 'none',
            }}>
              <div style={{ ...FxDisplay, fontSize: 22, fontWeight: 600, color: '#fff', letterSpacing: '-0.02em' }}>{s.value}</div>
              <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.6)', fontWeight: 500, marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Identidade visual — cor da marca */}
      <div style={{ padding: '20px 16px 0' }}>
        <div style={{ background: cardBg, borderRadius: 20, overflow: 'hidden', border: `1px solid ${line}` }}>
          <div style={{ padding: '14px 16px 10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink }}>Identidade visual</div>
            <div style={{ ...FxText, fontSize: 12, color: brand, fontWeight: 600 }}>Editar →</div>
          </div>
          <div style={{ padding: '0 16px 14px', display: 'flex', gap: 10 }}>
            {['#3B5FE2','#0D1B5C','#7CC0FF','#FFFFFF','#0B1220'].map(c => (
              <div key={c} style={{ width: 36, height: 36, borderRadius: 12,
                background: c, border: `1.5px solid ${c === '#FFFFFF' ? line : 'transparent'}`,
                boxShadow: '0 2px 6px rgba(0,0,0,0.1)',
              }}/>
            ))}
            <div style={{ width: 36, height: 36, borderRadius: 12,
              border: `1.5px dashed ${line}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <FxIcon name="plus" size={14} color={mute} stroke={2} />
            </div>
          </div>
        </div>
      </div>

      {/* Informações */}
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{ background: cardBg, borderRadius: 20, overflow: 'hidden', border: `1px solid ${line}` }}>
          <div style={{ padding: '14px 16px 4px' }}>
            <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink }}>Informações</div>
          </div>
          {[
            { icon: 'calendar', label: 'Membro desde', value: 'ago 2024' },
            { icon: 'users',    label: 'Limite do plano', value: '24 / 40 alunos' },
            { icon: 'trend',    label: 'Especialidade', value: 'Hipertrofia · Funcional' },
            { icon: 'chat',     label: 'WhatsApp', value: '(11) 99999-0000' },
          ].map((r, i, arr) => (
            <div key={r.label} style={{ display: 'flex', alignItems: 'center', padding: '13px 16px',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${line}` : 'none',
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10,
                background: dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <FxIcon name={r.icon} size={15} color={brand} stroke={1.8} />
              </div>
              <div style={{ flex: 1, marginLeft: 12 }}>
                <div style={{ ...FxText, fontSize: 11.5, color: mute, fontWeight: 500 }}>{r.label}</div>
                <div style={{ ...FxText, fontSize: 14, color: ink, fontWeight: 500, marginTop: 1 }}>{r.value}</div>
              </div>
              <FxIcon name="chev" size={14} color={mute} stroke={2} />
            </div>
          ))}
        </div>
      </div>

      {/* Configurações */}
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{ background: cardBg, borderRadius: 20, overflow: 'hidden', border: `1px solid ${line}` }}>
          <div style={{ padding: '14px 16px 4px' }}>
            <div style={{ ...FxDisplay, fontSize: 15, fontWeight: 600, color: ink }}>Conta & plano</div>
          </div>
          {[
            { icon: 'spark', label: 'Copiloto IA', value: 'PRO · ativo', accent: true },
            { icon: 'coin',  label: 'Planos e assinatura', value: 'Gerenciar' },
            { icon: 'bell',  label: 'Notificações', value: 'Todas ativadas' },
            { icon: 'warn',  label: 'Sair da conta', value: '', danger: true },
          ].map((r, i, arr) => (
            <div key={r.label} style={{ display: 'flex', alignItems: 'center', padding: '13px 16px',
              borderBottom: i < arr.length - 1 ? `0.5px solid ${line}` : 'none',
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10,
                background: r.danger ? (dark ? 'rgba(255,139,139,0.12)' : FX.badSoft)
                  : r.accent ? (dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft)
                  : (dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft),
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <FxIcon name={r.icon} size={15}
                  color={r.danger ? (dark ? '#FF8B8B' : FX.bad) : r.accent ? brand : mute}
                  stroke={1.8} />
              </div>
              <div style={{ flex: 1, marginLeft: 12,
                ...FxText, fontSize: 14, fontWeight: 500,
                color: r.danger ? (dark ? '#FF8B8B' : FX.bad) : ink,
              }}>{r.label}</div>
              {r.value && (
                <div style={{ ...FxText, fontSize: 12, color: r.accent ? brand : mute, fontWeight: r.accent ? 600 : 400 }}>{r.value}</div>
              )}
              {!r.danger && <FxIcon name="chev" size={14} color={mute} stroke={2} />}
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}

window.FxPerfil = FxPerfil;

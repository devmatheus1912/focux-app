// Onboarding — fluxo de boas-vindas pra novo personal trainer
// Mostrando o step 3 de 5: "Convide seu primeiro aluno"

function FxOnboarding({ dark = false }) {
  const bg = dark ? FX.darkBg : '#fff';
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;
  const brandSoft = dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft;

  const steps = [
    { n:1, label:'Perfil', done:true },
    { n:2, label:'Plano', done:true },
    { n:3, label:'Aluno', done:false, current:true },
    { n:4, label:'Treino', done:false },
    { n:5, label:'IA', done:false },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', display: 'flex', flexDirection: 'column', paddingBottom: 40 }}>
      {/* status bar spacer */}
      <div style={{ height: 56 }} />

      {/* Step indicator */}
      <div style={{ padding: '0 28px 0', marginBottom: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
          {steps.map((s, i) => (
            <React.Fragment key={s.n}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ width: 32, height: 32, borderRadius: 32,
                  background: s.done ? brand : s.current ? (dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft) : (dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft),
                  border: s.current ? `2px solid ${brand}` : 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {s.done
                    ? <svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5l3 4L11 1" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    : <div style={{ ...FxMono, fontSize: 11, fontWeight: 700, color: s.current ? brand : mute }}>{s.n}</div>
                  }
                </div>
                <div style={{ ...FxText, fontSize: 9.5, fontWeight: s.current ? 700 : 500,
                  color: s.current ? brand : (s.done ? ink : mute), letterSpacing: '0.02em',
                }}>{s.label}</div>
              </div>
              {i < steps.length - 1 && (
                <div style={{ flex: 1, height: 2, borderRadius: 2, marginBottom: 16,
                  background: s.done ? brand : (dark ? 'rgba(255,255,255,0.08)' : FX.lineSoft),
                }}/>
              )}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* Hero illustration area */}
      <div style={{ padding: '0 24px', marginBottom: 28 }}>
        <div style={{
          borderRadius: 32, overflow: 'hidden', position: 'relative',
          background: dark ? `linear-gradient(150deg, #1A2852 0%, #0A0F1E 100%)` : `linear-gradient(150deg, ${FX.brand} 0%, ${FX.brandDeep} 100%)`,
          padding: '32px 28px 28px',
          boxShadow: '0 20px 48px -20px rgba(59,95,226,0.38)',
        }}>
          <svg style={{ position: 'absolute', inset: 0, opacity: 0.07 }} width="100%" height="100%">
            <defs><pattern id="gg-ob" width="28" height="28" patternUnits="userSpaceOnUse">
              <path d="M 28 0 L 0 0 0 28" fill="none" stroke="#fff" strokeWidth="0.5"/>
            </pattern></defs>
            <rect width="100%" height="100%" fill="url(#gg-ob)" />
          </svg>

          {/* icon illustration */}
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 20, position: 'relative' }}>
            <div style={{ width: 96, height: 96, borderRadius: 96, background: 'rgba(255,255,255,0.12)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              backdropFilter: 'blur(8px)', position: 'relative',
            }}>
              {/* two avatars overlapping */}
              <div style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
                width: 48, height: 48, borderRadius: 48, background: 'rgba(255,255,255,0.9)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                ...FxDisplay, fontSize: 18, fontWeight: 700, color: FX.brand,
              }}>M</div>
              <div style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)',
                width: 48, height: 48, borderRadius: 48, background: FX.brandAccent,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                ...FxDisplay, fontSize: 18, fontWeight: 700, color: '#fff',
              }}>B</div>
              {/* connection line */}
              <div style={{ width: 28, height: 2, background: 'rgba(255,255,255,0.4)' }}/>
            </div>
          </div>

          <div style={{ color: '#fff', textAlign: 'center', position: 'relative' }}>
            <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.7)', fontWeight: 600,
              letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 8 }}>passo 3 de 5</div>
            <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 600, letterSpacing: '-0.025em', marginBottom: 8, lineHeight: 1.15 }}>
              Convide seu primeiro aluno
            </div>
            <div style={{ ...FxText, fontSize: 14, color: 'rgba(255,255,255,0.75)', lineHeight: 1.5 }}>
              Gere um link de convite e peça ao aluno pra baixar o app. Ele vai criar a conta e já aparece na sua lista.
            </div>
          </div>
        </div>
      </div>

      {/* Input — gerar convite */}
      <div style={{ padding: '0 24px', marginBottom: 16 }}>
        <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: ink, marginBottom: 8 }}>
          Gerar link de convite
        </div>
        <div style={{ background: dark ? FX.darkCard : FX.paper, borderRadius: 14,
          border: `1px solid ${line}`, padding: '13px 16px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <FxIcon name="users" size={16} color={mute} stroke={1.8} />
          <div style={{ ...FxText, fontSize: 14, color: mute, flex: 1 }}>Nome do aluno (opcional)</div>
        </div>
      </div>

      <div style={{ padding: '0 24px', marginBottom: 14 }}>
        <div style={{ height: 52, borderRadius: 14, background: brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          color: '#fff', ...FxText, fontSize: 15, fontWeight: 700,
          boxShadow: `0 6px 20px -8px rgba(59,95,226,0.5)`,
        }}>
          <FxIcon name="send" size={16} color="#fff" stroke={2} />
          Gerar link de convite
        </div>
      </div>

      {/* Or share directly */}
      <div style={{ padding: '0 24px', display: 'flex', gap: 10 }}>
        {[
          { label: 'WhatsApp', color: '#25D366' },
          { label: 'Email', color: FX.brand },
          { label: 'Copiar link', color: FX.inkMute },
        ].map(s => (
          <div key={s.label} style={{ flex: 1, height: 44, borderRadius: 12,
            background: dark ? 'rgba(255,255,255,0.06)' : FX.paper,
            border: `1px solid ${line}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            ...FxText, fontSize: 12, fontWeight: 600, color: s.color,
          }}>{s.label}</div>
        ))}
      </div>

      {/* Skip */}
      <div style={{ flex: 1 }} />
      <div style={{ padding: '20px 24px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ ...FxText, fontSize: 13, color: mute, fontWeight: 500 }}>Pular por agora</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, ...FxText, fontSize: 13, fontWeight: 700, color: brand }}>
          Próximo
          <FxIcon name="chev" size={14} color={brand} stroke={2.5} />
        </div>
      </div>
    </div>
  );
}

window.FxOnboarding = FxOnboarding;

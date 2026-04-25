// Business/Growth screens:
// - FxPaywall (planos FREE | PREMIUM | ENTERPRISE)
// - FxLandingPublic (página pública white-label do personal)
// - FxLinkNaBioConfig (growth: configurar landing page)
// - FxMigracaoMagica (IA import from other apps)
// - FxLeadsCRM (kanban de leads)

// ─────────────────────────────────────────────────────
// PAYWALL — Planos
// ─────────────────────────────────────────────────────
function FxPaywall({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;
  const [selected, setSelected] = React.useState(1); // 0=FREE, 1=PREMIUM, 2=ENTERPRISE

  const planos = [
    {
      id: 0, nome: 'FREE', preco: null, trial: null,
      cor: mute, corBg: dark ? 'rgba(255,255,255,0.04)' : FX.lineSoft,
      tag: null,
      sub: 'Para começar',
      features: [
        { ok: true,  label: 'Até 3 alunos ativos' },
        { ok: true,  label: 'Treinos básicos' },
        { ok: false, label: 'Financeiro' },
        { ok: false, label: 'IA Copiloto' },
        { ok: false, label: 'Landing Page' },
        { ok: false, label: 'Migração Mágica' },
      ],
    },
    {
      id: 1, nome: 'PREMIUM', preco: 79, trial: 5,
      cor: brand, corBg: dark ? 'rgba(141,164,226,0.1)' : FX.brandSoft,
      tag: 'MAIS POPULAR',
      sub: 'Para consultores sérios',
      features: [
        { ok: true, label: 'Até 20 alunos ativos' },
        { ok: true, label: 'Financeiro & cobranças' },
        { ok: true, label: 'CRM Kanban de Leads' },
        { ok: true, label: 'Migração Mágica IA' },
        { ok: false, label: 'Landing Page (white-label)' },
        { ok: false, label: 'IA ilimitada' },
      ],
    },
    {
      id: 2, nome: 'ENTERPRISE', preco: 149, trial: 5,
      cor: '#C49A2A', corBg: dark ? 'rgba(196,154,42,0.12)' : '#FFF9E8',
      tag: 'ESCALA TOTAL',
      sub: 'Para quem quer crescer',
      features: [
        { ok: true, label: 'Alunos ilimitados' },
        { ok: true, label: 'IA Copiloto completa' },
        { ok: true, label: 'Landing Page white-label' },
        { ok: true, label: 'Motor anti-churn & prova social' },
        { ok: true, label: 'Analytics avançado' },
        { ok: true, label: 'Suporte prioritário' },
      ],
    },
  ];

  const pl = planos[selected];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 120 }}>
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{ padding: '10px 22px 20px' }}>
        <div style={{ ...FxText, fontSize: 11, color: brand, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 6 }}>
          Evolua seu plano
        </div>
        <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em', lineHeight: 1.15, marginBottom: 8 }}>
          Escolha o plano{'\n'}ideal para você
        </div>
        <div style={{ ...FxText, fontSize: 14, color: mute, lineHeight: 1.5 }}>
          5 dias grátis · Cancele quando quiser
        </div>
      </div>

      {/* Plan selector tabs */}
      <div style={{ padding: '0 16px 20px', display: 'flex', gap: 8 }}>
        {planos.map((p) => (
          <button key={p.id} onClick={() => setSelected(p.id)} style={{
            flex: 1, padding: '10px 4px', borderRadius: 14, border: 'none', cursor: 'pointer',
            background: selected === p.id ? p.cor : (dark ? 'rgba(255,255,255,0.05)' : '#fff'),
            boxShadow: selected === p.id ? `0 4px 12px ${p.cor}44` : `inset 0 0 0 1px ${line}`,
            transition: 'all 180ms ease',
          }}>
            <div style={{ ...FxDisplay, fontSize: 12, fontWeight: 700,
              color: selected === p.id ? '#fff' : ink, letterSpacing: '0.04em' }}>{p.nome}</div>
            <div style={{ ...FxText, fontSize: 11,
              color: selected === p.id ? 'rgba(255,255,255,0.75)' : mute, marginTop: 2,
            }}>{p.preco ? `R$ ${p.preco}` : 'Grátis'}</div>
          </button>
        ))}
      </div>

      {/* Main plan card */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{
          borderRadius: 28, overflow: 'hidden',
          border: `2px solid ${pl.cor}`,
          boxShadow: `0 10px 40px -16px ${pl.cor}55`,
        }}>
          {/* card hero */}
          <div style={{
            background: pl.id === 0
              ? (dark ? FX.darkCard : '#f8f8f6')
              : `linear-gradient(135deg, ${pl.cor}EE 0%, ${pl.id === 1 ? FX.brandDeep : '#3A2600'} 100%)`,
            padding: '22px 22px 20px', position: 'relative', overflow: 'hidden',
          }}>
            {pl.id > 0 && (
              <svg style={{ position: 'absolute', right: -20, top: -20, opacity: 0.08 }} width="160" height="160" viewBox="0 0 40 40">
                <rect x="1" y="1" width="38" height="38" rx="11" fill="#fff"/>
                <path d="M10 9 L14 9 L31 30 L27 31 Z" fill="#000"/>
                <path d="M30 9 L26 9 L9 30 L13 31 Z" fill="#000" opacity="0.6"/>
              </svg>
            )}
            {pl.tag && (
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '4px 10px', borderRadius: 999,
                background: 'rgba(255,255,255,0.2)', marginBottom: 12,
                ...FxText, fontSize: 10, fontWeight: 700, color: '#fff', letterSpacing: '0.1em',
              }}>
                <svg width="9" height="9" viewBox="0 0 12 12" fill="none">
                  <path d="M6 1l1.2 2.9L11 4l-2.4 2.3.6 3.2L6 8l-3.2 1.5.6-3.2L1 4l3.8-.1L6 1z" fill="#fff"/>
                </svg>
                {pl.tag}
              </div>
            )}
            <div style={{ ...FxDisplay, fontSize: 22, fontWeight: 700, color: pl.id > 0 ? '#fff' : ink, letterSpacing: '-0.02em' }}>
              Plano {pl.nome}
            </div>
            <div style={{ ...FxText, fontSize: 13, color: pl.id > 0 ? 'rgba(255,255,255,0.7)' : mute, marginTop: 3 }}>{pl.sub}</div>
            {pl.preco && (
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 16 }}>
                <div style={{ ...FxDisplay, fontSize: 44, fontWeight: 700, color: '#fff', letterSpacing: '-0.03em', lineHeight: 1 }}>
                  R$ {pl.preco}
                </div>
                <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.6)' }}>/mês</div>
              </div>
            )}
            {pl.trial && (
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 10, padding: '5px 10px', borderRadius: 999,
                background: 'rgba(255,255,255,0.15)',
                ...FxText, fontSize: 12, color: '#fff', fontWeight: 600,
              }}>
                <svg width="11" height="11" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="#fff" strokeWidth="1.5"/><path d="M7 4v3l2 1.5" stroke="#fff" strokeWidth="1.5" strokeLinecap="round"/></svg>
                {pl.trial} dias grátis para começar
              </div>
            )}
          </div>

          {/* features list */}
          <div style={{ background: cardBg, padding: '18px 20px' }}>
            {pl.features.map((f, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 0',
                borderBottom: i < pl.features.length - 1 ? `0.5px solid ${line}` : 'none',
              }}>
                <div style={{ width: 24, height: 24, borderRadius: 24,
                  background: f.ok ? (dark ? 'rgba(111,226,150,0.15)' : FX.goodSoft) : (dark ? 'rgba(255,255,255,0.04)' : FX.lineSoft),
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>
                  {f.ok
                    ? <svg width="11" height="9" viewBox="0 0 12 10" fill="none"><path d="M1 5l3 4L11 1" stroke={dark ? '#6FE296' : FX.good} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    : <svg width="10" height="10" viewBox="0 0 12 12" fill="none"><path d="M2 2l8 8M10 2L2 10" stroke={mute} strokeWidth="1.8" strokeLinecap="round"/></svg>
                  }
                </div>
                <div style={{ ...FxText, fontSize: 13.5, color: f.ok ? ink : mute, fontWeight: f.ok ? 500 : 400 }}>{f.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {pl.id === 0 ? (
          <div style={{ height: 52, borderRadius: 14, background: dark ? 'rgba(255,255,255,0.08)' : FX.lineSoft,
            border: `1px solid ${line}`, display: 'flex', alignItems: 'center', justifyContent: 'center',
            ...FxText, fontSize: 14, fontWeight: 600, color: mute,
          }}>Plano atual · Grátis</div>
        ) : (
          <div style={{ height: 52, borderRadius: 14, cursor: 'pointer',
            background: pl.id === 2 ? `linear-gradient(135deg, #C49A2A, #7A5C0A)` : `linear-gradient(135deg, ${FX.brand}, ${FX.brandInk})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            color: '#fff', ...FxText, fontSize: 15, fontWeight: 700,
            boxShadow: pl.id === 2 ? '0 6px 20px rgba(196,154,42,0.4)' : `0 6px 20px rgba(59,95,226,0.4)`,
          }}>
            <FxIcon name="spark" size={17} color="#fff" stroke={1.8} />
            Começar {pl.trial} dias grátis
          </div>
        )}
        {pl.id > 0 && (
          <div style={{ textAlign: 'center', ...FxText, fontSize: 12, color: mute }}>
            Após o período, cobrado R$ {pl.preco}/mês · Cancele a qualquer momento
          </div>
        )}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// LANDING PAGE PÚBLICA — white-label do personal
// ─────────────────────────────────────────────────────
function FxLandingPublic({ dark = false }) {
  const brand = '#3B5FE2'; // personal's brand color (could be custom)

  const personal = {
    nome: 'Matheus Ribeiro',
    titulo: 'Personal Trainer Especialista em Hipertrofia',
    slug: 'matheus-personal',
    foto: null,
    alunos: 47,
    anos: 6,
    avaliacoes: 4.9,
    bio: 'Transformo corpos e vidas há 6 anos. Metodologia baseada em dados reais, com IA que acompanha sua evolução semana a semana.',
    especialidades: ['Hipertrofia', 'Emagrecimento', 'Funcional', 'Reabilitação'],
    depoimentos: [
      { nome: 'Beatriz C.', texto: 'Perdi 12kg em 4 meses e virei outra pessoa. O app dele é incrível!', nota: 5 },
      { nome: 'Lucas A.',   texto: 'Bati meu PR de supino após 3 meses. Metodologia diferenciada.', nota: 5 },
    ],
  };

  return (
    <div style={{ background: '#0A0F1E', minHeight: '100%', paddingBottom: 80, color: '#fff' }}>
      {/* HERO */}
      <div style={{ position: 'relative', overflow: 'hidden',
        background: `linear-gradient(160deg, #162D6B 0%, #0A0F1E 70%)`,
        padding: '54px 22px 32px',
      }}>
        <svg style={{ position: 'absolute', inset: 0, opacity: 0.06 }} width="100%" height="100%">
          <defs><pattern id="gg-lp" width="28" height="28" patternUnits="userSpaceOnUse">
            <path d="M 28 0 L 0 0 0 28" fill="none" stroke="#fff" strokeWidth="0.5"/>
          </pattern></defs>
          <rect width="100%" height="100%" fill="url(#gg-lp)" />
        </svg>
        <div style={{ position: 'absolute', top: -50, right: -50, width: 220, height: 220,
          borderRadius: 220, background: `radial-gradient(circle, ${brand}33 0%, transparent 70%)`,
        }}/>

        {/* Avatar */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, position: 'relative', marginBottom: 24 }}>
          <div style={{ width: 90, height: 90, borderRadius: 90, background: brand,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            ...FxDisplay, fontSize: 32, fontWeight: 700, color: '#fff',
            boxShadow: `0 8px 28px ${brand}66`,
          }}>MR</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, letterSpacing: '-0.02em' }}>{personal.nome}</div>
            <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.65)', marginTop: 4, lineHeight: 1.4 }}>{personal.titulo}</div>
          </div>
        </div>

        {/* Stats */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 24 }}>
          {[
            { label: 'Alunos', v: personal.alunos + '+' },
            { label: 'Anos', v: personal.anos },
            { label: 'Avaliação', v: personal.avaliacoes },
          ].map((s, i, arr) => (
            <React.Fragment key={s.label}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 700 }}>{s.v}</div>
                <div style={{ ...FxText, fontSize: 11, color: 'rgba(255,255,255,0.55)', marginTop: 2 }}>{s.label}</div>
              </div>
              {i < arr.length - 1 && <div style={{ width: 1, background: 'rgba(255,255,255,0.15)' }}/>}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* Bio */}
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{ ...FxText, fontSize: 14.5, color: 'rgba(255,255,255,0.75)', lineHeight: 1.65 }}>{personal.bio}</div>
      </div>

      {/* Especialidades */}
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, marginBottom: 12 }}>Especialidades</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {personal.especialidades.map(e => (
            <div key={e} style={{ padding: '8px 14px', borderRadius: 999,
              background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.12)',
              ...FxText, fontSize: 13, fontWeight: 500, color: 'rgba(255,255,255,0.85)',
            }}>{e}</div>
          ))}
        </div>
      </div>

      {/* Depoimentos */}
      <div style={{ padding: '24px 22px 0' }}>
        <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, marginBottom: 14 }}>O que dizem meus alunos</div>
        {personal.depoimentos.map((d, i) => (
          <div key={i} style={{ marginBottom: 12, padding: 16, borderRadius: 18,
            background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)',
          }}>
            <div style={{ display: 'flex', gap: 2, marginBottom: 8 }}>
              {[...Array(d.nota)].map((_, j) => <div key={j} style={{ color: '#FFD37A', fontSize: 14 }}>★</div>)}
            </div>
            <div style={{ ...FxText, fontSize: 14, color: 'rgba(255,255,255,0.8)', lineHeight: 1.5, marginBottom: 8 }}>"{d.texto}"</div>
            <div style={{ ...FxText, fontSize: 12, color: 'rgba(255,255,255,0.45)', fontWeight: 600 }}>— {d.nome}</div>
          </div>
        ))}
      </div>

      {/* CTA */}
      <div style={{ padding: '28px 22px 0' }}>
        <div style={{ padding: '22px 20px', borderRadius: 24,
          background: `linear-gradient(135deg, ${brand}CC 0%, #0D1B5C 100%)`,
          textAlign: 'center',
          border: '1px solid rgba(255,255,255,0.1)',
        }}>
          <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 700, marginBottom: 8, lineHeight: 1.2 }}>
            Pronto para transformar seu corpo?
          </div>
          <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.7)', marginBottom: 18 }}>
            Entre em contato e comece hoje
          </div>
          <div style={{ height: 50, borderRadius: 14, background: '#fff', color: brand,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            ...FxText, fontSize: 14, fontWeight: 700,
          }}>
            <FxIcon name="chat" size={16} color={brand} stroke={2} />
            Falar no WhatsApp
          </div>
        </div>
      </div>

      {/* Powered by Focux footer */}
      <div style={{ textAlign: 'center', padding: '24px 22px 0', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
        <FxMark size={20} variant="official" onDark />
        <div style={{ ...FxText, fontSize: 11, color: 'rgba(255,255,255,0.25)', fontWeight: 500 }}>Criado com <span style={{ color: 'rgba(255,255,255,0.45)', fontWeight: 700 }}>Focux Personal</span></div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// LINK NA BIO CONFIG — PREMIUM feature
// ─────────────────────────────────────────────────────
function FxLinkNaBioConfig({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      <div style={{ padding: '10px 20px 20px' }}>
        <div style={{ ...FxText, fontSize: 11, color: brand, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 6 }}>ENTERPRISE</div>
        <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Seu link na bio 🚀</div>
        <div style={{ ...FxText, fontSize: 14, color: mute, marginTop: 6, lineHeight: 1.55 }}>
          Sua landing page personalizada. Coloque no Instagram e converta visitantes em alunos.
        </div>
      </div>

      {/* Live link card */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{ background: dark ? 'rgba(141,164,226,0.08)' : FX.brandSofter, borderRadius: 22,
          padding: '18px 18px', border: `1.5px solid ${dark ? 'rgba(141,164,226,0.2)' : 'rgba(59,95,226,0.2)'}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
            <div style={{ width: 36, height: 36, borderRadius: 11,
              background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FxIcon name="trend" size={17} color={brand} stroke={1.8} />
            </div>
            <div>
              <div style={{ ...FxText, fontSize: 10, color: '#2BB673', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em' }}>● ATIVA</div>
              <div style={{ ...FxText, fontSize: 14, fontWeight: 700, color: ink }}>Sua Landing Page está no ar!</div>
            </div>
          </div>
          {/* link row */}
          <div style={{ background: cardBg, borderRadius: 12, padding: '12px 14px',
            display: 'flex', alignItems: 'center', gap: 10, border: `1px solid ${line}`,
          }}>
            <div style={{ ...FxMono, fontSize: 12, color: brand, flex: 1 }}>focux.app/p/matheus-personal</div>
            <div style={{ padding: '5px 10px', borderRadius: 8, background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
              ...FxText, fontSize: 11, fontWeight: 700, color: brand, display: 'flex', alignItems: 'center', gap: 4,
            }}>
              <FxIcon name="send" size={11} color={brand} stroke={2} /> Copiar
            </div>
          </div>
          {/* stats */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginTop: 12 }}>
            {[{ label: 'Visitas', v: '284' }, { label: 'Cliques', v: '47' }, { label: 'Conversão', v: '16,5%' }].map(s => (
              <div key={s.label} style={{ background: cardBg, borderRadius: 12, padding: '10px', textAlign: 'center', border: `1px solid ${line}` }}>
                <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 700, color: ink }}>{s.v}</div>
                <div style={{ ...FxText, fontSize: 10.5, color: mute, marginTop: 2 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Configurações */}
      <div style={{ padding: '0 20px 12px', ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>Configurações</div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { icon: 'coin',    label: 'Link de pagamento', value: 'MercadoPago conectado', badge: null },
          { icon: 'users',   label: 'Depoimentos', value: '3 em destaque', badge: null },
          { icon: 'trend',   label: 'Prova social',  value: 'Ativada', badge: '● LIVE' },
          { icon: 'spark',   label: 'Cor da marca',  value: '#3B5FE2 · Azul royal', badge: null },
          { icon: 'calendar',label: 'Formulário de contato', value: 'WhatsApp direto', badge: null },
        ].map((r) => (
          <div key={r.label} style={{ background: cardBg, borderRadius: 16, padding: '13px 14px',
            border: `1px solid ${line}`, display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 34, height: 34, borderRadius: 10,
              background: dark ? 'rgba(141,164,226,0.12)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <FxIcon name={r.icon} size={16} color={brand} stroke={1.8} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ ...FxText, fontSize: 13.5, fontWeight: 600, color: ink }}>{r.label}</div>
              <div style={{ ...FxText, fontSize: 11.5, color: mute, marginTop: 1 }}>{r.value}</div>
            </div>
            {r.badge && (
              <div style={{ ...FxText, fontSize: 10, fontWeight: 700, color: '#2BB673' }}>{r.badge}</div>
            )}
            <FxIcon name="chev" size={14} color={mute} stroke={2} />
          </div>
        ))}
      </div>

      <div style={{ padding: '20px 16px 0' }}>
        <div style={{ height: 50, borderRadius: 14, background: brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          color: '#fff', ...FxText, fontSize: 14, fontWeight: 700,
          boxShadow: `0 6px 20px rgba(59,95,226,0.35)`,
        }}>
          <FxIcon name="send" size={16} color="#fff" stroke={2} />
          Compartilhar landing page
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// MIGRAÇÃO MÁGICA IA
// ─────────────────────────────────────────────────────
function FxMigracaoMagica({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const alunos = [
    { nome: 'Beatriz Carvalho', email: 'bia@gmail.com', tel: '(11)99999-1111', obj: 'Hipertrofia' },
    { nome: 'Lucas Andrade',    email: 'lucas@gmail.com', tel: '(11)98888-2222', obj: 'Emagrecimento' },
    { nome: 'Camila Prado',     email: 'camila@gmail.com', tel: '(11)97777-3333', obj: 'Condicionamento' },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      {/* Header */}
      <div style={{ padding: '10px 20px 18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{ width: 32, height: 32, borderRadius: 10,
            background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <FxIcon name="spark" size={16} color={brand} stroke={1.8} />
          </div>
          <div style={{ ...FxText, fontSize: 12, color: brand, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase' }}>IA Focux</div>
        </div>
        <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em', lineHeight: 1.1 }}>
          Migração Mágica ✨
        </div>
        <div style={{ ...FxText, fontSize: 14, color: mute, marginTop: 6, lineHeight: 1.55 }}>
          Traga seus alunos de qualquer app. Cole o texto e a IA extrai tudo automaticamente.
        </div>
      </div>

      {/* Hero card */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{
          borderRadius: 24, overflow: 'hidden', position: 'relative',
          background: dark ? `linear-gradient(135deg, #1A2852, #0A0F1E)` : `linear-gradient(135deg, ${FX.brand}, ${FX.brandDeep})`,
          padding: '20px 20px 18px', color: '#fff',
        }}>
          <div style={{ ...FxDisplay, fontSize: 16, fontWeight: 600, marginBottom: 6 }}>
            Como funciona
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {['Cole PDF, Excel ou print de outro app', 'A IA lê e extrai nome, email, telefone e objetivo', 'Confirme e todos os alunos são salvos no Focux'].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                <div style={{ width: 22, height: 22, borderRadius: 22, background: 'rgba(255,255,255,0.2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  ...FxMono, fontSize: 11, fontWeight: 700, color: '#fff',
                }}>{i+1}</div>
                <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.82)', lineHeight: 1.4 }}>{s}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Text paste area */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{ background: cardBg, borderRadius: 20, padding: '14px', border: `1px solid ${line}` }}>
          <div style={{ ...FxText, fontSize: 12, color: mute, fontWeight: 600, textTransform: 'uppercase',
            letterSpacing: '0.06em', marginBottom: 10 }}>Dados bagunçados</div>
          <div style={{ borderRadius: 12, background: dark ? 'rgba(255,255,255,0.04)' : FX.brandSofter,
            border: `1px solid ${dark ? FX.darkLine : 'rgba(59,95,226,0.12)'}`,
            padding: '12px 14px', minHeight: 100,
            ...FxMono, fontSize: 12, color: mute, lineHeight: 1.6,
          }}>
            Beatriz Carvalho — 28 anos — (11)99999-1111 — bia@gmail.com — objetivo: hipertrofia{'\n'}
            Lucas Andrade, 34, lucas@gmail.com, emagrecimento{'\n'}
            Camila Prado | 25 | Condicionamento | (11)97777-3333
          </div>
          <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
            <div style={{ flex: 1, height: 48, borderRadius: 12, background: brand,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              color: '#fff', ...FxText, fontSize: 13, fontWeight: 700,
              boxShadow: `0 4px 14px rgba(59,95,226,0.35)`,
            }}>
              <FxIcon name="spark" size={15} color="#fff" stroke={2} />
              Iniciar migração
            </div>
          </div>
        </div>
      </div>

      {/* Results */}
      <div style={{ padding: '0 20px 12px', ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>
        {alunos.length} alunos encontrados
      </div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {alunos.map((a, i) => (
          <div key={i} style={{ background: cardBg, borderRadius: 18, padding: '13px 14px',
            border: `1px solid ${line}`, display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <FxAvatar name={a.nome} size={42} dark={dark} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ ...FxText, fontSize: 14, fontWeight: 600, color: ink }}>{a.nome}</div>
              <div style={{ ...FxText, fontSize: 11.5, color: mute, marginTop: 1 }}>{a.email} · {a.obj}</div>
            </div>
            <div style={{ width: 28, height: 28, borderRadius: 28, background: dark ? 'rgba(111,226,150,0.15)' : FX.goodSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="12" height="9" viewBox="0 0 12 10" fill="none"><path d="M1 5l3 4L11 1" stroke={dark ? '#6FE296' : FX.good} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
          </div>
        ))}
      </div>
      <div style={{ padding: '16px 16px 0' }}>
        <div style={{ height: 50, borderRadius: 14, background: dark ? '#1A3A1A' : FX.goodSoft,
          border: `1.5px solid ${dark ? '#2BB673' : FX.good}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          color: dark ? '#6FE296' : FX.good, ...FxText, fontSize: 14, fontWeight: 700,
        }}>
          <FxIcon name="check" size={16} color="currentColor" stroke={2.2} />
          Confirmar e salvar {alunos.length} alunos
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  FxPaywall, FxLandingPublic, FxLinkNaBioConfig, FxMigracaoMagica,
});

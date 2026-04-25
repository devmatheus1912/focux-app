// Dashboard — Personal Trainer home screen
// YT Music-inspired: hero card with artwork, horizontal category chips,
// card decks of "Hoje", "Atenção", "Seus alunos"

function FxDashboard({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;

  const d = FxData;

  // Animated hero: gradient angle rotates slowly + revenue counter ticks up
  const [angle, setAngle] = React.useState(135);
  const [rev, setRev] = React.useState(0);
  React.useEffect(() => {
    // gradient loop
    let a = 135;
    const ti = setInterval(() => { a = (a + 0.4) % 360; setAngle(a); }, 32);
    // counter animation: 0 → 8420 in ~1.2s
    let cur = 0; const target = 8420; const step = Math.ceil(target / 48);
    const tc = setInterval(() => {
      cur = Math.min(cur + step, target);
      setRev(cur);
      if (cur >= target) clearInterval(tc);
    }, 25);
    return () => { clearInterval(ti); clearInterval(tc); };
  }, []);

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      {/* Status bar spacer */}
      <div style={{ height: 54 }} />

      {/* Top bar — lockup + avatar */}
      <div style={{ padding: '8px 20px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <FxLockup size={16} color={ink} markColor={dark ? FX.brandAccent : FX.brand} gradient subtitle variant={window.FX_LOGO_VARIANT || 'official'} onDark={dark} />
          <div style={{ ...FxText, fontSize: 12, color: mute, marginTop: 10, fontWeight: 500 }}>
            Sex · 17 abr · <span style={{ color: ink, fontWeight: 600 }}>Bom dia, Matheus</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <div style={{ width: 36, height: 36, borderRadius: 36, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: dark ? 'rgba(255,255,255,0.05)' : '#fff', boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line, position: 'relative',
          }}>
            <FxIcon name="bell" size={17} color={ink} stroke={1.8} />
            <div style={{ position: 'absolute', top: 8, right: 9, width: 7, height: 7, borderRadius: 7, background: FX.brand, boxShadow: '0 0 0 2px ' + cardBg }} />
          </div>
          <FxAvatar name="Matheus Ribeiro" size={36} dark={dark} />
        </div>
      </div>

      {/* HERO — large brand card, YT Music artwork vibe */}
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{
          borderRadius: 28, overflow: 'hidden', position: 'relative',
          background: dark
            ? `linear-gradient(${angle}deg, #1C3273 0%, #0F1E4A 100%)`
            : `linear-gradient(${angle}deg, ${FX.brand} 0%, ${FX.brandDeep} 100%)`,
          padding: '22px 22px 20px',
          boxShadow: '0 20px 40px -20px rgba(43,74,158,0.4)',
        }}>
          {/* decorative eagle watermark */}
          <div style={{ position: 'absolute', right: -40, top: -20, opacity: 0.09 }}>
            <svg width="220" height="220" viewBox="0 0 32 32" fill="#fff">
              <path d="M16 7 L12 11 L10 10 L6 13 L9 15 L8 18 L12 18 L13 20 L16 23 L19 20 L20 18 L24 18 L23 15 L26 13 L22 10 L20 11 Z"/>
            </svg>
          </div>
          {/* subtle grid lines */}
          <svg style={{ position: 'absolute', inset: 0, opacity: 0.08 }} width="100%" height="100%">
            <defs>
              <pattern id="gg" width="32" height="32" patternUnits="userSpaceOnUse">
                <path d="M 32 0 L 0 0 0 32" fill="none" stroke="#fff" strokeWidth="0.5"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#gg)" />
          </svg>

          <div style={{ position: 'relative' }}>
            <div style={{ ...FxText, fontSize: 11, color: 'rgba(255,255,255,0.7)', letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 600 }}>Receita · abril</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
              <div style={{ ...FxDisplay, fontSize: 44, color: '#fff', fontWeight: 600, lineHeight: 1, letterSpacing: '-0.03em', fontVariantNumeric: 'tabular-nums' }}>
                R$ {rev.toLocaleString('pt-BR')}
              </div>
              <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.55)' }}>/ 11.750</div>
            </div>

            {/* progress bar */}
            <div style={{ marginTop: 14, height: 6, borderRadius: 6, background: 'rgba(255,255,255,0.15)', overflow: 'hidden' }}>
              <div style={{ width: '71%', height: '100%', background: '#fff', borderRadius: 6 }} />
            </div>

            <div style={{ display: 'flex', marginTop: 16, gap: 18 }}>
              <div>
                <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Pendente</div>
                <div style={{ ...FxDisplay, fontSize: 18, color: '#fff', fontWeight: 600, marginTop: 2 }}>R$ 3.330</div>
              </div>
              <div style={{ width: 1, background: 'rgba(255,255,255,0.15)' }} />
              <div>
                <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Inadimpl.</div>
                <div style={{ ...FxDisplay, fontSize: 18, color: '#fff', fontWeight: 600, marginTop: 2 }}>
                  2 <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', fontWeight: 400 }}>alunos</span>
                </div>
              </div>
              <div style={{ width: 1, background: 'rgba(255,255,255,0.15)' }} />
              <div>
                <div style={{ ...FxText, fontSize: 10.5, color: 'rgba(255,255,255,0.6)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>Ticket</div>
                <div style={{ ...FxDisplay, fontSize: 18, color: '#fff', fontWeight: 600, marginTop: 2 }}>R$ 349</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* quick tiles grid — 2×2 */}
      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 24 }}>
        <QuickTile dark={dark} icon="users"  label="Alunos ativos" value="24" sub="/ 40 no plano" accent={FX.brand} />
        <QuickTile dark={dark} icon="check"  label="Check-ins hoje" value="9"  sub="de 14 treinos" accent={FX.good} />
        <QuickTile dark={dark} icon="warn"   label="Risco alto" value="2" sub="precisam atenção" accent={FX.warn} />
        <QuickTile dark={dark} icon="flame"  label="Aderência média" value="78%" sub="últimos 30 dias" accent={FX.brand} />
      </div>

      {/* SECTION — Precisa de atenção */}
      <SectionTitle dark={dark} title="Precisa de atenção" action="Ver tudo" />
      <div style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '0 16px 4px', scrollbarWidth: 'none' }}>
        <style>{`.fx-scroll::-webkit-scrollbar{display:none}`}</style>
        <AttentionCard dark={dark}
          aluno={FxData.alunos[2]} tipo="overdue"
          titulo="Inadimplente · 9 dias"
          subt="R$ 450 de abril pendente"
          acao="Lembrar via WhatsApp"
        />
        <AttentionCard dark={dark}
          aluno={FxData.alunos[4]} tipo="risk"
          titulo="14 dias sem treino"
          subt="Aderência caiu para 22%"
          acao="Ligar agora"
        />
        <AttentionCard dark={dark}
          aluno={FxData.alunos[7]} tipo="new"
          titulo="Onboarding pendente"
          subt="Falta enviar anamnese"
          acao="Enviar convite"
        />
      </div>

      {/* SECTION — Seus alunos (horizontal ranking list) */}
      <div style={{ height: 28 }} />
      <SectionTitle dark={dark} title="Aderência da semana" action="Relatório" />
      <div style={{ padding: '0 16px' }}>
        <div style={{ background: cardBg, borderRadius: 22, overflow: 'hidden', boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line }}>
          {[FxData.alunos[0], FxData.alunos[3], FxData.alunos[5]].map((a, i, arr) => (
            <div key={a.id} style={{ display: 'flex', alignItems: 'center', padding: '14px 16px',
              borderBottom: i < arr.length - 1 ? '0.5px solid ' + line : 'none' }}>
              <FxAvatar name={a.nome} size={40} dark={dark} />
              <div style={{ flex: 1, marginLeft: 12, minWidth: 0 }}>
                <div style={{ ...FxText, fontSize: 14, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>{a.nome}</div>
                <div style={{ ...FxText, fontSize: 12, color: mute, marginTop: 1 }}>{a.obj} · {a.treinos} treinos</div>
              </div>
              <FxSparkline data={a.sparkline} w={56} h={22} color={dark ? '#8DA4E2' : FX.brand} />
              <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, color: ink, marginLeft: 14, width: 40, textAlign: 'right' }}>
                {a.aderencia}%
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* SECTION — Atalhos */}
      <div style={{ height: 28 }} />
      <SectionTitle dark={dark} title="Atalhos" />
      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
        <Shortcut dark={dark} icon="spark"    label="Gerar treino IA" />
        <Shortcut dark={dark} icon="plus"     label="Novo aluno" />
        <Shortcut dark={dark} icon="calendar" label="Agenda" />
        <Shortcut dark={dark} icon="chat"     label="Mensagens" sub="3 novas" />
        <Shortcut dark={dark} icon="pix"      label="Cobrar PIX" />
        <Shortcut dark={dark} icon="trend"    label="Leads" sub="5 ativos" />
      </div>
    </div>
  );
}

function SectionTitle({ title, action, dark }) {
  const ink = dark ? FX.darkInk : FX.ink;
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      padding: '0 20px 12px' }}>
      <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 600, color: ink, letterSpacing: '-0.02em' }}>{title}</div>
      {action && <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: dark ? '#8DA4E2' : FX.brand }}>{action} →</div>}
    </div>
  );
}

function QuickTile({ icon, label, value, sub, accent, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  return (
    <div style={{ background: cardBg, borderRadius: 18, padding: '14px 14px 14px',
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + FX.line,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 30, height: 30, borderRadius: 10,
          background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <FxIcon name={icon} size={16} color={dark ? '#8DA4E2' : accent} stroke={2} />
        </div>
      </div>
      <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 600, color: ink, marginTop: 10, letterSpacing: '-0.02em', lineHeight: 1 }}>{value}</div>
      <div style={{ ...FxText, fontSize: 11.5, color: ink, fontWeight: 500, marginTop: 8 }}>{label}</div>
      <div style={{ ...FxText, fontSize: 11, color: mute, marginTop: 1 }}>{sub}</div>
    </div>
  );
}

function AttentionCard({ aluno, tipo, titulo, subt, acao, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const accentMap = {
    overdue: FX.bad, risk: FX.warn, new: FX.brand,
  };
  const accent = accentMap[tipo] || FX.brand;
  return (
    <div style={{ width: 240, flexShrink: 0, background: cardBg, borderRadius: 20, padding: 14,
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + FX.line,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <FxAvatar name={aluno.nome} size={36} dark={dark} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: ink,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{aluno.nome}</div>
          <div style={{ ...FxText, fontSize: 11, color: mute }}>{aluno.obj}</div>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 12,
        color: accent, ...FxText, fontSize: 11.5, fontWeight: 600, letterSpacing: '0.02em', textTransform: 'uppercase' }}>
        <span style={{ width: 5, height: 5, borderRadius: 5, background: accent }} />
        {titulo}
      </div>
      <div style={{ ...FxText, fontSize: 12.5, color: ink, marginTop: 4, lineHeight: 1.35 }}>{subt}</div>
      <div style={{ marginTop: 12, padding: '9px 12px', borderRadius: 12,
        background: dark ? 'rgba(255,255,255,0.05)' : FX.brandSoft,
        color: dark ? '#fff' : FX.brand, ...FxText, fontSize: 12, fontWeight: 600,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{acao} →</div>
    </div>
  );
}

function Shortcut({ icon, label, sub, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  return (
    <div style={{ background: cardBg, borderRadius: 16, padding: '14px 12px',
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + FX.line,
      display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 10, minHeight: 92,
    }}>
      <FxIcon name={icon} size={18} color={dark ? '#8DA4E2' : FX.brand} stroke={1.9} />
      <div>
        <div style={{ ...FxText, fontSize: 12, color: ink, fontWeight: 600, lineHeight: 1.2 }}>{label}</div>
        {sub && <div style={{ ...FxText, fontSize: 10.5, color: mute, marginTop: 2 }}>{sub}</div>}
      </div>
    </div>
  );
}

window.FxDashboard = FxDashboard;

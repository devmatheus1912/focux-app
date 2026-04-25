// Remaining screens: Alertas, Leads CRM Kanban, Agenda Semanal, Gamificação, Analytics

// ─────────────────────────────────────────────────────
// ALERTAS DE RISCO — motor anti-churn
// ─────────────────────────────────────────────────────
function FxAlertas({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const alertas = [
    { id:1, nome:'Rafael Medeiros',   score:2, motivos:['9 dias sem treino','Aderência 45%','Mensalidade atrasada'], dias:9,  aderencia:45 },
    { id:2, nome:'Juliana Torres',    score:2, motivos:['14 dias sem treino','Aderência 22%'], dias:14, aderencia:22 },
    { id:3, nome:'Lucas Andrade',     score:1, motivos:['3 dias sem treino','Aderência caindo'], dias:3,  aderencia:71 },
    { id:4, nome:'Fernanda Lima',     score:1, motivos:['Aderência abaixo de 60%'], dias:2,  aderencia:58 },
  ];

  const scoreColor = (s) => s >= 2
    ? (dark ? '#FF8B8B' : FX.bad)
    : (dark ? '#E2B46F' : FX.warn);
  const scoreBg = (s) => s >= 2
    ? (dark ? 'rgba(255,139,139,0.12)' : FX.badSoft)
    : (dark ? 'rgba(226,180,111,0.12)' : FX.warnSoft);

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      <div style={{ padding: '10px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <div>
          <div style={{ ...FxText, fontSize: 12, color: dark ? '#FF8B8B' : FX.bad, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 4 }}>
            Motor anti-churn
          </div>
          <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Alertas de Risco</div>
        </div>
        <div style={{ padding: '8px 12px', borderRadius: 12, background: dark ? 'rgba(255,255,255,0.06)' : '#fff',
          border: `1px solid ${line}`, display: 'flex', alignItems: 'center', gap: 6,
          ...FxText, fontSize: 12, fontWeight: 600, color: mute,
        }}>
          <FxIcon name="filter" size={14} color={mute} stroke={2} /> Filtrar
        </div>
      </div>

      {/* Config strip */}
      <div style={{ margin: '0 16px 16px', padding: '12px 14px', borderRadius: 14,
        background: dark ? 'rgba(255,255,255,0.04)' : FX.brandSofter,
        border: `1px solid ${dark ? FX.darkLine : 'rgba(59,95,226,0.12)'}`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <FxIcon name="clock" size={15} color={mute} stroke={1.8} />
        <div style={{ ...FxText, fontSize: 12, color: mute }}>
          Dispara se: <span style={{ color: ink, fontWeight: 600 }}>sem treino &gt; 7 dias</span> ou <span style={{ color: ink, fontWeight: 600 }}>aderência &lt; 60%</span>
        </div>
        <div style={{ marginLeft: 'auto', ...FxText, fontSize: 11.5, color: brand, fontWeight: 600 }}>Editar</div>
      </div>

      {/* Summary chips */}
      <div style={{ padding: '0 16px 16px', display: 'flex', gap: 8 }}>
        <div style={{ flex: 1, padding: '10px', borderRadius: 14, background: dark ? 'rgba(255,139,139,0.1)' : FX.badSoft,
          textAlign: 'center', border: `1px solid ${dark ? 'rgba(255,139,139,0.2)' : 'rgba(158,43,43,0.15)'}`,
        }}>
          <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: dark ? '#FF8B8B' : FX.bad }}>2</div>
          <div style={{ ...FxText, fontSize: 11, color: dark ? '#FF8B8B' : FX.bad, fontWeight: 600 }}>Score alto</div>
        </div>
        <div style={{ flex: 1, padding: '10px', borderRadius: 14, background: dark ? 'rgba(226,180,111,0.1)' : FX.warnSoft,
          textAlign: 'center', border: `1px solid ${dark ? 'rgba(226,180,111,0.2)' : 'rgba(138,90,18,0.15)'}`,
        }}>
          <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: dark ? '#E2B46F' : FX.warn }}>2</div>
          <div style={{ ...FxText, fontSize: 11, color: dark ? '#E2B46F' : FX.warn, fontWeight: 600 }}>Score médio</div>
        </div>
        <div style={{ flex: 1, padding: '10px', borderRadius: 14, background: dark ? 'rgba(111,226,150,0.08)' : FX.goodSoft,
          textAlign: 'center', border: `1px solid ${dark ? 'rgba(111,226,150,0.15)' : 'rgba(43,106,63,0.15)'}`,
        }}>
          <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: dark ? '#6FE296' : FX.good }}>20</div>
          <div style={{ ...FxText, fontSize: 11, color: dark ? '#6FE296' : FX.good, fontWeight: 600 }}>Saudáveis</div>
        </div>
      </div>

      {/* Alert list */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {alertas.map(a => (
          <div key={a.id} style={{ background: cardBg, borderRadius: 20, overflow: 'hidden',
            border: `1px solid ${a.score >= 2 ? (dark ? 'rgba(255,139,139,0.25)' : 'rgba(158,43,43,0.2)') : line}`,
          }}>
            <div style={{ padding: '14px 14px 12px', display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <FxAvatar name={a.nome} size={44} dark={dark} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <div style={{ ...FxText, fontSize: 14, fontWeight: 600, color: ink }}>{a.nome}</div>
                  <div style={{ padding: '2px 7px', borderRadius: 999,
                    background: scoreBg(a.score), color: scoreColor(a.score),
                    ...FxMono, fontSize: 11, fontWeight: 700,
                  }}>Score {a.score}</div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                  {a.motivos.map((m, i) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <div style={{ width: 4, height: 4, borderRadius: 4, background: scoreColor(a.score), flexShrink: 0 }}/>
                      <div style={{ ...FxText, fontSize: 12, color: scoreColor(a.score), fontWeight: 500 }}>{m}</div>
                    </div>
                  ))}
                </div>
              </div>
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 700, color: scoreColor(a.score) }}>{a.dias}d</div>
                <div style={{ ...FxText, fontSize: 10.5, color: mute }}>{a.aderencia}% ader.</div>
              </div>
            </div>
            <div style={{ borderTop: `1px solid ${line}`, display: 'flex' }}>
              <div style={{ flex: 1, padding: '10px', textAlign: 'center',
                ...FxText, fontSize: 12, fontWeight: 600, color: brand,
                borderRight: `1px solid ${line}`,
              }}>
                💬 Mensagem
              </div>
              <div style={{ flex: 1, padding: '10px', textAlign: 'center',
                ...FxText, fontSize: 12, fontWeight: 600, color: dark ? '#6FE296' : FX.good,
              }}>
                ✓ Resolvido
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// LEADS / CRM KANBAN
// ─────────────────────────────────────────────────────
function FxLeadsKanban({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const colunas = [
    { id:'LEAD', label:'Lead', cor: brand, leads:[
      { nome:'Amanda Souza', origem:'Instagram', tempo:'2h', tag:'novo' },
      { nome:'Carlos Rocha', origem:'Indicação',  tempo:'1d' },
      { nome:'Priya Nair',   origem:'Landing Page',tempo:'3d' },
    ]},
    { id:'TESTE', label:'Teste', cor: dark ? '#E2B46F' : FX.warn, leads:[
      { nome:'João Melo', origem:'WhatsApp', tempo:'5d', tag:'urgente' },
      { nome:'Tais Lima', origem:'Instagram', tempo:'2d' },
    ]},
    { id:'ATIVO', label:'Ativo', cor: dark ? '#6FE296' : FX.good, leads:[
      { nome:'Beatriz Carvalho', origem:'Indicação', tempo:'30d' },
      { nome:'Lucas Andrade',    origem:'Instagram', tempo:'45d' },
    ]},
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      <div style={{ padding: '10px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <div>
          <div style={{ ...FxText, fontSize: 12, color: brand, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 4 }}>CRM</div>
          <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Funil de Leads</div>
        </div>
        <div style={{ width: 44, height: 44, borderRadius: 44, background: brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 6px 16px rgba(59,95,226,0.4)`,
        }}>
          <FxIcon name="plus" size={20} color="#fff" stroke={2.2} />
        </div>
      </div>

      {/* Summary */}
      <div style={{ padding: '0 16px 16px', display: 'flex', gap: 8 }}>
        {colunas.map(c => (
          <div key={c.id} style={{ flex: 1, padding: '10px 8px', borderRadius: 14,
            background: cardBg, border: `1px solid ${line}`, textAlign: 'center',
          }}>
            <div style={{ width: 8, height: 8, borderRadius: 8, background: c.cor, margin: '0 auto 6px' }}/>
            <div style={{ ...FxDisplay, fontSize: 20, fontWeight: 700, color: ink }}>{c.leads.length}</div>
            <div style={{ ...FxText, fontSize: 10.5, color: mute, fontWeight: 600 }}>{c.label}</div>
          </div>
        ))}
      </div>

      {/* Kanban columns — horizontal scroll */}
      <div style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '0 16px', scrollbarWidth: 'none' }}>
        {colunas.map(col => (
          <div key={col.id} style={{ width: 240, flexShrink: 0 }}>
            {/* column header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
              <div style={{ width: 8, height: 8, borderRadius: 8, background: col.cor }}/>
              <div style={{ ...FxText, fontSize: 13, fontWeight: 700, color: ink }}>{col.label}</div>
              <div style={{ ...FxMono, fontSize: 11, color: mute, marginLeft: 2 }}>({col.leads.length})</div>
            </div>
            {/* cards */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {col.leads.map((l, i) => (
                <div key={i} style={{ background: cardBg, borderRadius: 16, padding: '12px 12px',
                  border: `1px solid ${line}`,
                  borderLeft: `3px solid ${col.cor}`,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                    <FxAvatar name={l.nome} size={32} dark={dark} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: ink,
                        overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                      }}>{l.nome}</div>
                    </div>
                    {l.tag && (
                      <div style={{ padding: '2px 6px', borderRadius: 6,
                        background: col.cor + '22', color: col.cor,
                        ...FxText, fontSize: 9.5, fontWeight: 700,
                      }}>{l.tag}</div>
                    )}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ ...FxText, fontSize: 11, color: mute }}>{l.origem}</div>
                    <div style={{ ...FxText, fontSize: 10.5, color: mute }}>{l.tempo}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
                    <div style={{ flex: 1, height: 30, borderRadius: 8,
                      background: dark ? 'rgba(255,255,255,0.05)' : FX.brandSoft,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
                      ...FxText, fontSize: 11, fontWeight: 600, color: brand,
                    }}>
                      <FxIcon name="send" size={11} color={brand} stroke={2}/> WhatsApp
                    </div>
                    <div style={{ width: 30, height: 30, borderRadius: 8,
                      background: dark ? 'rgba(255,255,255,0.05)' : FX.lineSoft,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <FxIcon name="chev" size={12} color={mute} stroke={2}/>
                    </div>
                  </div>
                </div>
              ))}
              {/* add card */}
              <div style={{ height: 40, borderRadius: 14, border: `1.5px dashed ${line}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                ...FxText, fontSize: 12, color: mute, fontWeight: 500,
              }}>
                <FxIcon name="plus" size={13} color={mute} stroke={2}/> Adicionar
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// AGENDA SEMANAL
// ─────────────────────────────────────────────────────
function FxAgenda({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const dias = ['Seg\n21', 'Ter\n22', 'Qua\n23', 'Qui\n24', 'Sex\n25', 'Sáb\n26', 'Dom\n27'];
  const hoje = 4; // Sex

  const eventos = {
    0: [{ h:'07:00', nome:'Beatriz C.', status:'PRESENTE' }, { h:'08:00', nome:'Lucas A.', status:'PRESENTE' }],
    1: [{ h:'06:30', nome:'Rafael M.', status:'FALTA' }, { h:'09:00', nome:'Camila P.', status:'PRESENTE' }],
    2: [{ h:'07:00', nome:'Pedro H.', status:'PRESENTE' }, { h:'10:00', nome:'Fernanda L.', status:'PRESENTE' }],
    3: [{ h:'07:30', nome:'Gabriel M.', status:'PRESENTE' }],
    4: [{ h:'07:00', nome:'Beatriz C.', status:'AGENDADO' }, { h:'08:30', nome:'Juliana T.', status:'AGENDADO' }, { h:'17:00', nome:'Lucas A.', status:'AGENDADO' }],
    5: [{ h:'09:00', nome:'Beatriz C.', status:'AGENDADO' }],
    6: [],
  };

  const statusColor = (s) => ({
    PRESENTE: dark ? '#6FE296' : FX.good,
    FALTA: dark ? '#FF8B8B' : FX.bad,
    AGENDADO: brand,
    CANCELADO: mute,
  }[s] || brand);

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      {/* Header */}
      <div style={{ padding: '10px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Agenda</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px',
          background: cardBg, borderRadius: 12, border: `1px solid ${line}`,
          ...FxText, fontSize: 13, fontWeight: 600, color: ink,
        }}>
          <svg width="8" height="12" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke={mute} strokeWidth="2" strokeLinecap="round"/></svg>
          21–27 abr
          <svg width="8" height="12" viewBox="0 0 10 16" fill="none"><path d="M2 2l6 6-6 6" stroke={mute} strokeWidth="2" strokeLinecap="round"/></svg>
        </div>
      </div>

      {/* Day tabs */}
      <div style={{ display: 'flex', padding: '0 16px', gap: 6, marginBottom: 16, overflowX: 'auto', scrollbarWidth: 'none' }}>
        {dias.map((d, i) => {
          const count = (eventos[i] || []).length;
          return (
            <div key={i} style={{ flexShrink: 0, display: 'flex', flexDirection: 'column', alignItems: 'center',
              padding: '10px 8px', borderRadius: 14, minWidth: 46,
              background: i === hoje ? brand : cardBg,
              border: `1px solid ${i === hoje ? 'transparent' : line}`,
              boxShadow: i === hoje ? `0 4px 12px rgba(59,95,226,0.35)` : 'none',
            }}>
              {d.split('\n').map((t, j) => (
                <div key={j} style={{
                  ...j === 0 ? FxText : FxDisplay,
                  fontSize: j === 0 ? 10 : 16,
                  fontWeight: j === 0 ? 600 : 700,
                  color: i === hoje ? '#fff' : j === 0 ? mute : ink,
                  lineHeight: 1.2,
                }}>{t}</div>
              ))}
              {count > 0 && (
                <div style={{ marginTop: 4, width: 16, height: 16, borderRadius: 16,
                  background: i === hoje ? 'rgba(255,255,255,0.3)' : brand,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  ...FxMono, fontSize: 9, fontWeight: 700, color: '#fff',
                }}>{count}</div>
              )}
            </div>
          );
        })}
      </div>

      {/* Today's events */}
      <div style={{ padding: '0 20px 10px' }}>
        <div style={{ ...FxDisplay, fontSize: 17, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>
          Sexta · 25 abr · <span style={{ color: brand }}>3 atendimentos</span>
        </div>
      </div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {(eventos[hoje] || []).map((e, i) => (
          <div key={i} style={{ background: cardBg, borderRadius: 18, padding: '14px 14px',
            border: `1px solid ${line}`,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 52, textAlign: 'center', flexShrink: 0 }}>
              <div style={{ ...FxMono, fontSize: 14, fontWeight: 700, color: brand }}>{e.h}</div>
              <div style={{ width: 2, height: 20, background: brand, margin: '4px auto 0', opacity: 0.3, borderRadius: 2 }}/>
            </div>
            <FxAvatar name={e.nome} size={40} dark={dark} />
            <div style={{ flex: 1 }}>
              <div style={{ ...FxText, fontSize: 14, fontWeight: 600, color: ink }}>{e.nome}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
                <div style={{ width: 5, height: 5, borderRadius: 5, background: statusColor(e.status) }}/>
                <div style={{ ...FxText, fontSize: 11.5, color: statusColor(e.status), fontWeight: 600 }}>{e.status}</div>
              </div>
            </div>
            <div style={{ width: 34, height: 34, borderRadius: 10,
              background: dark ? 'rgba(255,255,255,0.06)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <FxIcon name="chev" size={13} color={brand} stroke={2}/>
            </div>
          </div>
        ))}
        {/* Add slot */}
        <div style={{ height: 52, borderRadius: 16, border: `1.5px dashed ${line}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          ...FxText, fontSize: 13, color: mute, fontWeight: 500,
        }}>
          <FxIcon name="plus" size={15} color={mute} stroke={2}/> Novo agendamento
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// GAMIFICAÇÃO — streak, badges, referral
// ─────────────────────────────────────────────────────
function FxGamificacao({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const badges = [
    { tipo:'STREAK_10', icon:'🔥', label:'Sequência 10d', cor:'#E2B46F', earned:true },
    { tipo:'PR_CARGA',  icon:'💪', label:'PR de carga',   cor: brand,    earned:true },
    { tipo:'FREQ_100',  icon:'⭐', label:'100% semana',   cor:'#2BB673', earned:true },
    { tipo:'FIRST_AI',  icon:'✨', label:'Usou a IA',     cor:'#9B7AFF', earned:true },
    { tipo:'LOCK1',     icon:'🏆', label:'50 treinos',    cor: mute,     earned:false },
    { tipo:'LOCK2',     icon:'🎯', label:'Meta atingida', cor: mute,     earned:false },
  ];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      <div style={{ padding: '10px 20px 20px' }}>
        <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Minha Evolução</div>
      </div>

      {/* Streak hero */}
      <div style={{ padding: '0 16px 16px' }}>
        <div style={{
          borderRadius: 26, overflow: 'hidden', position: 'relative',
          background: dark ? `linear-gradient(135deg, #1A2852, #0A0F1E)` : `linear-gradient(135deg, ${FX.brand}, ${FX.brandDeep})`,
          padding: '22px 22px',
        }}>
          <svg style={{ position: 'absolute', inset: 0, opacity: 0.06 }} width="100%" height="100%">
            <defs><pattern id="gg-gam" width="26" height="26" patternUnits="userSpaceOnUse">
              <path d="M 26 0 L 0 0 0 26" fill="none" stroke="#fff" strokeWidth="0.5"/></pattern></defs>
            <rect width="100%" height="100%" fill="url(#gg-gam)" />
          </svg>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, position: 'relative' }}>
            <div style={{ fontSize: 52 }}>🔥</div>
            <div>
              <div style={{ ...FxDisplay, fontSize: 44, fontWeight: 700, color: '#fff', lineHeight: 1, letterSpacing: '-0.03em' }}>12</div>
              <div style={{ ...FxText, fontSize: 14, color: 'rgba(255,255,255,0.75)', marginTop: 2 }}>dias seguidos</div>
            </div>
            <div style={{ flex: 1 }}/>
            <div style={{ textAlign: 'right' }}>
              <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Recorde</div>
              <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 700, color: '#fff' }}>18d</div>
            </div>
          </div>
          <div style={{ marginTop: 18, display: 'flex', gap: 20, position: 'relative' }}>
            <div>
              <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Total treinos</div>
              <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: '#fff' }}>58</div>
            </div>
            <div style={{ width: 1, background: 'rgba(255,255,255,0.2)' }}/>
            <div>
              <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>PRs esse mês</div>
              <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: '#fff' }}>4</div>
            </div>
            <div style={{ width: 1, background: 'rgba(255,255,255,0.2)' }}/>
            <div>
              <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.08em' }}>Aderência</div>
              <div style={{ ...FxDisplay, fontSize: 24, fontWeight: 700, color: '#fff' }}>92%</div>
            </div>
          </div>
        </div>
      </div>

      {/* Badges */}
      <div style={{ padding: '0 20px 12px', ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>
        Conquistas
      </div>
      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
        {badges.map(b => (
          <div key={b.tipo} style={{ background: cardBg, borderRadius: 18, padding: '16px 10px',
            border: `1px solid ${b.earned ? (dark ? 'rgba(255,255,255,0.08)' : line) : line}`,
            textAlign: 'center', opacity: b.earned ? 1 : 0.45,
          }}>
            <div style={{ width: 48, height: 48, borderRadius: 48, margin: '0 auto 8px',
              background: b.earned ? `${b.cor}22` : (dark ? 'rgba(255,255,255,0.04)' : FX.lineSoft),
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 24,
              filter: b.earned ? 'none' : 'grayscale(1)',
            }}>{b.icon}</div>
            <div style={{ ...FxText, fontSize: 11.5, fontWeight: 600, color: ink, lineHeight: 1.3 }}>{b.label}</div>
          </div>
        ))}
      </div>

      {/* Referral */}
      <div style={{ padding: '20px 16px 0' }}>
        <div style={{ background: cardBg, borderRadius: 20, padding: '18px',
          border: `1px solid ${line}`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
            <div style={{ fontSize: 22 }}>🎁</div>
            <div style={{ ...FxDisplay, fontSize: 16, fontWeight: 700, color: ink }}>Indique um amigo</div>
          </div>
          <div style={{ ...FxText, fontSize: 13, color: mute, marginBottom: 14 }}>
            Seu amigo ganha 20% de desconto no primeiro mês!
          </div>
          <div style={{ background: dark ? 'rgba(255,255,255,0.06)' : FX.brandSofter, borderRadius: 12,
            padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            border: `1px solid ${dark ? FX.darkLine : 'rgba(59,95,226,0.12)'}`,
          }}>
            <div style={{ ...FxMono, fontSize: 16, fontWeight: 700, color: ink, letterSpacing: '0.12em' }}>MATHEUS20</div>
            <div style={{ padding: '5px 10px', borderRadius: 8, background: brand,
              ...FxText, fontSize: 12, fontWeight: 700, color: '#fff',
            }}>Copiar</div>
          </div>
          <div style={{ marginTop: 12, height: 44, borderRadius: 12, background: dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft,
            border: `1px solid ${line}`, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            ...FxText, fontSize: 13, fontWeight: 600, color: ink,
          }}>
            <FxIcon name="send" size={14} color={mute} stroke={2}/> Compartilhar
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// ANALYTICS — métricas do negócio (ENTERPRISE)
// ─────────────────────────────────────────────────────
function FxAnalytics({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const metricas = [
    { label:'MRR', value:'R$ 8.420', delta:'+14%', up:true },
    { label:'Churn', value:'4,2%', delta:'-1,1%', up:true },
    { label:'LTV', value:'R$ 2.340', delta:'+8%', up:true },
    { label:'CAC', value:'R$ 42', delta:'-12%', up:true },
  ];

  const barData = [4.2, 5.1, 5.8, 6.2, 7.4, 8.4];
  const barLabels = ['nov', 'dez', 'jan', 'fev', 'mar', 'abr'];
  const maxBar = Math.max(...barData);

  const churnData = [7.2, 6.8, 6.1, 5.4, 5.1, 4.2];

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />
      <div style={{ padding: '10px 20px 16px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ ...FxText, fontSize: 11, color: brand, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 4 }}>ENTERPRISE</div>
          <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: ink, letterSpacing: '-0.025em' }}>Analytics</div>
        </div>
        <div style={{ padding: '7px 12px', borderRadius: 10, background: cardBg, border: `1px solid ${line}`,
          ...FxText, fontSize: 12, fontWeight: 600, color: ink, display: 'flex', alignItems: 'center', gap: 5,
        }}>
          <FxIcon name="calendar" size={13} color={mute} stroke={2}/> 6 meses
        </div>
      </div>

      {/* 4-metric grid */}
      <div style={{ padding: '0 16px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {metricas.map(m => (
          <div key={m.label} style={{ background: cardBg, borderRadius: 18, padding: '16px 16px',
            border: `1px solid ${line}`,
          }}>
            <div style={{ ...FxText, fontSize: 11.5, color: mute, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 6 }}>{m.label}</div>
            <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 700, color: ink, letterSpacing: '-0.02em', lineHeight: 1 }}>{m.value}</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 8 }}>
              <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                <path d={m.up ? 'M5 7V3M3 5l2-2 2 2' : 'M5 3v4M3 5l2 2 2-2'} stroke={m.up ? (dark ? '#6FE296' : FX.good) : (dark ? '#FF8B8B' : FX.bad)} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <div style={{ ...FxText, fontSize: 12, fontWeight: 600, color: m.up ? (dark ? '#6FE296' : FX.good) : (dark ? '#FF8B8B' : FX.bad) }}>{m.delta}</div>
              <div style={{ ...FxText, fontSize: 11, color: mute }}>vs mês passado</div>
            </div>
          </div>
        ))}
      </div>

      {/* MRR chart */}
      <div style={{ padding: '0 16px 14px' }}>
        <div style={{ background: cardBg, borderRadius: 22, padding: '18px 16px',
          border: `1px solid ${line}`,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16 }}>
            <div style={{ ...FxDisplay, fontSize: 16, fontWeight: 600, color: ink }}>Receita recorrente (MRR)</div>
            <div style={{ ...FxMono, fontSize: 11, color: dark ? '#6FE296' : FX.good, fontWeight: 700 }}>+100% em 6m</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 120 }}>
            {barData.map((v, i) => {
              const h = (v / maxBar) * 100;
              const isLast = i === barData.length - 1;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5 }}>
                  <div style={{ ...FxText, fontSize: 9.5, color: isLast ? ink : mute, fontWeight: isLast ? 700 : 400 }}>
                    {v}k
                  </div>
                  <div style={{ width: '100%', height: `${h}%`, borderRadius: '6px 6px 2px 2px',
                    background: isLast
                      ? (dark ? `linear-gradient(180deg, #8DA4E2, #3D5FBE)` : `linear-gradient(180deg, ${FX.brand}, ${FX.brandInk})`)
                      : (dark ? 'rgba(141,164,226,0.2)' : FX.brandSoft),
                  }}/>
                  <div style={{ ...FxText, fontSize: 10, color: isLast ? ink : mute, fontWeight: isLast ? 700 : 400 }}>{barLabels[i]}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Churn sparkline */}
      <div style={{ padding: '0 16px 14px' }}>
        <div style={{ background: cardBg, borderRadius: 22, padding: '18px 16px', border: `1px solid ${line}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ ...FxDisplay, fontSize: 16, fontWeight: 600, color: ink }}>Taxa de churn</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 10px', borderRadius: 999,
              background: dark ? 'rgba(111,226,150,0.12)' : FX.goodSoft,
              ...FxText, fontSize: 12, fontWeight: 700, color: dark ? '#6FE296' : FX.good,
            }}>
              <svg width="9" height="9" viewBox="0 0 10 10" fill="none">
                <path d="M5 7V3M3 5l2-2 2 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              Caindo
            </div>
          </div>
          <FxSparkline data={churnData} w={320} h={68} color={dark ? '#6FE296' : FX.good} fill />
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
            <div style={{ ...FxText, fontSize: 11, color: mute }}>nov · 7,2%</div>
            <div style={{ ...FxText, fontSize: 11, color: dark ? '#6FE296' : FX.good, fontWeight: 700 }}>abr · 4,2%</div>
          </div>
        </div>
      </div>

      {/* Top alunos por LTV */}
      <div style={{ padding: '0 20px 10px', ...FxDisplay, fontSize: 18, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>Top 3 · LTV</div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { nome:'Rafael Medeiros', ltv:'R$ 2.700', months: 6 },
          { nome:'Beatriz Carvalho',ltv:'R$ 2.280', months: 6 },
          { nome:'Juliana Torres',  ltv:'R$ 1.900', months: 5 },
        ].map((a, i) => (
          <div key={i} style={{ background: cardBg, borderRadius: 16, padding: '12px 14px',
            border: `1px solid ${line}`, display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 26, height: 26, borderRadius: 26,
              background: dark ? 'rgba(141,164,226,0.15)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              ...FxDisplay, fontSize: 12, fontWeight: 700, color: brand,
            }}>{i+1}</div>
            <FxAvatar name={a.nome} size={36} dark={dark} />
            <div style={{ flex: 1, ...FxText, fontSize: 13.5, fontWeight: 500, color: ink }}>{a.nome}</div>
            <div style={{ ...FxDisplay, fontSize: 14, fontWeight: 700, color: ink }}>{a.ltv}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  FxAlertas, FxLeadsKanban, FxAgenda, FxGamificacao, FxAnalytics,
});

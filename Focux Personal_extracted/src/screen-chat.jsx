// Chat — personal ↔ aluno, real-time WebSocket STOMP

function FxChat({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;
  const brand = dark ? FX.brandAccent : FX.brand;

  const msgs = [
    { id:1, from:'aluno', text:'Oi Matheus! Consegui bater o PR no supino hoje 🎉 100kg nas 4 séries!', time:'09:12', read:true },
    { id:2, from:'personal', text:'QUE ISSO! Isso é muito resultado pra 3 meses. Você virou outra pessoa na academia 💪', time:'09:14', read:true },
    { id:3, from:'aluno', text:'Hahaha obrigado! Mas tô sentindo o ombro esquerdo um pouco travado. Devo me preocupar?', time:'09:15', read:true },
    { id:4, from:'personal', text:'Dói ou só trava? Se for tensão pós-treino é normal. Hoje à noite faz 3 séries de rotação externa com 3kg e me fala.', time:'09:17', read:true },
    { id:5, from:'aluno', text:'Só trava. Ok, vou fazer!', time:'09:18', read:true },
    { id:6, from:'personal', text:'Perfeito. Amanhã o treino é Pull B — foco nas costas. Chega bem descansado 😤', time:'09:19', read:true },
    { id:7, from:'aluno', text:'Pode deixar! Aliás, você conseguiu rever meu plano alimentar? Tô querendo aumentar a proteína', time:'09:41', read:true },
    { id:8, from:'personal', text:'Sim! Gerei um plano com IA agora de manhã, vou te mandar em PDF ainda hoje. Aumentei pra 2.2g/kg.', time:'09:43', read:false },
  ];

  return (
    <div style={{ background: bg, display: 'flex', flexDirection: 'column', height: '100%', maxHeight: '100%' }}>
      {/* Header */}
      <div style={{ paddingTop: 54, background: cardBg,
        boxShadow: dark ? 'none' : '0 1px 0 ' + line,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', padding: '10px 16px 14px', gap: 12 }}>
          <div style={{ width: 34, height: 34, borderRadius: 34, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft }}>
            <svg width="9" height="15" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke={ink} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ position: 'relative' }}>
            <FxAvatar name="Beatriz Carvalho" size={42} dark={dark} />
            <div style={{ position: 'absolute', bottom: 1, right: 1, width: 10, height: 10,
              borderRadius: 10, background: '#2BB673', border: '2px solid ' + cardBg }}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ ...FxDisplay, fontSize: 16, fontWeight: 600, color: ink }}>Beatriz Carvalho</div>
            <div style={{ ...FxText, fontSize: 12, color: '#2BB673', fontWeight: 500, marginTop: 1 }}>online agora</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: dark ? 'rgba(255,255,255,0.06)' : FX.brandSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FxIcon name="spark" size={16} color={brand} stroke={1.8} />
            </div>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: dark ? 'rgba(255,255,255,0.06)' : FX.lineSoft,
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FxIcon name="more" size={16} color={ink} stroke={2} />
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px 14px', display: 'flex', flexDirection: 'column', gap: 6,
        scrollbarWidth: 'none',
      }}>
        {/* date separator */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '4px 0 10px' }}>
          <div style={{ flex: 1, height: 0.5, background: line }} />
          <div style={{ ...FxText, fontSize: 11, color: mute, fontWeight: 500 }}>hoje · 25 abr</div>
          <div style={{ flex: 1, height: 0.5, background: line }} />
        </div>

        {msgs.map(m => {
          const isMe = m.from === 'personal';
          return (
            <div key={m.id} style={{ display: 'flex', flexDirection: isMe ? 'row-reverse' : 'row',
              alignItems: 'flex-end', gap: 8,
            }}>
              {!isMe && <FxAvatar name="Beatriz Carvalho" size={28} dark={dark} />}
              <div style={{ maxWidth: '72%' }}>
                <div style={{
                  padding: '10px 14px',
                  borderRadius: isMe ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
                  background: isMe
                    ? (dark ? `linear-gradient(135deg, #2440B8, #1A2F8A)` : `linear-gradient(135deg, ${FX.brand}, ${FX.brandInk})`)
                    : (dark ? FX.darkCardHi : '#fff'),
                  color: isMe ? '#fff' : ink,
                  boxShadow: isMe ? 'none' : (dark ? 'none' : '0 1px 2px rgba(0,0,0,0.06)'),
                  border: !isMe ? `1px solid ${line}` : 'none',
                }}>
                  <div style={{ ...FxText, fontSize: 14, lineHeight: 1.45 }}>{m.text}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: isMe ? 'flex-end' : 'flex-start',
                  gap: 4, marginTop: 4, paddingLeft: 4, paddingRight: 4,
                }}>
                  <div style={{ ...FxText, fontSize: 10.5, color: mute }}>{m.time}</div>
                  {isMe && (
                    <svg width="14" height="10" viewBox="0 0 16 10" fill="none">
                      <path d={m.read ? 'M1 5l3 4L15 1M5 5l3 4' : 'M1 5l3 4L15 1'} stroke={m.read ? brand : mute} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  )}
                </div>
              </div>
            </div>
          );
        })}

        {/* Typing indicator */}
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
          <FxAvatar name="Beatriz Carvalho" size={28} dark={dark} />
          <div style={{ padding: '12px 16px', borderRadius: '18px 18px 18px 4px',
            background: dark ? FX.darkCardHi : '#fff', border: `1px solid ${line}`,
            display: 'flex', gap: 4, alignItems: 'center',
          }}>
            {[0,1,2].map(i => (
              <div key={i} style={{ width: 6, height: 6, borderRadius: 6,
                background: mute, opacity: 0.5 + i * 0.25,
              }}/>
            ))}
          </div>
        </div>
      </div>

      {/* Input bar */}
      <div style={{ padding: '10px 12px 28px', background: cardBg,
        boxShadow: dark ? 'none' : '0 -1px 0 ' + line,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <div style={{ flex: 1, background: dark ? 'rgba(255,255,255,0.05)' : FX.paper,
          border: `1px solid ${line}`, borderRadius: 999,
          padding: '11px 16px', display: 'flex', alignItems: 'center',
        }}>
          <div style={{ ...FxText, fontSize: 14, color: mute, flex: 1 }}>Mensagem…</div>
          <div style={{ display: 'flex', gap: 10 }}>
            <FxIcon name="spark" size={16} color={brand} stroke={1.8} />
          </div>
        </div>
        <div style={{ width: 42, height: 42, borderRadius: 42, background: brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 4px 12px rgba(59,95,226,0.3)`,
        }}>
          <FxIcon name="send" size={16} color="#fff" stroke={1.8} />
        </div>
      </div>
    </div>
  );
}

window.FxChat = FxChat;

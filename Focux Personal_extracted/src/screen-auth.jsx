// Pre-login flow: Splash → Onboarding (3 slides) → Login → Esqueci senha → Cadastro
// Each exported as separate component. FxAuthFlow ties them together with internal state.

// ─────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────
function AuthBg({ children, dark = false, style = {} }) {
  return (
    <div style={{
      minHeight: '100%', width: '100%',
      background: dark
        ? `radial-gradient(ellipse at 30% 10%, #1A3A7A 0%, #060C1E 55%, #020818 100%)`
        : `radial-gradient(ellipse at 30% 10%, #1836A0 0%, #0D1B5C 55%, #070F33 100%)`,
      position: 'relative', overflow: 'hidden', ...style,
    }}>
      {/* grid texture */}
      <svg style={{ position: 'absolute', inset: 0, opacity: 0.05, pointerEvents: 'none' }} width="100%" height="100%">
        <defs><pattern id="gg-auth" width="30" height="30" patternUnits="userSpaceOnUse">
          <path d="M 30 0 L 0 0 0 30" fill="none" stroke="#fff" strokeWidth="0.5"/>
        </pattern></defs>
        <rect width="100%" height="100%" fill="url(#gg-auth)" />
      </svg>
      {/* ambient glow */}
      <div style={{ position: 'absolute', top: -80, right: -80, width: 300, height: 300,
        borderRadius: 300, background: 'radial-gradient(circle, rgba(124,192,255,0.18) 0%, transparent 70%)',
        pointerEvents: 'none',
      }}/>
      {children}
    </div>
  );
}

function AuthInput({ label, placeholder, type = 'text', icon, dark = false, action }) {
  const line = dark ? FX.darkLine : 'rgba(255,255,255,0.15)';
  return (
    <div>
      {label && (
        <div style={{ ...FxText, fontSize: 12.5, fontWeight: 600, color: 'rgba(255,255,255,0.7)',
          letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 7,
        }}>{label}</div>
      )}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12,
        background: 'rgba(255,255,255,0.07)', borderRadius: 14,
        border: '1px solid rgba(255,255,255,0.14)',
        padding: '14px 16px',
        backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
      }}>
        {icon && <FxIcon name={icon} size={16} color="rgba(255,255,255,0.5)" stroke={1.8} />}
        <div style={{ ...FxText, fontSize: 15, color: 'rgba(255,255,255,0.4)', flex: 1 }}>{placeholder}</div>
        {action && (
          <div style={{ ...FxText, fontSize: 12, fontWeight: 600, color: FX.brandAccent }}>{action}</div>
        )}
      </div>
    </div>
  );
}

function AuthBtn({ label, primary = true, icon, style = {} }) {
  return (
    <div style={{
      height: 54, borderRadius: 14, cursor: 'pointer',
      background: primary
        ? `linear-gradient(135deg, ${FX.brand} 0%, ${FX.brandInk} 100%)`
        : 'rgba(255,255,255,0.08)',
      border: primary ? 'none' : '1px solid rgba(255,255,255,0.14)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: primary ? `0 8px 24px -8px rgba(59,95,226,0.6)` : 'none',
      ...style,
    }}>
      {icon && <FxIcon name={icon} size={17} color="#fff" stroke={2} />}
      <div style={{ ...FxText, fontSize: 15, fontWeight: 700, color: '#fff' }}>{label}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────
// SPLASH
// ─────────────────────────────────────────────────────
function FxSplash({ dark = false }) {
  return (
    <AuthBg dark={dark}>
      <div style={{ height: '100%', display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', padding: '0 32px',
        paddingTop: 54, paddingBottom: 60, minHeight: 874,
      }}>
        {/* Logo mark — large */}
        <div style={{ marginBottom: 28 }}>
          <FxMark size={110} variant="official" onDark />
        </div>

        {/* Wordmark */}
        <div style={{ ...FxDisplay, fontSize: 42, fontWeight: 700, color: '#fff',
          letterSpacing: '-0.03em', lineHeight: 1, textAlign: 'center',
        }}>FOCUX</div>
        <div style={{ ...FxText, fontSize: 15, color: 'rgba(255,255,255,0.55)', fontWeight: 500,
          letterSpacing: '0.28em', textTransform: 'uppercase', marginTop: 6,
        }}>PERSONAL</div>
        <div style={{ ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.4)', fontStyle: 'italic',
          marginTop: 14, textAlign: 'center',
        }}>Treine com dados. Evolua com inteligência.</div>

        <div style={{ flex: 1 }} />

        {/* Loading indicator */}
        <div style={{ display: 'flex', gap: 6 }}>
          {[1,0.4,0.2].map((o, i) => (
            <div key={i} style={{ width: i === 0 ? 24 : 7, height: 7, borderRadius: 7,
              background: '#fff', opacity: o, transition: 'all 300ms',
            }}/>
          ))}
        </div>
      </div>
    </AuthBg>
  );
}

// ─────────────────────────────────────────────────────
// ONBOARDING INTRO — 3 slides swipeable
// ─────────────────────────────────────────────────────
const introSlides = [
  {
    icon: 'dumbbell',
    title: 'Seus alunos,\nsua gestão.',
    sub: 'Cadastre alunos, monte treinos e acompanhe a evolução de cada um em tempo real.',
    accent: '#7CC0FF',
  },
  {
    icon: 'spark',
    title: 'IA que\nentende treino.',
    sub: 'Gere treinos e dietas personalizados em segundos. A IA aprende com o histórico de cada aluno.',
    accent: '#A0CCFF',
  },
  {
    icon: 'coin',
    title: 'Financeiro\nsem complicação.',
    sub: 'Cobranças, inadimplências e relatórios automatizados. Você foca no que importa: resultados.',
    accent: '#B8D9FF',
  },
];

function FxIntroSlides({ dark = false }) {
  const [active, setActive] = React.useState(0);

  return (
    <AuthBg dark={dark}>
      <div style={{ minHeight: 874, display: 'flex', flexDirection: 'column', paddingTop: 60, paddingBottom: 40 }}>
        {/* Skip */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '0 20px 0' }}>
          <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: 'rgba(255,255,255,0.5)' }}>Pular</div>
        </div>

        {/* Slide content */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
          padding: '20px 32px 0', textAlign: 'center',
        }}>
          {/* Icon illustration */}
          <div style={{ width: 120, height: 120, borderRadius: 36, marginBottom: 32, marginTop: 16,
            background: 'rgba(255,255,255,0.07)',
            border: '1px solid rgba(255,255,255,0.1)',
            backdropFilter: 'blur(16px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative', overflow: 'hidden',
            boxShadow: `0 0 60px ${introSlides[active].accent}33`,
          }}>
            {/* glow behind icon */}
            <div style={{ position: 'absolute', inset: 0, borderRadius: 36,
              background: `radial-gradient(circle at center, ${introSlides[active].accent}22 0%, transparent 70%)`,
            }}/>
            <FxIcon name={introSlides[active].icon} size={52} color={introSlides[active].accent} stroke={1.4} />
          </div>

          <div style={{ ...FxDisplay, fontSize: 34, fontWeight: 700, color: '#fff',
            letterSpacing: '-0.025em', lineHeight: 1.15, marginBottom: 16, whiteSpace: 'pre-line',
          }}>{introSlides[active].title}</div>

          <div style={{ ...FxText, fontSize: 15.5, color: 'rgba(255,255,255,0.65)',
            lineHeight: 1.6, maxWidth: 300,
          }}>{introSlides[active].sub}</div>
        </div>

        {/* Dots */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 32, marginBottom: 28 }}>
          {introSlides.map((_, i) => (
            <div key={i} onClick={() => setActive(i)} style={{
              height: 7, borderRadius: 7, cursor: 'pointer',
              width: i === active ? 28 : 7,
              background: i === active ? '#fff' : 'rgba(255,255,255,0.3)',
              transition: 'all 300ms ease',
            }}/>
          ))}
        </div>

        {/* CTA */}
        <div style={{ padding: '0 24px' }}>
          {active < 2 ? (
            <AuthBtn label="Próximo →" primary onClick={() => setActive(a => Math.min(2, a+1))} />
          ) : (
            <AuthBtn label="Começar agora" primary icon="chev" />
          )}
          <div style={{ textAlign: 'center', marginTop: 14,
            ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.45)',
          }}>
            Já tenho uma conta · <span style={{ color: FX.brandAccent, fontWeight: 600 }}>Entrar</span>
          </div>
        </div>
      </div>
    </AuthBg>
  );
}

// ─────────────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────────────
function FxLogin({ dark = false }) {
  return (
    <AuthBg dark={dark}>
      <div style={{ minHeight: 874, display: 'flex', flexDirection: 'column', paddingTop: 60, paddingBottom: 40 }}>
        {/* Logo */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 36 }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
            <FxMark size={72} variant="official" onDark />
            <div>
              <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 700, color: '#fff',
                letterSpacing: '-0.02em', textAlign: 'center' }}>FOCUX PERSONAL</div>
              <div style={{ ...FxText, fontSize: 12, color: 'rgba(255,255,255,0.45)',
                fontStyle: 'italic', textAlign: 'center', marginTop: 4 }}>
                Treine com dados. Evolua com inteligência.
              </div>
            </div>
          </div>
        </div>

        {/* Form card */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', padding: '0 24px 0' }}>
          <div style={{ background: 'rgba(255,255,255,0.05)', backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)', borderRadius: 28,
            border: '1px solid rgba(255,255,255,0.1)',
            padding: '28px 22px', marginBottom: 20,
          }}>
            <div style={{ ...FxDisplay, fontSize: 26, fontWeight: 700, color: '#fff',
              letterSpacing: '-0.02em', marginBottom: 22,
            }}>Entrar</div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <AuthInput label="E-mail" placeholder="seu@email.com" icon="users" />
              <AuthInput label="Senha" placeholder="••••••••" type="password" icon="warn" action="Ver" />
            </div>

            <div style={{ textAlign: 'right', marginTop: 10, marginBottom: 22 }}>
              <div style={{ ...FxText, fontSize: 13, fontWeight: 600, color: FX.brandAccent }}>
                Esqueci minha senha
              </div>
            </div>

            <AuthBtn label="Entrar" primary />

            {/* divider */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
              <div style={{ flex: 1, height: 0.5, background: 'rgba(255,255,255,0.15)' }}/>
              <div style={{ ...FxText, fontSize: 12, color: 'rgba(255,255,255,0.4)' }}>ou continue com</div>
              <div style={{ flex: 1, height: 0.5, background: 'rgba(255,255,255,0.15)' }}/>
            </div>

            <AuthBtn label="Google" primary={false} icon="search" />
          </div>

          <div style={{ textAlign: 'center', ...FxText, fontSize: 14, color: 'rgba(255,255,255,0.5)' }}>
            Não tem conta?{' '}
            <span style={{ color: '#fff', fontWeight: 700 }}>Criar conta grátis</span>
          </div>
        </div>
      </div>
    </AuthBg>
  );
}

// ─────────────────────────────────────────────────────
// ESQUECI MINHA SENHA
// ─────────────────────────────────────────────────────
function FxEsqueciSenha({ dark = false }) {
  return (
    <AuthBg dark={dark}>
      <div style={{ minHeight: 874, display: 'flex', flexDirection: 'column', paddingTop: 60, paddingBottom: 40 }}>
        {/* back */}
        <div style={{ padding: '0 22px 28px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="10" height="16" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ ...FxText, fontSize: 14, color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>Voltar</div>
        </div>

        <div style={{ padding: '0 24px', flex: 1 }}>
          {/* icon */}
          <div style={{ width: 72, height: 72, borderRadius: 22, marginBottom: 24,
            background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.12)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <FxIcon name="send" size={32} color={FX.brandAccent} stroke={1.6} />
          </div>

          <div style={{ ...FxDisplay, fontSize: 30, fontWeight: 700, color: '#fff',
            letterSpacing: '-0.025em', lineHeight: 1.15, marginBottom: 10,
          }}>Recuperar{'\n'}senha</div>
          <div style={{ ...FxText, fontSize: 14.5, color: 'rgba(255,255,255,0.55)',
            lineHeight: 1.55, marginBottom: 32, maxWidth: 300,
          }}>
            Digite seu e-mail e vamos enviar um link pra redefinir sua senha.
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginBottom: 24 }}>
            <AuthInput label="E-mail cadastrado" placeholder="seu@email.com" icon="users" />
          </div>

          <AuthBtn label="Enviar link de recuperação" primary icon="send" />

          <div style={{ textAlign: 'center', marginTop: 20,
            ...FxText, fontSize: 13, color: 'rgba(255,255,255,0.4)',
          }}>
            Lembrei a senha ·{' '}
            <span style={{ color: FX.brandAccent, fontWeight: 600 }}>Voltar ao login</span>
          </div>
        </div>
      </div>
    </AuthBg>
  );
}

// ─────────────────────────────────────────────────────
// CADASTRO — novo personal trainer
// ─────────────────────────────────────────────────────
function FxCadastro({ dark = false }) {
  return (
    <AuthBg dark={dark}>
      <div style={{ minHeight: 874, display: 'flex', flexDirection: 'column', paddingTop: 54, paddingBottom: 30 }}>
        {/* back */}
        <div style={{ padding: '8px 22px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 38, height: 38, borderRadius: 38, background: 'rgba(255,255,255,0.1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="10" height="16" viewBox="0 0 10 16" fill="none"><path d="M8 2L2 8l6 6" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
        </div>

        <div style={{ padding: '0 24px', flex: 1, display: 'flex', flexDirection: 'column' }}>
          {/* mini lockup */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 22 }}>
            <FxMark size={40} variant="official" onDark />
            <div>
              <div style={{ ...FxDisplay, fontSize: 18, fontWeight: 700, color: '#fff', letterSpacing: '-0.01em' }}>FOCUX</div>
              <div style={{ ...FxText, fontSize: 9.5, color: 'rgba(255,255,255,0.5)', letterSpacing: '0.22em', textTransform: 'uppercase', fontWeight: 600 }}>PERSONAL</div>
            </div>
          </div>

          <div style={{ ...FxDisplay, fontSize: 28, fontWeight: 700, color: '#fff',
            letterSpacing: '-0.025em', lineHeight: 1.15, marginBottom: 6,
          }}>Criar conta</div>
          <div style={{ ...FxText, fontSize: 13.5, color: 'rgba(255,255,255,0.5)', marginBottom: 26 }}>
            Comece grátis. Sem cartão.
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <AuthInput label="Nome completo" placeholder="Seu nome" icon="users" />
            <AuthInput label="E-mail" placeholder="seu@email.com" icon="spark" />
            <AuthInput label="Senha" placeholder="Mín. 8 caracteres" type="password" icon="warn" />
            <AuthInput label="Telefone / WhatsApp" placeholder="(11) 99999-0000" icon="send" />
          </div>

          {/* Planos */}
          <div style={{ marginTop: 20, marginBottom: 20 }}>
            <div style={{ ...FxText, fontSize: 12.5, fontWeight: 600, color: 'rgba(255,255,255,0.7)',
              letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 10,
            }}>Escolha seu plano</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {[
                { name: 'FREE', sub: '3 alunos', price: 'Grátis' },
                { name: 'PREMIUM', sub: '20 alunos · 5d grátis', price: 'R$ 79/mês', highlight: true },
                { name: 'ENTERPRISE', sub: 'Ilimitado · 5d grátis', price: 'R$ 149/mês' },
              ].map(p => (
                <div key={p.name} style={{ flex: 1, borderRadius: 14, padding: '12px 8px', textAlign: 'center', cursor: 'pointer',
                  background: p.highlight ? `linear-gradient(135deg, ${FX.brand}, ${FX.brandInk})` : 'rgba(255,255,255,0.07)',
                  border: p.highlight ? 'none' : '1px solid rgba(255,255,255,0.12)',
                  boxShadow: p.highlight ? '0 6px 20px rgba(59,95,226,0.4)' : 'none',
                }}>
                  <div style={{ ...FxDisplay, fontSize: 12, fontWeight: 700, color: '#fff', letterSpacing: '0.04em' }}>{p.name}</div>
                  <div style={{ ...FxText, fontSize: 10, color: 'rgba(255,255,255,0.6)', marginTop: 2 }}>{p.sub}</div>
                  <div style={{ ...FxText, fontSize: 11.5, fontWeight: 700, color: '#fff', marginTop: 4 }}>{p.price}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={{ flex: 1 }} />

          <AuthBtn label="Criar minha conta" primary />
          <div style={{ textAlign: 'center', marginTop: 12,
            ...FxText, fontSize: 11.5, color: 'rgba(255,255,255,0.35)', lineHeight: 1.5,
          }}>
            Ao criar, você concorda com os{' '}
            <span style={{ color: FX.brandAccent }}>Termos de uso</span>
          </div>
        </div>
      </div>
    </AuthBg>
  );
}

Object.assign(window, {
  FxSplash, FxIntroSlides, FxLogin, FxEsqueciSenha, FxCadastro,
});

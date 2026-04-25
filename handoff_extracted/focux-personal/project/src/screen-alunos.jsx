// Alunos — list screen with search, filter chips, cards

function FxAlunosList({ dark = false }) {
  const bg = dark ? FX.darkBg : FX.paper;
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;

  return (
    <div style={{ background: bg, minHeight: '100%', paddingBottom: 110 }}>
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{ padding: '8px 20px 18px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ ...FxText, fontSize: 12, color: mute, fontWeight: 600, letterSpacing: '0.04em', textTransform: 'uppercase' }}>24 ativos · 2 inadimpl.</div>
          <div style={{ ...FxDisplay, fontSize: 32, color: ink, fontWeight: 600, letterSpacing: '-0.03em', marginTop: 2 }}>Alunos</div>
        </div>
        <div style={{ width: 44, height: 44, borderRadius: 44, background: dark ? '#fff' : FX.brand,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 6px 16px -6px rgba(43,74,158,0.5)',
        }}>
          <FxIcon name="plus" size={20} color={dark ? FX.ink : '#fff'} stroke={2.2} />
        </div>
      </div>

      {/* Search */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10,
          background: cardBg, borderRadius: 14, padding: '12px 14px',
          boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
        }}>
          <FxIcon name="search" size={16} color={mute} stroke={2} />
          <div style={{ ...FxText, fontSize: 14, color: mute, flex: 1 }}>Buscar por nome, objetivo…</div>
          <FxIcon name="filter" size={16} color={dark ? '#8DA4E2' : FX.brand} stroke={2} />
        </div>
      </div>

      {/* Filter chips */}
      <div style={{ paddingBottom: 16 }}>
        <FxChips items={['Todos', 'Ativos', 'Inadimplentes', 'Risco alto', 'Novos']} active={0} dark={dark} />
      </div>

      {/* List */}
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {FxData.alunos.map(a => <AlunoCard key={a.id} a={a} dark={dark} />)}
      </div>
    </div>
  );
}

function AlunoCard({ a, dark }) {
  const cardBg = dark ? FX.darkCard : FX.card;
  const ink = dark ? FX.darkInk : FX.ink;
  const mute = dark ? FX.darkInkMute : FX.inkMute;
  const line = dark ? FX.darkLine : FX.line;

  const aderColor =
    a.aderencia >= 70 ? (dark ? '#6FE296' : FX.good) :
    a.aderencia >= 40 ? (dark ? '#E2B46F' : FX.warn) :
                         (dark ? '#FF8B8B' : FX.bad);

  return (
    <div style={{ background: cardBg, borderRadius: 20, padding: 14,
      boxShadow: dark ? 'none' : 'inset 0 0 0 1px ' + line,
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <FxAvatar name={a.nome} size={48} dark={dark} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ ...FxText, fontSize: 14.5, fontWeight: 600, color: ink, letterSpacing: '-0.01em' }}>{a.nome}</div>
          {a.status !== 'active' && <FxStatus kind={a.status} dark={dark} small />}
        </div>
        <div style={{ ...FxText, fontSize: 12, color: mute, marginTop: 2 }}>{a.obj} · {a.idade} anos</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <div style={{ width: 6, height: 6, borderRadius: 6, background: aderColor }} />
            <div style={{ ...FxText, fontSize: 11, color: ink, fontWeight: 600 }}>{a.aderencia}%</div>
            <div style={{ ...FxText, fontSize: 11, color: mute }}>aderência</div>
          </div>
          <div style={{ width: 1, height: 10, background: line }} />
          <div style={{ ...FxText, fontSize: 11, color: mute }}>{a.diasSem === 0 ? 'Treinou hoje' : `há ${a.diasSem}d`}</div>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
        <FxSparkline data={a.sparkline} w={60} h={24} color={aderColor} fill={false} />
        <FxIcon name="chev" size={14} color={mute} stroke={2} />
      </div>
    </div>
  );
}

window.FxAlunosList = FxAlunosList;

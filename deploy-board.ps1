# Updates the mill-board pace files on WEB03 (disclaimer + Targets Pending wording)
$root = 'C:\millboard\mill-board-master'
$enc  = New-Object System.Text.UTF8Encoding($false)

[IO.File]::WriteAllText((Join-Path $root 'src\PaceBoard.js'), @'
import React, { useState, useEffect } from 'react';
import './PaceBoard.css';

/* Pace board for the TV.
   /?mill=plate   -> Rolling + Shipping
   /?mill=pipe    -> Forming + Scope + Stencil
   add &asOf=2026-10-31 to test a specific day */

const THEME = {
  DARKGREEN:  { main: '#1f8a3b', tint: '#eaf6ee', edge: '#cfe9d6', arc: '#b7e0c2', status: 'ON PACE',         footer: 'ON TRACK - KEEP IT UP',      icon: 'check' },
  LIGHTGREEN: { main: '#6aa72d', tint: '#f2f8ea', edge: '#dcedc6', arc: '#d3e9b9', status: 'SLIGHTLY BEHIND', footer: 'CLOSE - PUSH TO CLOSE THE GAP', icon: 'check' },
  RED:        { main: '#d23b31', tint: '#fdf1f1', edge: '#f4c9c6', arc: '#f1b1bb', status: 'BEHIND PACE',     footer: 'ACTION NEEDED TO CATCH UP',  icon: 'x' },
  NOTARGET:   { main: '#7b8494', tint: '#f3f4f6', edge: '#dfe2e7', arc: '#d5d9e0', status: 'TARGETS PENDING', footer: 'TARGETS PENDING FOR REVIEW', icon: 'x' }
};

const UNIT = {
  'Plate Mill Slab Rolling':     { mtd: 'MTD PRODUCTION', today: "TODAY'S PRODUCTION" },
  'Trade Prime Plate Shipments': { mtd: 'MTD SHIPMENTS',  today: "TODAY'S SHIPMENTS" }
};

const fmt = (n) => (n === null || n === undefined ? '-' : Math.round(Number(n)).toLocaleString());

/* ---------- small inline icons (no extra packages) ---------- */
const Icon = ({ name, color, size = 34 }) => {
  const s = { width: size, height: size, flex: '0 0 auto' };
  if (name === 'check') return (
    <svg viewBox="0 0 24 24" style={s} fill="none" stroke={color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><path d="M7.5 12.5l3 3 6-6.5" />
    </svg>);
  if (name === 'x') return (
    <svg viewBox="0 0 24 24" style={s} fill="none" stroke={color} strokeWidth="2.4" strokeLinecap="round">
      <circle cx="12" cy="12" r="10" /><path d="M9 9l6 6M15 9l-6 6" />
    </svg>);
  if (name === 'bell') return (
    <svg viewBox="0 0 24 24" style={s} fill={color}>
      <path d="M12 2a6 6 0 0 0-6 6v4.5L4 16v1h16v-1l-2-3.5V8a6 6 0 0 0-6-6zm0 21a2.5 2.5 0 0 0 2.45-2h-4.9A2.5 2.5 0 0 0 12 23z" />
    </svg>);
  if (name === 'trend') return (
    <svg viewBox="0 0 24 24" style={s}>
      <circle cx="12" cy="12" r="12" fill={color} />
      <path d="M6 15l4-4 3 3 5-5" fill="none" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>);
  if (name === 'target') return (
    <svg viewBox="0 0 24 24" style={s} fill="none" stroke={color} strokeWidth="2.4">
      <circle cx="12" cy="12" r="10" /><circle cx="12" cy="12" r="5.5" /><circle cx="12" cy="12" r="1.5" fill={color} />
    </svg>);
  return null;
};

/* ---------- semicircle gauge (SVG, rounded ends) ---------- */
const Gauge = ({ pct, theme }) => {
  const p = Math.max(0, Math.min(pct || 0, 100));
  const r = 80, len = Math.PI * r;               // half-circle length
  return (
    <div className="pb-gauge">
      <svg viewBox="0 0 200 115">
        <path d="M20 100 A80 80 0 0 1 180 100" fill="none" stroke={theme.arc} strokeWidth="18" strokeLinecap="round" />
        <path d="M20 100 A80 80 0 0 1 180 100" fill="none" stroke={theme.main} strokeWidth="18" strokeLinecap="round"
              strokeDasharray={`${(p / 100) * len} ${len}`} />
      </svg>
      <div className="pb-gauge-text">
        <div className="pb-gauge-pct">{pct === null || pct === undefined ? '-' : `${pct}%`}</div>
        <div className="pb-gauge-sub">COMPLETE</div>
      </div>
    </div>
  );
};

/* ---------- one card ---------- */
function PaceCard({ card }) {
  const t = THEME[card.PaceColor] || THEME.NOTARGET;
  const labels = UNIT[card.Card] || { mtd: 'MTD PRODUCTION', today: "TODAY'S PRODUCTION" };

  const asOf      = new Date(card.AsOfDate);
  const monthEnd  = new Date(Date.UTC(asOf.getUTCFullYear(), asOf.getUTCMonth() + 1, 0));
  const daysLeft  = Math.round((monthEnd - asOf) / 86400000);           // days after AsOf
  const hasTarget = card.MonthTarget !== null && card.MonthTarget !== undefined && card.MonthTarget > 0;
  const remaining = hasTarget ? Math.max(card.MonthTarget - (card.ActualMtd || 0), 0) : null;
  const perDay    = hasTarget && daysLeft > 0 ? remaining / daysLeft : null;

  return (
    <div className="pb-card" style={{ '--main': t.main, '--tint': t.tint, '--edge': t.edge }}>
      <div className="pb-title">{card.Card.toUpperCase()}</div>

      <div className={"pb-status" + (card.PaceColor === "NOTARGET" ? " pb-status-pending" : "")}>
        <Icon name={t.icon} color="#fff" size={40} />
        <span>{t.status}</span>
        {card.PacePct !== null && <span className="pb-status-pct">{card.PacePct}% OF PACE</span>}
      </div>

      <div className="pb-body">
        <Gauge pct={card.MonthPct} theme={t} />

        <div className="pb-box pb-totals">
          <div className="pb-totals-row">
            <span className="pb-big">{fmt(card.ActualMtd)}</span>
            <span className="pb-slash">/</span>
            <span className="pb-mid">{fmt(card.MonthTarget)}</span>
            <span className="pb-unit">TONS</span>
          </div>
          <div className="pb-totals-labels">
            <span>{labels.mtd}</span><span>MONTHLY TARGET</span>
          </div>
        </div>

        <div className="pb-box pb-tinted pb-remaining">
          <Icon name="bell" color="var(--main)" size={40} />
          {!hasTarget
            ? <span className="pb-label">TARGETS PENDING FOR REVIEW</span>
            : remaining > 0
              ? <><span className="pb-big2">{fmt(remaining)}</span><span className="pb-label">TONS REMAINING</span></>
              : <span className="pb-big2">TARGET MET</span>}
        </div>

        <div className="pb-row">
          <div className="pb-box pb-tinted pb-small">
            <Icon name="trend" color="var(--main)" size={40} />
            <div>
              <div className="pb-big2">{fmt(card.ActualToday)}</div>
              <div className="pb-label">{labels.today}</div>
            </div>
          </div>
          <div className="pb-box pb-tinted pb-small">
            <Icon name="target" color="var(--main)" size={40} />
            <div>
              <div className="pb-big2">{!hasTarget ? '-' : perDay === null ? 'FINAL' : fmt(perDay)}</div>
              <div className="pb-label">
                {!hasTarget ? 'TONS/DAY NEEDED' : perDay === null ? 'MONTH COMPLETE' : <>TONS/DAY NEEDED<br />({daysLeft} DAY{daysLeft === 1 ? '' : 'S'} LEFT)</>}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="pb-footer">{t.footer}</div>
    </div>
  );
}

/* ---------- page ---------- */
export default function PaceBoard({ mill, asOf }) {
  const [cards, setCards]   = useState([]);
  const [error, setError]   = useState('');
  const [loaded, setLoaded] = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch('/api', {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify({ pace: true, asOf: asOf || null })
        });
        if (!res.ok) throw new Error(res.status);
        const rows = await res.json();
        setCards(rows.filter(r => r.Mill === mill.toUpperCase()));
        setLoaded(new Date().toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }));
        setError('');
      } catch (e) {
        setError('Data refresh failed - showing last values');   // keep last good cards on screen
      }
    };
    load();
    const t = setInterval(load, 60000);
    return () => clearInterval(t);
  }, [mill, asOf]);

  const day = cards.length ? new Date(cards[0].AsOfDate).toISOString().slice(0, 10) : '';

  return (
    <div className={`pb-page pb-count-${cards.length}`}>
      <div className="pb-header">
        <span>{mill.toUpperCase() === 'PIPE' ? 'PIPE MILL' : 'PLATE MILL'}</span>
        <span className="pb-header-sub">
          PRODUCTION DAY {day}{loaded && ` | UPDATED ${loaded}`}
          {error && <span className="pb-error"> | {error}</span>}
        </span>
      </div>
      <div className="pb-cards">
        {cards.map(c => <PaceCard key={c.Card} card={c} />)}
      </div>
      <div className="pb-disclaimer">
        HIP/MIP payout is subject to audit clearance and final management approval.
      </div>
    </div>
  );
}
'@, $enc)
Write-Host 'wrote src\PaceBoard.js'

[IO.File]::WriteAllText((Join-Path $root 'src\PaceBoard.css'), @'
/* Pace board - sized for a 1920x1080 TV, scales with the window */

.pb-page {
  min-height: 100vh;
  box-sizing: border-box;
  padding: 1.6vh 1.6vw;
  background: #e9edf2;
  font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
  color: #1b2333;
  display: flex;
  flex-direction: column;
}

.pb-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  font-weight: 900;
  font-size: 3.2vh;
  letter-spacing: 0.25vh;
  margin: 0 0.4vw 1.4vh;
}
.pb-header-sub { font-size: 1.9vh; font-weight: 700; color: #5b6475; letter-spacing: 0.1vh; }
.pb-error      { color: #d23b31; }

.pb-cards {
  flex: 1;
  display: flex;
  gap: 1.6vw;
  align-items: stretch;
}

/* ---------- card ---------- */
.pb-card {
  flex: 1 1 0;
  min-width: 0;
  background: #fff;
  border-radius: 1.4vh;
  overflow: hidden;
  box-shadow: 0 0.6vh 2vh rgba(20, 30, 50, 0.12);
  display: flex;
  flex-direction: column;
}

.pb-title {
  background: #111a2e;
  color: #fff;
  text-align: center;
  font-weight: 900;
  font-size: 2.9vh;
  letter-spacing: 0.3vh;
  padding: 2.2vh 1vw;
}

.pb-status {
  background: var(--main);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1vw;
  font-weight: 900;
  font-size: 4.6vh;
  letter-spacing: 0.35vh;
  padding: 1.6vh 1vw;
  white-space: nowrap;
}
.pb-status svg { width: 4.6vh !important; height: 4.6vh !important; }
.pb-status-pct { font-size: 2.2vh; font-weight: 800; opacity: 0.9; letter-spacing: 0.1vh; }

.pb-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  gap: 1.4vh;
  padding: 2vh 1.6vw;
}

/* ---------- gauge ---------- */
.pb-gauge {
  position: relative;
  width: min(70%, 40vh);
  margin: 0 auto;
}
.pb-gauge svg { display: block; width: 100%; height: auto; }
.pb-gauge-text {
  position: absolute;
  left: 0; right: 0; bottom: 0;
  text-align: center;
}
.pb-gauge-pct { font-size: 5.8vh; font-weight: 900; line-height: 1; color: #111a2e; }
.pb-gauge-sub { font-size: 2vh; font-weight: 800; letter-spacing: 0.35vh; color: #5b6475; margin-top: 0.6vh; }

/* ---------- boxes ---------- */
.pb-box {
  border: 0.2vh solid #e3e7ee;
  border-radius: 1.2vh;
  padding: 1.6vh 1.2vw;
  box-shadow: 0 0.2vh 0.6vh rgba(20, 30, 50, 0.05);
}
.pb-tinted {
  background: var(--tint);
  border-color: var(--edge);
}

.pb-totals { text-align: center; }
.pb-totals-row {
  display: flex;
  justify-content: center;
  align-items: baseline;
  gap: 0.6vw;
}
.pb-big   { font-size: 6vh; font-weight: 900; color: var(--main); line-height: 1; }
.pb-slash { font-size: 3.4vh; font-weight: 700; color: #8a93a3; }
.pb-mid   { font-size: 3.8vh; font-weight: 900; color: #3d4659; }
.pb-unit  { font-size: 2.6vh; font-weight: 900; color: #3d4659; }
.pb-totals-labels {
  display: flex;
  justify-content: center;
  gap: 2.4vw;
  margin-top: 1vh;
  font-size: 1.8vh;
  font-weight: 800;
  letter-spacing: 0.25vh;
  color: #5b6475;
}

.pb-remaining {
  display: flex;
  align-items: center;
  gap: 1.2vw;
}
.pb-big2 { font-size: 4.6vh; font-weight: 900; color: var(--main); line-height: 1.05; }
.pb-label {
  font-size: 1.8vh;
  font-weight: 900;
  letter-spacing: 0.2vh;
  color: var(--main);
  line-height: 1.3;
}
.pb-remaining .pb-label { font-size: 2.4vh; }

.pb-row {
  display: flex;
  gap: 1vw;
}
.pb-small {
  flex: 1 1 0;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 0.9vw;
}

.pb-box svg { width: 4.4vh !important; height: 4.4vh !important; }

/* ---------- footer ---------- */
.pb-footer {
  background: var(--main);
  color: #fff;
  text-align: center;
  font-weight: 900;
  font-size: 2.8vh;
  letter-spacing: 0.35vh;
  padding: 2vh 1vw;
}

/* ---------- 3 cards (pipe): tighter so everything fits ---------- */
.pb-count-3 .pb-title       { font-size: 2.6vh; padding: 1.8vh 1vw; }
.pb-count-3 .pb-status      { font-size: 3.6vh; padding: 1.4vh 1vw; }
.pb-count-3 .pb-status svg  { width: 3.8vh !important; height: 3.8vh !important; }
.pb-count-3 .pb-status-pct  { display: none; }
.pb-count-3 .pb-body        { padding: 1.6vh 1.2vw; gap: 1.2vh; }
.pb-count-3 .pb-gauge       { width: min(72%, 34vh); }
.pb-count-3 .pb-gauge-pct   { font-size: 5vh; }
.pb-count-3 .pb-big         { font-size: 4.8vh; }
.pb-count-3 .pb-mid         { font-size: 3.2vh; }
.pb-count-3 .pb-unit        { font-size: 2.2vh; }
.pb-count-3 .pb-totals-labels { font-size: 1.5vh; gap: 1.6vw; }
.pb-count-3 .pb-box         { padding: 1.3vh 0.9vw; }
.pb-count-3 .pb-big2        { font-size: 3.4vh; }
.pb-count-3 .pb-label       { font-size: 1.45vh; letter-spacing: 0.12vh; }
.pb-count-3 .pb-remaining .pb-label { font-size: 1.9vh; }
.pb-count-3 .pb-row         { gap: 0.7vw; }
.pb-count-3 .pb-small       { gap: 0.6vw; }
.pb-count-3 .pb-box svg     { width: 3.6vh !important; height: 3.6vh !important; }
.pb-count-3 .pb-footer      { font-size: 2.2vh; padding: 1.7vh 0.6vw; }

/* ---------- disclaimer footer ---------- */
.pb-disclaimer {
  margin-top: 1.2vh;
  text-align: center;
  font-size: 2.3vh;
  font-weight: 800;
  font-style: italic;
  color: #3d4659;
  letter-spacing: 0.05vh;
}
.pb-count-3 .pb-disclaimer { font-size: 2vh; }

/* ---------- pending status fits the long text on one line ---------- */
.pb-status-pending        { font-size: 3vh; letter-spacing: 0.15vh; }
.pb-status-pending svg    { width: 3.2vh !important; height: 3.2vh !important; }
.pb-count-3 .pb-status-pending { font-size: 2.2vh; letter-spacing: 0.1vh; gap: 0.5vw; }
.pb-count-3 .pb-status-pending svg { width: 2.6vh !important; height: 2.6vh !important; }
'@, $enc)
Write-Host 'wrote src\PaceBoard.css'

Write-Host 'Board files updated. Now run: npm run build; pm2 restart mill-board' -ForegroundColor Green

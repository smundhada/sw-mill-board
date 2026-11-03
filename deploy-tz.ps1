# Updates PaceBoard.js on WEB03 (UPDATED label now shows Central/plant time)
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
        setLoaded(new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', timeZone: 'America/Chicago' }));
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

Write-Host 'Done. Now run: npm run build; pm2 restart mill-board' -ForegroundColor Green

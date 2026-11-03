# deploy-pct: PaceBoard.css with pipe % of pace shown
$root = 'C:\millboard\mill-board-master'
$enc  = New-Object System.Text.UTF8Encoding($false)

[IO.File]::WriteAllText((Join-Path $root 'src\PaceBoard.css'), @'
/* Pace board - sized for a 1920x1080 TV, scales with the window */

.pb-page {
  min-height: 100vh;
  box-sizing: border-box;
  padding: 1vh 1.6vw;
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
  margin: 0 0.4vw 0.8vh;
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
  padding: 1.8vh 1vw;
}

.pb-status {
  background: var(--main);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1vw;
  font-weight: 900;
  font-size: 4vh;
  letter-spacing: 0.3vh;
  padding: 1.2vh 1vw;
  white-space: nowrap;
}
.pb-status svg { width: 4vh !important; height: 4vh !important; }
.pb-status-pct { font-size: 2.2vh; font-weight: 800; opacity: 0.9; letter-spacing: 0.1vh; }

.pb-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  gap: 1vh;
  padding: 1.4vh 1.6vw;
}

/* ---------- gauge ---------- */
.pb-gauge {
  position: relative;
  width: min(60%, 33vh);
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
  padding: 1.2vh 1.2vw;
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
  font-size: 2.6vh;
  letter-spacing: 0.35vh;
  padding: 1.5vh 1vw;
}

/* ---------- 3 cards (pipe): tighter so everything fits ---------- */
.pb-count-3 .pb-title       { font-size: 2.6vh; padding: 1.8vh 1vw; }
.pb-count-3 .pb-status      { font-size: 3.2vh; padding: 1.4vh 0.6vw; gap: 0.5vw; }
.pb-count-3 .pb-status svg  { width: 3.8vh !important; height: 3.8vh !important; }
.pb-count-3 .pb-status-pct  { font-size: 1.5vh; }
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
  margin-top: 0.6vh;
  text-align: center;
  font-size: 2.1vh;
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

Write-Host 'Done. Run: npm run build; pm2 restart mill-board' -ForegroundColor Green

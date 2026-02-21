/* ================================================================
   URM Simulator — Frontend Application
   ================================================================ */

const API = '';   // same origin; change to 'http://localhost:8080' if serving separately

/* ---------------------------------------------------------------- */
/* DOM references                                                    */
/* ---------------------------------------------------------------- */
const editor        = document.getElementById('editor');
const lineNumbers   = document.getElementById('lineNumbers');
const progName      = document.getElementById('progName');
const progArgs      = document.getElementById('progArgs');
const boundSteps    = document.getElementById('boundSteps');
const outputLog     = document.getElementById('outputLog');
const registersDiv  = document.getElementById('registersTable');
const pcDisplay     = document.getElementById('pcDisplay');
const progViewSec   = document.getElementById('progViewSection');
const progViewTitle = document.getElementById('progViewTitle');
const progViewList  = document.getElementById('progViewList');
const stepStatus    = document.getElementById('stepStatus');
const helpModal     = document.getElementById('helpModal');
const helpContent   = document.getElementById('helpContent');
const fileSelect    = document.getElementById('fileSelect');
const optExamples   = document.getElementById('optExamples');
const optSaved      = document.getElementById('optSaved');
const saveFilename  = document.getElementById('saveFilename');

/* ---------------------------------------------------------------- */
/* State                                                             */
/* ---------------------------------------------------------------- */
let sessionId      = null;          // active step session
let lastRegisters  = null;          // for change-highlighting
let stepProgInstr  = [];            // instruction list during stepping

/* ---------------------------------------------------------------- */
/* Utilities                                                         */
/* ---------------------------------------------------------------- */

function parseArgs(str) {
  if (!str.trim()) return [];
  return str.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n));
}

async function api(path, body) {
  const opts = body === undefined
    ? { method: 'GET' }
    : { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) };
  const r = await fetch(API + path, opts);
  return r.json();
}

/* ---------------------------------------------------------------- */
/* Output log                                                        */
/* ---------------------------------------------------------------- */

function log(msg, cls = 'log-info') {
  const d = document.createElement('div');
  d.className = 'log-entry ' + cls;
  d.textContent = msg;
  outputLog.appendChild(d);
  outputLog.scrollTop = outputLog.scrollHeight;
}

function logCmd(cmd)  { log('▶ ' + cmd, 'log-cmd'); }
function logOk(msg)   { log(msg, 'log-ok'); }
function logErr(msg)  { log('✗ ' + msg, 'log-err'); }
function logStep(msg) { log(msg, 'log-step'); }

document.getElementById('btnClearLog').addEventListener('click', () => {
  outputLog.innerHTML = '';
});

/* ---------------------------------------------------------------- */
/* Register display                                                  */
/* ---------------------------------------------------------------- */

function showRegisters(regs, pc = null, highlight = null) {
  registersDiv.innerHTML = '';

  // Only show registers up to the last non-zero one (min 4)
  let maxShow = 4;
  for (let i = regs.length - 1; i >= 0; i--) {
    if (regs[i] !== 0) { maxShow = Math.max(i + 2, 4); break; }
  }
  maxShow = Math.min(maxShow, regs.length);

  for (let i = 0; i < maxShow; i++) {
    const cell = document.createElement('div');
    cell.className = 'reg-cell';
    if (i === 0) cell.classList.add('output-reg'); // R1 is output
    if (highlight && lastRegisters && lastRegisters[i] !== regs[i])
      cell.classList.add('changed');

    const name = document.createElement('div');
    name.className = 'reg-name';
    name.textContent = 'R' + (i + 1);

    const val = document.createElement('div');
    val.className = 'reg-val';
    val.textContent = regs[i] ?? 0;

    cell.appendChild(name);
    cell.appendChild(val);
    registersDiv.appendChild(cell);
  }

  lastRegisters = [...regs];

  if (pc !== null) {
    pcDisplay.textContent = 'PC: ' + (pc > (stepProgInstr.length || 9999) ? 'halt' : pc);
    highlightEditorLine(pc);
    highlightProgViewLine(pc);
  }
}

function clearRegisters() {
  registersDiv.innerHTML = '<div class="reg-placeholder">Run a program to see register values.</div>';
  lastRegisters = null;
  pcDisplay.textContent = 'PC: —';
}

/* ---------------------------------------------------------------- */
/* Editor line numbers + PC highlight                               */
/* ---------------------------------------------------------------- */

function updateLineNumbers() {
  const lines = editor.value.split('\n').length;
  lineNumbers.textContent = Array.from({ length: lines }, (_, i) => i + 1).join('\n');
}

editor.addEventListener('input', updateLineNumbers);
editor.addEventListener('scroll', () => { lineNumbers.scrollTop = editor.scrollTop; });
updateLineNumbers();

// We overlay a highlight using a CSS background on the textarea.
// For accurate highlighting we use a transparent textarea over a div mirror.
// Simpler approach: we show current line in the prog-view list (below).
function highlightEditorLine(_pc) {
  // Line highlighting in a plain textarea is complex without a mirror div.
  // We indicate the current instruction via the prog-view panel instead.
}

/* ---------------------------------------------------------------- */
/* Program view panel                                               */
/* ---------------------------------------------------------------- */

function showProgView(title, instructions) {
  progViewTitle.textContent = title;
  progViewList.innerHTML = '';
  stepProgInstr = instructions;
  instructions.forEach(line => {
    const li = document.createElement('li');
    li.textContent = line;
    progViewList.appendChild(li);
  });
  progViewSec.style.display = '';
}

function highlightProgViewLine(pc) {
  const items = progViewList.querySelectorAll('li');
  items.forEach((li, i) => {
    li.classList.toggle('current-instr', i === pc - 1);
  });
  // Scroll into view
  if (pc >= 1 && pc <= items.length) {
    items[pc - 1].scrollIntoView({ block: 'nearest' });
  }
}

document.getElementById('btnCloseProgView').addEventListener('click', () => {
  progViewSec.style.display = 'none';
  stepProgInstr = [];
});

/* ---------------------------------------------------------------- */
/* RUN                                                               */
/* ---------------------------------------------------------------- */

document.getElementById('btnRun').addEventListener('click', async () => {
  const name = progName.value.trim();
  const args = parseArgs(progArgs.value);
  if (!name) { logErr('Enter a program name.'); return; }
  logCmd('RUN ' + name + '(' + args.join(', ') + ')');
  const res = await api('/api/run', { source: editor.value, name, args });
  if (!res.ok) { logErr(res.error); return; }
  showRegisters(res.data.registers, null, true);
  const regStr = res.data.registers
    .map((v, i) => 'R' + (i+1) + '=' + v)
    .join('  ');
  logOk(regStr);
});

/* ---------------------------------------------------------------- */
/* EVAL                                                              */
/* ---------------------------------------------------------------- */

document.getElementById('btnEval').addEventListener('click', async () => {
  const name = progName.value.trim();
  const args = parseArgs(progArgs.value);
  if (!name) { logErr('Enter a program name.'); return; }
  logCmd('EVAL ' + name + '(' + args.join(', ') + ')');
  const res = await api('/api/eval', { source: editor.value, name, args });
  if (!res.ok) { logErr(res.error); return; }
  showRegisters([res.data.result], null, false);
  logOk('R1 = ' + res.data.result);
});

/* ---------------------------------------------------------------- */
/* RUNBOUND                                                          */
/* ---------------------------------------------------------------- */

document.getElementById('btnRunBound').addEventListener('click', async () => {
  const name  = progName.value.trim();
  const args  = parseArgs(progArgs.value);
  const bound = parseInt(boundSteps.value, 10) || 100;
  if (!name) { logErr('Enter a program name.'); return; }
  logCmd('RUNBOUND ' + name + '(' + args.join(', ') + ') ' + bound);
  const res = await api('/api/runbound', { source: editor.value, name, args, bound });
  if (!res.ok) { logErr(res.error); return; }
  showRegisters(res.data.registers, null, true);
  const regStr = res.data.registers
    .map((v, i) => 'R' + (i+1) + '=' + v)
    .join('  ');
  logOk(regStr + '  [max ' + bound + ' steps]');
});

/* ---------------------------------------------------------------- */
/* PRINT                                                             */
/* ---------------------------------------------------------------- */

document.getElementById('btnPrint').addEventListener('click', async () => {
  const name = progName.value.trim();
  if (!name) { logErr('Enter a program name to print.'); return; }
  logCmd('PRINT ' + name);
  const res = await api('/api/print', { source: editor.value, name });
  if (!res.ok) { logErr(res.error); return; }
  logOk('Program ' + name + ' (' + res.data.instructions.length + ' instructions):');
  res.data.instructions.forEach(l => log('  ' + l, 'log-info'));
});

/* ---------------------------------------------------------------- */
/* Step-by-step                                                      */
/* ---------------------------------------------------------------- */

const btnStepStart = document.getElementById('btnStepStart');
const btnStepNext  = document.getElementById('btnStepNext');
const btnStepReset = document.getElementById('btnStepReset');

function setStepUI(active) {
  btnStepStart.disabled = active;
  btnStepNext.disabled  = !active;
  btnStepReset.disabled = !active;
}

btnStepStart.addEventListener('click', async () => {
  const name = progName.value.trim();
  const args = parseArgs(progArgs.value);
  if (!name) { logErr('Enter a program name to step through.'); return; }
  logCmd('STEP ' + name + '(' + args.join(', ') + ')');
  const res = await api('/api/step/start', { source: editor.value, name, args });
  if (!res.ok) { logErr(res.error); return; }
  sessionId = res.data.session_id;
  setStepUI(true);
  stepProgInstr = res.data.instructions || [];
  showProgView('Step: ' + name, stepProgInstr);
  showRegisters(res.data.registers, res.data.pc, false);
  stepStatus.textContent = 'PC=' + res.data.pc + ' / ' + res.data.program_length;
  logStep('Session started. Click ⏭ Next to execute one instruction.');
});

btnStepNext.addEventListener('click', async () => {
  if (!sessionId) return;
  const res = await api('/api/step/next', { session_id: sessionId });
  if (!res.ok) { logErr(res.error); return; }
  showRegisters(res.data.registers, res.data.pc, true);
  logStep('→ ' + res.data.executed + '   PC=' + res.data.pc);
  stepStatus.textContent = res.data.done
    ? '✓ Halted'
    : 'PC=' + res.data.pc + ' / ' + stepProgInstr.length;
  if (res.data.done) {
    btnStepNext.disabled = true;
    logOk('Program halted. R1 = ' + res.data.registers[0]);
  }
});

btnStepReset.addEventListener('click', async () => {
  if (sessionId) {
    await api('/api/step/reset', { session_id: sessionId });
    sessionId = null;
  }
  setStepUI(false);
  stepStatus.textContent = '';
  progViewSec.style.display = 'none';
  clearRegisters();
  logStep('Step session reset.');
});

/* ---------------------------------------------------------------- */
/* PRINT / PRINTALL (via parse endpoint + print endpoint)           */
/* ---------------------------------------------------------------- */

// We expose PRINT and PRINTALL via the output log when the user
// types them in the editor. They are also triggered by the Gödel panel.
// For convenience we expose PRINTALL in the output on parse.

/* ---------------------------------------------------------------- */
/* ENCODE                                                            */
/* ---------------------------------------------------------------- */

document.getElementById('btnEncode').addEventListener('click', async () => {
  const name = document.getElementById('encodeProgName').value.trim();
  if (!name) { logErr('Enter a program name to encode.'); return; }
  logCmd('ENCODE ' + name);
  const res = await api('/api/encode', { source: editor.value, name });
  if (!res.ok) { logErr(res.error); return; }
  logOk('Gödel index of ' + name + ': #' + res.data.index);
});

/* ---------------------------------------------------------------- */
/* DECODE                                                            */
/* ---------------------------------------------------------------- */

document.getElementById('btnDecode').addEventListener('click', async () => {
  let raw = document.getElementById('decodeIndex').value.trim();
  if (raw.startsWith('#')) raw = raw.slice(1);
  if (!raw) { logErr('Enter a Gödel index to decode.'); return; }
  logCmd('DECODE #' + raw);
  const res = await api('/api/decode', { index: raw });
  if (!res.ok) { logErr(res.error); return; }
  logOk('Program at index #' + raw + ' (' + res.data.instructions.length + ' instructions):');
  res.data.instructions.forEach(l => log('  ' + l, 'log-info'));
});

/* ---------------------------------------------------------------- */
/* SIMULATE                                                          */
/* ---------------------------------------------------------------- */

document.getElementById('btnSimulate').addEventListener('click', async () => {
  let raw  = document.getElementById('simIndex').value.trim();
  const args = parseArgs(document.getElementById('simArgs').value);
  if (raw.startsWith('#')) raw = raw.slice(1);
  if (!raw) { logErr('Enter a Gödel index to simulate.'); return; }
  logCmd('SIMULATE #' + raw + '(' + args.join(', ') + ')');
  const res = await api('/api/simulate', { index: raw, args });
  if (!res.ok) { logErr(res.error); return; }
  const regStr = res.data.registers.map((v, i) => 'R' + (i+1) + '=' + v).join('  ');
  logOk(regStr);
});

/* ---------------------------------------------------------------- */
/* File loader (examples + saved)                                   */
/* ---------------------------------------------------------------- */

function populateOptgroup(group, names) {
  group.innerHTML = '';
  names.forEach(name => {
    const opt = document.createElement('option');
    opt.value = name;
    opt.textContent = name;
    group.appendChild(opt);
  });
}

async function refreshFileDropdown() {
  const [exRes, svRes] = await Promise.all([
    api('/api/examples'),
    api('/api/saved'),
  ]);
  if (exRes.ok) populateOptgroup(optExamples, exRes.data.examples);
  if (svRes.ok) populateOptgroup(optSaved,    svRes.data.saved);
}

async function loadFile(kind, name) {
  const endpoint = kind === 'example' ? '/api/examples/' : '/api/saved/';
  const res = await api(endpoint + encodeURIComponent(name));
  if (!res.ok) { logErr('Could not load file: ' + name); return; }
  editor.value = res.data.source;
  updateLineNumbers();
  log('Loaded: ' + name, 'log-info');
  saveFilename.value = name;
  // Auto-fill program name from first PROG definition
  const match = res.data.source.match(/PROG\s+(\w+)/i);
  if (match) progName.value = match[1];
}

fileSelect.addEventListener('change', async () => {
  const val = fileSelect.value;
  if (!val) return;
  // Determine which optgroup the selected option belongs to
  const opt = fileSelect.options[fileSelect.selectedIndex];
  const kind = opt.parentElement === optExamples ? 'example' : 'saved';
  await loadFile(kind, val);
  fileSelect.value = '';
});

refreshFileDropdown();

/* ---------------------------------------------------------------- */
/* Save                                                              */
/* ---------------------------------------------------------------- */

async function doSave(overwrite) {
  const name = saveFilename.value.trim();
  if (!name) { logErr('Enter a filename before saving.'); return; }
  const source = editor.value;
  logCmd('SAVE ' + name);
  const res = await api('/api/save', { name, source, overwrite });
  if (!res.ok) { logErr(res.error); return; }
  if (res.data.exists && !res.data.saved) {
    // Server says file exists and we did not force overwrite — ask user
    if (confirm('"' + name + '.txt" already exists. Overwrite?')) {
      await doSave(true);
    } else {
      log('Save cancelled.', 'log-info');
    }
    return;
  }
  logOk('Saved as ' + name + '.txt');
  await refreshFileDropdown(); // refresh so the new file appears in the dropdown
}

document.getElementById('btnSave').addEventListener('click', () => doSave(false));

/* ---------------------------------------------------------------- */
/* Help modal                                                        */
/* ---------------------------------------------------------------- */

const HELP_TEXT = `URM LANGUAGE REFERENCE
======================

All commands end with ;;

DEFINE A PROGRAM
----------------
PROG <name>:
  <body>
;;

INSTRUCTIONS (body = list of instructions)
------------------------------------------
  Z(n)         Zero register R(n)
  S(n)         Successor: R(n) := R(n) + 1
  T(m,n)       Transfer: R(n) := R(m)
  J(m,n,q)     Jump: if R(m) = R(n) goto instruction q

Lines may be numbered (e.g. "1: Z(1)") or not.

PROGRAM COMPOSITION
-------------------
  Relocation:
    PROG p: q[i1, i2 -> k] ;;
    Read q from registers i1,i2,... output to register k

  Concatenation:
    PROG p: q1; q2; q3 ;;
    Execute q1, then q2, then q3 sequentially

  Substitution (function composition f∘(g1,...,gk)):
    PROG p: f(g1, g2): n ;;
    n = arity of the g programs

  Primitive Recursion:
    PROG p: REC(f, g): n ;;
    f is n-ary (base case), g is (n+2)-ary (step)

  Minimalization (μ-operator):
    PROG p: MIN(f == 0): n ;;
    Finds smallest y such that f(x,y) = 0

EXECUTE
-------
  RUN name(a1, a2, ...);;        — show all registers
  EVAL name(a1, a2, ...);;       — show R1 only
  RUNBOUND name(a1,...) n;;      — run at most n steps

INSPECT
-------
  PRINT name;;                   — show compiled instructions
  PRINTALL;;                     — show all defined programs

FILE I/O (server-side)
----------------------
  SAVE name filename;;
  LOAD filename;;

GÖDEL ENCODING
--------------
  ENCODE name;;                  — compute Gödel index
  DECODE #number;;               — recover program from index
  SIMULATE #index(a1, a2,...);;  — run universal machine

COMMENTS
--------
  % this is a comment
  // this is also a comment

Note: keywords are case-insensitive (RUN = Run = run).
`;

document.getElementById('btnHelp').addEventListener('click', () => {
  helpContent.textContent = HELP_TEXT;
  helpModal.hidden = false;
});

document.getElementById('btnCloseHelp').addEventListener('click', () => {
  helpModal.hidden = true;
});

helpModal.addEventListener('click', e => {
  if (e.target === helpModal) helpModal.hidden = true;
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') helpModal.hidden = true;
});

/* ---------------------------------------------------------------- */
/* Tab key in editor                                                 */
/* ---------------------------------------------------------------- */

editor.addEventListener('keydown', e => {
  if (e.key === 'Tab') {
    e.preventDefault();
    const s = editor.selectionStart;
    const end = editor.selectionEnd;
    editor.value = editor.value.slice(0, s) + '  ' + editor.value.slice(end);
    editor.selectionStart = editor.selectionEnd = s + 2;
    updateLineNumbers();
  }
});

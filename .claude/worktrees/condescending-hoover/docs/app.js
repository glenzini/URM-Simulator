/* ================================================================
   URM Simulator — Frontend Application (GitHub Pages / static version)
   All computation runs in-browser via urm-engine.js.
   The api() function is a thin wrapper over URM.api() instead of fetch().
   ================================================================ */

/* ---------------------------------------------------------------- */
/* API — delegates to the JS engine (no server required)            */
/* ---------------------------------------------------------------- */

async function api(path, body) {
  return URM.api(path, body);
}

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
let sessionId      = null;
let lastRegisters  = null;
let stepProgInstr  = [];

/* ---------------------------------------------------------------- */
/* Utilities                                                         */
/* ---------------------------------------------------------------- */

function parseArgs(str) {
  if (!str.trim()) return [];
  return str.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n));
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

  let maxShow = 4;
  for (let i = regs.length - 1; i >= 0; i--) {
    if (regs[i] !== 0) { maxShow = Math.max(i + 2, 4); break; }
  }
  maxShow = Math.min(maxShow, regs.length);

  for (let i = 0; i < maxShow; i++) {
    const cell = document.createElement('div');
    cell.className = 'reg-cell';
    if (i === 0) cell.classList.add('output-reg');
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
    highlightProgViewLine(pc);
  }
}

function clearRegisters() {
  registersDiv.innerHTML = '<div class="reg-placeholder">Run a program to see register values.</div>';
  lastRegisters = null;
  pcDisplay.textContent = 'PC: —';
}

/* ---------------------------------------------------------------- */
/* Editor line numbers                                               */
/* ---------------------------------------------------------------- */

function updateLineNumbers() {
  const lines = editor.value.split('\n').length;
  lineNumbers.textContent = Array.from({ length: lines }, (_, i) => i + 1).join('\n');
}

editor.addEventListener('input', updateLineNumbers);
editor.addEventListener('scroll', () => { lineNumbers.scrollTop = editor.scrollTop; });
updateLineNumbers();

function highlightEditorLine(_pc) {}  // handled via prog-view panel

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
  items.forEach((li, i) => { li.classList.toggle('current-instr', i === pc - 1); });
  if (pc >= 1 && pc <= items.length) items[pc - 1].scrollIntoView({ block: 'nearest' });
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
  logOk(res.data.registers.map((v, i) => 'R' + (i+1) + '=' + v).join('  '));
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
  logOk(res.data.registers.map((v, i) => 'R' + (i+1) + '=' + v).join('  ') + '  [max ' + bound + ' steps]');
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
  logOk(res.data.registers.map((v, i) => 'R' + (i+1) + '=' + v).join('  '));
});

/* ---------------------------------------------------------------- */
/* File loader (examples from ./examples/*.txt + saved from localStorage) */
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
  const [exRes, svRes] = await Promise.all([api('/api/examples'), api('/api/saved')]);
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
  const match = res.data.source.match(/PROG\s+(\w+)/i);
  if (match) progName.value = match[1];
}

fileSelect.addEventListener('change', async () => {
  const val = fileSelect.value;
  if (!val) return;
  const opt  = fileSelect.options[fileSelect.selectedIndex];
  const kind = opt.parentElement === optExamples ? 'example' : 'saved';
  await loadFile(kind, val);
  fileSelect.value = '';
});

refreshFileDropdown();

/* ---------------------------------------------------------------- */
/* Save  (localStorage instead of server-side files)                */
/* ---------------------------------------------------------------- */

async function doSave(overwrite) {
  const name = saveFilename.value.trim();
  if (!name) { logErr('Enter a filename before saving.'); return; }
  logCmd('SAVE ' + name);
  const res = await api('/api/save', { name, source: editor.value, overwrite });
  if (!res.ok) { logErr(res.error); return; }
  if (res.data.exists && !res.data.saved) {
    if (confirm('"' + name + '" already exists. Overwrite?')) {
      await doSave(true);
    } else {
      log('Save cancelled.', 'log-info');
    }
    return;
  }
  logOk('Saved as "' + name + '" (browser local storage)');
  await refreshFileDropdown();
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

GÖDEL ENCODING
--------------
  ENCODE name;;                  — compute Gödel index
  DECODE #number;;               — recover program from index
  SIMULATE #index(a1, a2,...);;  — run universal machine

SAVE / LOAD (browser storage)
------------------------------
  Use the Save button to store programs in your browser.
  Use the Load file… dropdown to reload them.
  Note: saved programs are stored locally in this browser only.

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

document.getElementById('btnCloseHelp').addEventListener('click', () => { helpModal.hidden = true; });
helpModal.addEventListener('click', e => { if (e.target === helpModal) helpModal.hidden = true; });
document.addEventListener('keydown', e => { if (e.key === 'Escape') helpModal.hidden = true; });

/* ---------------------------------------------------------------- */
/* Tab key in editor                                                 */
/* ---------------------------------------------------------------- */

editor.addEventListener('keydown', e => {
  if (e.key === 'Tab') {
    e.preventDefault();
    const s = editor.selectionStart;
    editor.value = editor.value.slice(0, s) + '  ' + editor.value.slice(editor.selectionEnd);
    editor.selectionStart = editor.selectionEnd = s + 2;
    updateLineNumbers();
  }
});

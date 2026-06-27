/* ================================================================
   URM Engine — pure JavaScript (no server required)
   Ports the OCaml URM-Server backend logic to run in the browser.
   Covers: lexer, parser, machine, program composition, Gödel encoding.
   ================================================================ */

'use strict';

const URM = (() => {

// ==========================================================================
// Instructions
// ==========================================================================

const Zero = n        => ({ type: 'Zero', n });
const Succ = n        => ({ type: 'Succ', n });
const Tran = (m, n)   => ({ type: 'Tran', m, n });
const Jump = (m,n,q)  => ({ type: 'Jump', m, n, q });

function instrToString(i) {
  switch (i.type) {
    case 'Zero': return `Z(${i.n})`;
    case 'Succ': return `S(${i.n})`;
    case 'Tran': return `T(${i.m},${i.n})`;
    case 'Jump': return `J(${i.m},${i.n},${i.q})`;
    default:     return '?';
  }
}

// ==========================================================================
// Lexer
// ==========================================================================

function tokenize(source) {
  const tokens = [];
  let i = 0;
  const n = source.length;

  while (i < n) {
    const c = source[i];

    // Whitespace
    if (c === ' ' || c === '\t' || c === '\r' || c === '\n') { i++; continue; }

    // Line comments: // or %
    if (c === '/' && source[i+1] === '/') {
      while (i < n && source[i] !== '\n') i++;
      continue;
    }
    if (c === '%') {
      while (i < n && source[i] !== '\n') i++;
      continue;
    }

    // ==0  (must precede single '=')
    if (source[i]==='=' && source[i+1]==='=' && source[i+2]==='0') {
      tokens.push({ type: 'EQUALZERO' }); i += 3; continue;
    }

    // ->
    if (c === '-' && source[i+1] === '>') {
      tokens.push({ type: 'ARROW' }); i += 2; continue;
    }

    // ;;  (must precede single ';')
    if (c === ';' && source[i+1] === ';') {
      tokens.push({ type: 'DSEMI' }); i += 2; continue;
    }

    // #index
    if (c === '#') {
      let j = i + 1;
      while (j < n && source[j] >= '0' && source[j] <= '9') j++;
      if (j === i + 1) throw new Error('Expected digits after #');
      tokens.push({ type: 'INDEX', value: source.slice(i+1, j) });
      i = j; continue;
    }

    // Number
    if (c >= '0' && c <= '9') {
      let j = i;
      while (j < n && source[j] >= '0' && source[j] <= '9') j++;
      tokens.push({ type: 'NUMBER', value: parseInt(source.slice(i, j), 10) });
      i = j; continue;
    }

    // Word  →  keyword or name
    if (isLetter(c)) {
      let j = i;
      while (j < n && isNameChar(source[j])) j++;
      tokens.push(classifyWord(source.slice(i, j)));
      i = j; continue;
    }

    // Single-char symbols
    switch (c) {
      case ':': tokens.push({ type: 'COLON'    }); break;
      case ';': tokens.push({ type: 'SEMI'     }); break;
      case ',': tokens.push({ type: 'COMMA'    }); break;
      case '(': tokens.push({ type: 'LPAREN'   }); break;
      case ')': tokens.push({ type: 'RPAREN'   }); break;
      case '[': tokens.push({ type: 'LBRACKET' }); break;
      case ']': tokens.push({ type: 'RBRACKET' }); break;
      case '.': tokens.push({ type: 'DOT'      }); break;
      default:  throw new Error(`Unexpected character: '${c}'`);
    }
    i++;
  }

  tokens.push({ type: 'EOF' });
  return tokens;
}

function isLetter(c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}
function isNameChar(c) {
  return isLetter(c) || (c >= '0' && c <= '9') || c === "'" || c === '_';
}

// Case-insensitive keyword matching (matches the simulator's docs: "keywords are case-insensitive")
function classifyWord(word) {
  switch (word.toUpperCase()) {
    case 'ENCODE':   return { type: 'ENCODE'   };
    case 'EVAL':     return { type: 'EVAL'     };
    case 'DECODE':   return { type: 'DECODE'   };
    case 'EXIT':     return { type: 'EXIT'     };
    case 'HELP':     return { type: 'HELP'     };
    case 'LOAD':     return { type: 'LOAD'     };
    case 'MIN':      return { type: 'MU'       };
    case 'PRINT':    return { type: 'PRINT'    };
    case 'PRINTALL': return { type: 'PRINTALL' };
    case 'PROG':     return { type: 'PROG'     };
    case 'REC':      return { type: 'REC'      };
    case 'RUN':      return { type: 'RUN'      };
    case 'RUNBOUND': return { type: 'RUNBOUND' };
    case 'SAVE':     return { type: 'SAVE'     };
    case 'SIMULATE': return { type: 'SIMULATE' };
    case 'S':        return { type: 'SUCC'     };
    case 'T':        return { type: 'TRAN'     };
    case 'Z':        return { type: 'ZERO'     };
    case 'J':        return { type: 'JUMP'     };
    default:         return { type: 'NAME', value: word };
  }
}

// ==========================================================================
// Parser  →  { ok, tops } | { ok, error }
// Grammar mirrors URMParser.mly exactly.
// ==========================================================================

function parse(source) {
  let tokens;
  try { tokens = tokenize(source); }
  catch (e) { return { ok: false, error: 'Lexer: ' + e.message }; }

  let pos = 0;
  const peek  = ()     => tokens[pos];
  const peek2 = ()     => tokens[pos + 1];
  const at    = type   => tokens[pos].type === type;
  const consume = ()   => tokens[pos++];

  function expect(type) {
    if (!at(type)) {
      const t = tokens[pos];
      const got = t.type + (t.value !== undefined ? `(${t.value})` : '');
      throw new Error(`Expected ${type}, got ${got}`);
    }
    return consume();
  }

  function parseItems() {
    const items = [];
    while (!at('EOF')) {
      items.push(parseItem());
      expect('DSEMI');
    }
    return items;
  }

  function parseItem() {
    if (at('PROG')) return parseProgram();
    return parseExec();
  }

  function parseProgram() {
    expect('PROG');
    const name = expect('NAME').value;
    expect('COLON');
    return { tag: 'ProgramDef', name, body: parseBody() };
  }

  function parseBody() {
    // REC(f, g) : n
    if (at('REC')) {
      consume();
      expect('LPAREN');
      const f = expect('NAME').value;
      expect('COMMA');
      const g = expect('NAME').value;
      expect('RPAREN');
      expect('COLON');
      return { tag: 'BodyRec', f, g, n: expect('NUMBER').value };
    }

    // MIN(f ==0) : n
    if (at('MU')) {
      consume();
      expect('LPAREN');
      const f = expect('NAME').value;
      expect('EQUALZERO');
      expect('RPAREN');
      expect('COLON');
      return { tag: 'BodyMin', f, n: expect('NUMBER').value };
    }

    // Instructions: start with ZERO/SUCC/TRAN/JUMP or "NUMBER :"
    if (at('ZERO') || at('SUCC') || at('TRAN') || at('JUMP') ||
        (at('NUMBER') && peek2()?.type === 'COLON')) {
      return { tag: 'BodyInstrs', instrs: parseInstrs() };
    }

    // NAME-prefixed bodies
    if (at('NAME')) {
      const name = consume().value;

      if (at('LBRACKET')) {          // NAME [ numbers -> NUMBER ]
        consume();
        const inputs = parseNumbers();
        expect('ARROW');
        const output = expect('NUMBER').value;
        expect('RBRACKET');
        return { tag: 'BodyRelocate', name, inputs, output };
      }

      if (at('LPAREN')) {             // NAME ( namelist ) : NUMBER
        consume();
        const gnames = parseNameList();
        expect('RPAREN');
        expect('COLON');
        return { tag: 'BodySubstitute', fname: name, gnames, n: expect('NUMBER').value };
      }

      if (at('SEMI')) {               // NAME ; concatlist
        consume();
        return { tag: 'BodyConcatenate', fname: name, gnames: parseConcatList() };
      }

      // Bare NAME (single-element concatenation, no semi)
      return { tag: 'BodyConcatenate', fname: name, gnames: [] };
    }

    throw new Error(`Unexpected body token: ${peek().type}`);
  }

  function parseInstrs() {
    const instrs = [];
    for (;;) {
      if (at('ZERO') || at('SUCC') || at('TRAN') || at('JUMP')) {
        instrs.push(parseInstr());
      } else if (at('NUMBER') && peek2()?.type === 'COLON') {
        instrs.push(parseInstr());
      } else break;
    }
    if (instrs.length === 0) throw new Error('Empty instruction list');
    return instrs;
  }

  function parseInstr() {
    if (at('NUMBER') && peek2()?.type === 'COLON') { consume(); consume(); } // skip "N:"
    if (at('ZERO')) { consume(); expect('LPAREN'); const n=expect('NUMBER').value; expect('RPAREN'); return Zero(n); }
    if (at('SUCC')) { consume(); expect('LPAREN'); const n=expect('NUMBER').value; expect('RPAREN'); return Succ(n); }
    if (at('TRAN')) { consume(); expect('LPAREN'); const m=expect('NUMBER').value; expect('COMMA'); const n=expect('NUMBER').value; expect('RPAREN'); return Tran(m,n); }
    if (at('JUMP')) { consume(); expect('LPAREN'); const m=expect('NUMBER').value; expect('COMMA'); const n=expect('NUMBER').value; expect('COMMA'); const q=expect('NUMBER').value; expect('RPAREN'); return Jump(m,n,q); }
    throw new Error(`Expected instruction keyword, got ${peek().type}`);
  }

  // concatlist: NAME (SEMI NAME)* | empty
  function parseConcatList() {
    if (!at('NAME')) return [];
    const name = consume().value;
    if (at('SEMI')) { consume(); return [name, ...parseConcatList()]; }
    return [name];
  }

  function parseNumbers() {
    const r = [];
    while (at('NUMBER')) { r.push(consume().value); if (!at('COMMA')) break; consume(); }
    return r;
  }

  function parseNameList() {
    const r = [];
    while (at('NAME')) { r.push(consume().value); if (!at('COMMA')) break; consume(); }
    return r;
  }

  function parseExec() {
    if (at('RUN'))      { consume(); const name=expect('NAME').value; expect('LPAREN'); const args=parseNumbers(); expect('RPAREN'); return {tag:'Run',name,args}; }
    if (at('RUNBOUND')) { consume(); const name=expect('NAME').value; expect('LPAREN'); const args=parseNumbers(); expect('RPAREN'); const bound=expect('NUMBER').value; return {tag:'RunBound',name,args,bound}; }
    if (at('EVAL'))     { consume(); const name=expect('NAME').value; expect('LPAREN'); const args=parseNumbers(); expect('RPAREN'); return {tag:'Eval',name,args}; }
    if (at('PRINT'))    { consume(); return {tag:'Print', name:expect('NAME').value}; }
    if (at('PRINTALL')) { consume(); return {tag:'PrintAll'}; }
    if (at('ENCODE'))   { consume(); return {tag:'Encode', name:expect('NAME').value}; }
    if (at('DECODE'))   { consume(); return {tag:'Decode', index:expect('INDEX').value}; }
    if (at('SIMULATE')) { consume(); const index=expect('INDEX').value; expect('LPAREN'); const args=parseNumbers(); expect('RPAREN'); return {tag:'Simulate',index,args}; }
    if (at('SAVE'))     { consume(); const name=expect('NAME').value; return {tag:'Save',name,filename:expect('NAME').value}; }
    if (at('LOAD'))     { consume(); return {tag:'Load', name:expect('NAME').value}; }
    if (at('HELP'))     { consume(); return {tag:'PrintHelp'}; }
    if (at('EXIT'))     { consume(); return {tag:'Exit'}; }
    throw new Error(`Unexpected exec token: ${peek().type}${peek().value !== undefined ? `(${peek().value})` : ''}`);
  }

  try {
    const tops = parseItems();
    return { ok: true, tops };
  } catch (e) {
    return { ok: false, error: 'Parse error: ' + e.message };
  }
}

// ==========================================================================
// Machine  (URM_machine.ml)
// ==========================================================================

function getMax(list) {
  let m = 0;
  for (const x of list) if (x > m) m = x;
  return m;
}

function rho(prog) {
  let max = 0;
  for (const i of prog) {
    let m = 0;
    switch (i.type) {
      case 'Zero': m = i.n; break;
      case 'Succ': m = i.n; break;
      case 'Tran': m = Math.max(i.m, i.n); break;
      case 'Jump': m = Math.max(i.m, i.n); break;
    }
    if (m > max) max = m;
  }
  return max;
}

function makeMachine(prog, args) {
  const size = Math.max(rho(prog), args.length);
  const rs = new Array(size).fill(0);
  for (let k = 0; k < args.length; k++) rs[k] = args[k];
  return { rs, pc: 1 };
}

function execInstr(instr, m) {
  m.pc++;
  const rs = m.rs;
  switch (instr.type) {
    case 'Zero': rs[instr.n-1] = 0; break;
    case 'Succ': rs[instr.n-1]++; break;
    case 'Tran': rs[instr.n-1] = rs[instr.m-1] ?? 0; break;
    case 'Jump': if ((rs[instr.m-1] ?? 0) === (rs[instr.n-1] ?? 0)) m.pc = instr.q; break;
  }
}

const MAX_STEPS = 10_000_000;

function run(prog, args) {
  if (!prog.length) return new Array(args.length).fill(0).map((_, k) => args[k] ?? 0);
  const m = makeMachine(prog, args);
  let steps = 0;
  while (m.pc <= prog.length) {
    if (++steps > MAX_STEPS) throw new Error('Execution limit reached (possible infinite loop). Use RUNBOUND to cap steps.');
    execInstr(prog[m.pc-1], m);
  }
  return m.rs;
}

function runbound(prog, args, bound) {
  if (!prog.length) return new Array(args.length).fill(0).map((_, k) => args[k] ?? 0);
  const m = makeMachine(prog, args);
  let count = 0;
  while (m.pc <= prog.length && count < bound) { execInstr(prog[m.pc-1], m); count++; }
  return m.rs;
}

function evalProg(prog, args) { return run(prog, args)[0] ?? 0; }

// ==========================================================================
// Program operations  (URM_machine.ml — compositional part)
// ==========================================================================

function standardize(prog) {
  const l = prog.length;
  return prog.map(i => i.type === 'Jump' ? Jump(i.m, i.n, i.q >= l+1 ? l+1 : i.q) : i);
}

function reindex(s, prog) {
  return standardize(prog).map(i => i.type === 'Jump' ? Jump(i.m, i.n, s + i.q) : i);
}

function concatenate(p, q) {
  if (!p.length) return standardize(q);
  if (!q.length) return standardize(p);
  return [...standardize(p), ...reindex(p.length, q)];
}

// concatenate' — p already in standard form
function concatenate_(p, q) {
  if (!q.length) return p;
  return [...p, ...reindex(p.length, q)];
}

function concatenateList(progs) {
  return progs.reduceRight((acc, p) => concatenate(p, acc), []);
}

function listinit(a, n)  { return Array.from({ length: Math.max(0,n) }, (_, k) => a+k); }
function listOfTrans(m, n, k)  { return Array.from({ length: Math.max(0,k) }, (_, i) => Tran(m+i, n+i)); }
function listOfTrans_(ris)     { return ris.map((l, i) => Tran(l, i+1)); }
function listOfZeros(m, k)     { return Array.from({ length: Math.max(0,k) }, (_, i) => Zero(m+i)); }

function relocate(prog, ris, ro) {
  const k = rho(prog);
  const n = ris.length;
  const ts   = listOfTrans_(ris);
  const zs   = listOfZeros(n+1, k-n > 0 ? k-n-1 : 0);
  const htp  = concatenate([...ts, ...zs], prog);
  return [...htp, Tran(1, ro)];
}

function listOfGs(glist, m, n) {
  const rlist = listinit(m, n);
  return [].concat(...glist.map((g, i) => relocate(g, rlist, m+n+i)));
}

function compose(f, glist, n) {
  const k = glist.length;
  const m = getMax([n, k, rho(f), ...glist.map(rho)]);
  return concatenateList([
    listOfTrans(1, m+1, n),
    listOfGs(glist, m+1, n),
    relocate(f, listinit(m+n+1, k), 1),
  ]);
}

function recursion(f, g, n) {
  const m   = getMax([n+2, rho(f), rho(g)]);
  const t   = m + n;
  const ts  = listOfTrans(1, m+1, n+1);
  const rf  = n > 0 ? relocate(f, listinit(1,n), t+3) : relocate(f, [1], t+3);
  const tsrf = concatenate(ts, rf);
  const q   = tsrf.length + 1;
  const rg  = relocate(g, [...listinit(m+1,n), t+2, t+3], t+3);
  const tsrf_jump = [...tsrf, Jump(t+1, t+2, q + rg.length + 3)];
  const tsrfrg    = concatenate_(tsrf_jump, rg);
  return [...tsrfrg, Succ(t+2), Jump(1,1,q), Tran(t+3,1)];
}

function minimalization(f, n) {
  const m    = getMax([n+1, rho(f)]);
  const ts   = listOfTrans(1, m+1, n);
  const rf   = relocate(f, listinit(m+1, n+1), 1);
  const p    = n + 1;
  const q    = n + rf.length + 4;
  const tsrf = concatenate(ts, rf);
  return [...tsrf, Jump(1, m+n+2, q), Succ(m+n+1), Jump(1,1,p), Tran(m+n+1,1)];
}

// ==========================================================================
// Gödel encoding  (URM_counting_programs.ml — using JavaScript BigInt)
// ==========================================================================

const B2 = 2n;
function twoexp(i) { return B2 ** i; }

function findtwoexp(n) {           // 2-adic valuation of n (BigInt)
  let i = 0n;
  while (n % B2 === 0n) { n /= B2; i++; }
  return i;
}

function intlog(n) {               // floor(log2(n)), BigInt
  let k = 0n;
  while (twoexp(k) <= n) k++;
  return k - 1n;
}

function encodePair(m, n) { return twoexp(m) * (2n*n + 1n) - 1n; }

function decodeFirstOfPair(n)  { return findtwoexp(n + 1n); }
function decodeSecondOfPair(n) {
  const v = decodeFirstOfPair(n);
  return ((n + 1n) / twoexp(v) - 1n) / 2n;
}

function encodeTriple(n, m, q) { return encodePair(encodePair(n-1n, m-1n), q-1n); }
function decodeFirstOfTriple(n)  { return decodeFirstOfPair(decodeFirstOfPair(n)) + 1n; }
function decodeSecondOfTriple(n) { return decodeSecondOfPair(decodeFirstOfPair(n)) + 1n; }
function decodeThirdOfTriple(n)  { return decodeSecondOfPair(n) + 1n; }

function encodeList(ln) {     // ln: array of BigInt
  function aux(lna, encode, exp, c) {
    if (lna.length === 1) return encode + twoexp(lna[0] + exp + c) - 1n;
    const h = lna[0];
    const exp_ = exp + h;
    return aux(lna.slice(1), encode + twoexp(exp_ + c), exp_, c + 1n);
  }
  return aux(ln, 0n, 0n, 0n);
}

// Iterative listofBs: bit positions of m (BigInt) in decreasing order
function listofBs(m) {
  const r = [];
  let n = m;
  for (;;) {
    const k = intlog(n);
    const t = twoexp(k);
    r.push(k);
    if (t === n) break;
    n -= t;
  }
  return r;
}

// Iterative listofAs: converts B-positions to A-differences
function listofAs(bs) {
  if (bs.length === 1) return [bs[0]];
  const r = [bs[bs.length - 1]];
  for (let i = bs.length - 2; i >= 0; i--) r.push(bs[i] - bs[i+1] - 1n);
  return r;
}

function decodeList(m) { return listofAs(listofBs(m + 1n)); }

function beta(instr) {
  switch (instr.type) {
    case 'Zero': return 4n * BigInt(instr.n - 1);
    case 'Succ': return 4n * BigInt(instr.n - 1) + 1n;
    case 'Tran': return 4n * encodePair(BigInt(instr.m-1), BigInt(instr.n-1)) + 2n;
    case 'Jump': return 4n * encodeTriple(BigInt(instr.m), BigInt(instr.n), BigInt(instr.q)) + 3n;
  }
}

function ubeta(x) {
  const u = x / 4n;
  switch (Number(x % 4n)) {
    case 0: return Zero(Number(u) + 1);
    case 1: return Succ(Number(u) + 1);
    case 2: return Tran(Number(decodeFirstOfPair(u)) + 1, Number(decodeSecondOfPair(u)) + 1);
    case 3: return Jump(Number(decodeFirstOfTriple(u)), Number(decodeSecondOfTriple(u)), Number(decodeThirdOfTriple(u)));
  }
}

function yota(prog)  { return encodeList(prog.map(beta)); }
function uyota(n)    { return decodeList(n).map(ubeta); }

// ==========================================================================
// Environment: parse source → Map<name, program>
// ==========================================================================

function buildEnv(source) {
  const parsed = parse(source);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const env = new Map();
  for (const top of parsed.tops) {
    if (top.tag !== 'ProgramDef') continue;
    try {
      env.set(top.name, standardize(interpretBody(env, top.body)));
    } catch (e) {
      return { ok: false, error: e.message };
    }
  }
  return { ok: true, env };
}

function findProgram(env, name) {
  if (!env.has(name)) throw new Error('Program not found: ' + name);
  return env.get(name);
}

function interpretBody(env, body) {
  switch (body.tag) {
    case 'BodyInstrs':
      return body.instrs;
    case 'BodyRelocate':
      return relocate(findProgram(env, body.name), body.inputs, body.output);
    case 'BodyConcatenate':
      return concatenateList([findProgram(env, body.fname), ...body.gnames.map(n => findProgram(env, n))]);
    case 'BodySubstitute':
      return compose(findProgram(env, body.fname), body.gnames.map(n => findProgram(env, n)), body.n);
    case 'BodyRec':
      return recursion(findProgram(env, body.f), findProgram(env, body.g), body.n);
    case 'BodyMin':
      return minimalization(findProgram(env, body.f), body.n);
    default:
      throw new Error('Unknown body tag: ' + body.tag);
  }
}

// ==========================================================================
// Step-by-step sessions (in-memory; replaces server-side session table)
// ==========================================================================

const _sessions = new Map();
let _sid = 0;

function stepStart(source, name, args) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  const prog    = r.env.get(name);
  const machine = makeMachine(prog, args);
  const id      = 'sid_' + (_sid++);
  _sessions.set(id, { prog, machine });
  return { ok: true, data: {
    session_id:     id,
    registers:      [...machine.rs],
    pc:             machine.pc,
    done:           machine.pc > prog.length,
    program_length: prog.length,
    instructions:   prog.map((i, k) => (k+1) + ': ' + instrToString(i)),
  }};
}

function stepNext(session_id) {
  const s = _sessions.get(session_id);
  if (!s) return { ok: false, error: 'Session not found' };
  const { prog, machine } = s;
  if (machine.pc > prog.length)
    return { ok: true, data: { registers: [...machine.rs], pc: machine.pc, done: true, executed: '(halted)' } };
  const executed = instrToString(prog[machine.pc - 1]);
  execInstr(prog[machine.pc - 1], machine);
  return { ok: true, data: {
    registers: [...machine.rs],
    pc:        machine.pc,
    done:      machine.pc > prog.length,
    executed,
  }};
}

function stepReset(session_id) {
  _sessions.delete(session_id);
  return { ok: true, data: {} };
}

// ==========================================================================
// Saved-file storage — uses localStorage instead of server filesystem
// ==========================================================================

const LS_LIST = 'urm_saved_names';
const LS_PFX  = 'urm_saved_';

function getSavedNames() {
  try { return JSON.parse(localStorage.getItem(LS_LIST) || '[]'); } catch { return []; }
}
function setSavedNames(names) { localStorage.setItem(LS_LIST, JSON.stringify(names)); }

function sanitize(name) { return name.replace(/[^a-zA-Z0-9\-_.]/g, ''); }

// ==========================================================================
// API handlers — same shape as the OCaml server responses
// ==========================================================================

const EXAMPLES = ['add', 'cutland_12', 'exp', 'sum_prod', 'test', 'two'];

function handleExamples()       { return { ok: true, data: { examples: EXAMPLES } }; }

function handleSaved()          { return { ok: true, data: { saved: getSavedNames() } }; }

function handleSavedGet(name) {
  const src = localStorage.getItem(LS_PFX + name);
  return src !== null
    ? { ok: true,  data: { source: src, name } }
    : { ok: false, error: 'Saved file not found: ' + name };
}

function handleSave({ name, source, overwrite }) {
  const safe = sanitize(name);
  if (!safe) return { ok: false, error: 'Invalid filename' };
  const names  = getSavedNames();
  const exists = names.includes(safe);
  if (exists && !overwrite)
    return { ok: true, data: { saved: false, exists: true, name: safe } };
  localStorage.setItem(LS_PFX + safe, source);
  if (!exists) { names.push(safe); names.sort(); setSavedNames(names); }
  return { ok: true, data: { saved: true, exists: false, name: safe } };
}

function handleRun({ source, name, args }) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  try   { return { ok: true,  data: { registers: [...run(r.env.get(name), args)] } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function handleEval({ source, name, args }) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  try   { return { ok: true,  data: { result: evalProg(r.env.get(name), args) } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function handleRunbound({ source, name, args, bound }) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  try   { return { ok: true,  data: { registers: [...runbound(r.env.get(name), args, bound)] } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function handlePrint({ source, name }) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  const prog = r.env.get(name);
  return { ok: true, data: { instructions: prog.map((i,k) => (k+1) + ': ' + instrToString(i)) } };
}

function handleEncode({ source, name }) {
  const r = buildEnv(source);
  if (!r.ok) return { ok: false, error: r.error };
  if (!r.env.has(name)) return { ok: false, error: 'Program not found: ' + name };
  try   { return { ok: true,  data: { index: yota(r.env.get(name)).toString() } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function handleDecode({ index }) {
  try   { return { ok: true,  data: { instructions: uyota(BigInt(index)).map((i,k) => (k+1) + ': ' + instrToString(i)) } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function handleSimulate({ index, args }) {
  try   { return { ok: true,  data: { registers: [...run(uyota(BigInt(index)), args)] } }; }
  catch (e) { return { ok: false, error: e.message }; }
}

// ==========================================================================
// Public interface — drop-in replacement for the fetch-based `api()` in app.js
// ==========================================================================

return {
  async api(path, body) {
    if (path === '/api/examples')     return handleExamples();
    if (path === '/api/saved')        return handleSaved();
    if (path === '/api/save')         return handleSave(body);

    if (path.startsWith('/api/examples/')) {
      const name = decodeURIComponent(path.slice('/api/examples/'.length));
      // Fetch from ./examples/ — works on GitHub Pages (static files)
      try {
        const resp = await fetch(`./examples/${name}.txt`);
        if (!resp.ok) return { ok: false, error: 'Example not found: ' + name };
        return { ok: true, data: { source: await resp.text(), name } };
      } catch (e) { return { ok: false, error: 'Failed to load example: ' + e.message }; }
    }

    if (path.startsWith('/api/saved/')) {
      return handleSavedGet(decodeURIComponent(path.slice('/api/saved/'.length)));
    }

    if (path === '/api/run')          return handleRun(body);
    if (path === '/api/eval')         return handleEval(body);
    if (path === '/api/runbound')     return handleRunbound(body);
    if (path === '/api/print')        return handlePrint(body);
    if (path === '/api/encode')       return handleEncode(body);
    if (path === '/api/decode')       return handleDecode(body);
    if (path === '/api/simulate')     return handleSimulate(body);
    if (path === '/api/step/start')   return stepStart(body.source, body.name, body.args);
    if (path === '/api/step/next')    return stepNext(body.session_id);
    if (path === '/api/step/reset')   return stepReset(body.session_id);

    return { ok: false, error: 'Unknown endpoint: ' + path };
  },
};

})(); // end URM module

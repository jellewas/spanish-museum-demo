// Spanish pronunciation engine — JS port of Core/Sources/PronunciationCore.
// Neutral Latin-American Spanish (seseo, yeismo). Deterministic, offline.
// Works in Node (module.exports) and the browser (window.Pronouncer).
(function (root) {
  "use strict";

  const STRONG = new Set(["a", "e", "o", "á", "é", "ó"]);
  const WEAK = new Set(["i", "u", "ü", "í", "ú"]);
  const ACCENTED = new Set(["á", "é", "í", "ó", "ú"]);
  const isVowelChar = (c) => STRONG.has(c) || WEAK.has(c);

  // --- Tokenize into units (digraphs ch/ll/rr and silent-u onsets qu/gu/gü are single units) ---
  function tokenize(chars) {
    const units = [];
    let i = 0;
    const n = chars.length;
    const at = (k) => (k >= 0 && k < n ? chars[k] : null);

    while (i < n) {
      const c = chars[i], next = at(i + 1), after = at(i + 2);

      if (c === "q" && next === "u") { units.push(cons("qu")); i += 2; continue; }
      if (c === "g" && next === "u" && (after === "e" || after === "i" || after === "é" || after === "í")) {
        units.push(cons("gu")); i += 2; continue;
      }
      if (c === "g" && next === "ü") { units.push(cons("gü")); i += 2; continue; }

      if (c === "c" && next === "h") { units.push(cons("ch")); i += 2; continue; }
      if (c === "l" && next === "l") { units.push(cons("ll")); i += 2; continue; }
      if (c === "r" && next === "r") { units.push(cons("rr")); i += 2; continue; }

      if (c === "y") {
        const isVowelHere = next === null || !isVowelChar(next);
        units.push(isVowelHere ? vowel("y", true, false) : cons("y"));
        i += 1; continue;
      }

      if (isVowelChar(c)) units.push(vowel(c, WEAK.has(c), ACCENTED.has(c)));
      else units.push(cons(c));
      i += 1;
    }
    return units;
  }
  const cons = (orth) => ({ orth, isVowel: false, isWeak: false, isAccented: false });
  const vowel = (orth, isWeak, isAccented) => ({ orth, isVowel: true, isWeak, isAccented });

  // --- Group vowels into nuclei (diphthong vs hiatus) ---
  function groupNuclei(units) {
    const isWeakUnaccented = (u) => u.isVowel && u.isWeak && !u.isAccented;
    const nuclei = [];
    let current = [], prev = null;
    units.forEach((u, idx) => {
      if (!u.isVowel) { if (current.length) { nuclei.push(current); current = []; } prev = null; return; }
      if (prev && current.length < 3 && (isWeakUnaccented(prev) || isWeakUnaccented(u))) {
        current.push(idx);
      } else {
        if (current.length) nuclei.push(current);
        current = [idx];
      }
      prev = u;
    });
    if (current.length) nuclei.push(current);
    return nuclei;
  }

  function isValidOnsetCluster(a, b) {
    if (b !== "l" && b !== "r") return false;
    if (b === "r") return ["p", "b", "f", "g", "c", "k", "t", "d"].includes(a);
    return ["p", "b", "f", "g", "c", "k"].includes(a);
  }

  function assignConsonants(units, nuclei) {
    const syllables = nuclei.map((nuc) => ({ unitIndices: nuc.slice(), nucleus: nuc.slice() }));

    if (nuclei.length && nuclei[0].length) {
      const firstVowel = nuclei[0][0];
      const leading = range(0, firstVowel);
      syllables[0].unitIndices = leading.concat(syllables[0].unitIndices);
    }

    for (let i = 0; i < nuclei.length - 1; i++) {
      const leftEnd = nuclei[i][nuclei[i].length - 1];
      const rightStart = nuclei[i + 1][0];
      const consonants = range(leftEnd + 1, rightStart);
      if (!consonants.length) continue;
      const k = consonants.length;
      let onsetCount = 1;
      if (k >= 2 && isValidOnsetCluster(units[consonants[k - 2]].orth, units[consonants[k - 1]].orth)) {
        onsetCount = 2;
      }
      const codaCount = k - onsetCount;
      const coda = consonants.slice(0, codaCount);
      const onset = consonants.slice(codaCount);
      syllables[i].unitIndices = syllables[i].unitIndices.concat(coda);
      syllables[i + 1].unitIndices = onset.concat(syllables[i + 1].unitIndices);
    }

    const lastNuc = nuclei[nuclei.length - 1];
    const lastVowel = lastNuc[lastNuc.length - 1];
    if (lastVowel + 1 < units.length) {
      syllables[syllables.length - 1].unitIndices =
        syllables[syllables.length - 1].unitIndices.concat(range(lastVowel + 1, units.length));
    }

    syllables.forEach((s) => s.unitIndices.sort((a, b) => a - b));
    return syllables;
  }

  function stressedSyllable(word, units, syllables) {
    for (let s = 0; s < syllables.length; s++) {
      if (syllables[s].nucleus.some((idx) => units[idx].isAccented)) return s;
    }
    if (syllables.length <= 1) return 0;
    const last = word[word.length - 1];
    if (isVowelChar(last) || last === "n" || last === "s") return syllables.length - 2;
    return syllables.length - 1;
  }

  function renderIPA(units, syllables, stressIndex) {
    const parts = syllables.map((syl) => {
      const nucleusSet = new Set(syl.nucleus);
      let s = "";
      for (const idx of syl.unitIndices) {
        const u = units[idx];
        if (u.isVowel && nucleusSet.has(idx)) s += vowelIPA(units, syl.nucleus, idx);
        else if (!u.isVowel) s += consonantIPA(u.orth, idx, units);
      }
      return s;
    });
    let out = "";
    parts.forEach((p, i) => {
      if (i === 0) out += (i === stressIndex ? "ˈ" : "") + p;
      else out += (i === stressIndex ? "ˈ" : ".") + p;
    });
    return out;
  }

  function vowelIPA(units, nucleus, index) {
    const base = (u) => {
      switch (u.orth) {
        case "a": case "á": return "a";
        case "e": case "é": return "e";
        case "i": case "í": case "y": return "i";
        case "o": case "ó": return "o";
        case "u": case "ú": case "ü": return "u";
        default: return u.orth;
      }
    };
    let mainIdx = nucleus.find((idx) => units[idx].isAccented);
    if (mainIdx === undefined) mainIdx = nucleus.find((idx) => !units[idx].isWeak);
    if (mainIdx === undefined) mainIdx = nucleus[nucleus.length - 1];

    const u = units[index];
    if (index === mainIdx) return base(u);
    const isGlideU = base(u) === "u";
    if (index < mainIdx) return isGlideU ? "w" : "j";       // on-glide
    return (isGlideU ? "u" : "i") + "̯";               // off-glide
  }

  function consonantIPA(orth, index, units) {
    const nextVowelChar = () => {
      const nx = units[index + 1];
      return nx && nx.isVowel ? nx.orth[0] : null;
    };
    const prevOrth = index > 0 ? units[index - 1].orth : null;
    const soft = (nv) => nv === "e" || nv === "é" || nv === "i" || nv === "í";

    switch (orth) {
      case "b": case "v": return "b";
      case "c": return soft(nextVowelChar()) ? "s" : "k";
      case "ch": return "tʃ";
      case "d": return "d";
      case "f": return "f";
      case "g": return soft(nextVowelChar()) ? "x" : "ɡ";
      case "gu": return "ɡ";
      case "gü": return "ɡw";
      case "h": return "";
      case "j": return "x";
      case "k": return "k";
      case "l": return "l";
      case "ll": return "ʝ";
      case "m": return "m";
      case "n": return "n";
      case "ñ": return "ɲ";
      case "p": return "p";
      case "qu": return "k";
      case "r":
        if (index === 0) return "r";
        if (prevOrth === "n" || prevOrth === "l" || prevOrth === "s") return "r";
        return "ɾ";
      case "rr": return "r";
      case "s": return "s";
      case "t": return "t";
      case "w": return "w";
      case "x": return "ks";
      case "y": return "ʝ";
      case "z": return "s";
      default: return orth;
    }
  }

  function analyze(rawWord) {
    const word = rawWord.toLowerCase();
    const units = tokenize(Array.from(word));
    if (!units.length) return { ipa: "", syllables: [], stressIndex: 0 };
    const nuclei = groupNuclei(units);
    if (!nuclei.length) {
      const ipa = units.map((u, i) => consonantIPA(u.orth, i, units)).join("");
      return { ipa, syllables: [word], stressIndex: 0 };
    }
    const syllables = assignConsonants(units, nuclei);
    const stressIndex = stressedSyllable(word, units, syllables);
    const ipa = renderIPA(units, syllables, stressIndex);
    const orthSyllables = syllables.map((s) => s.unitIndices.map((i) => units[i].orth).join(""));
    return { ipa, syllables: orthSyllables, stressIndex };
  }

  // --- Dutch coaching ---
  function tips(rawWord, stressedSyllableText) {
    const w = rawWord.toLowerCase();
    const has = (s) => w.includes(s);
    const hasCeCi = () => ["ce", "ci", "cé", "cí"].some(has);
    const hasGeGi = () => ["ge", "gi", "gé", "gí"].some(has);

    const features = [];
    const add = (tip) => { if (features.length < 2) features.push(tip); };

    if (has("j") || hasGeGi()) add("De Spaanse 'j' en de 'g' (voor e/i) klink je als de Nederlandse harde g, zoals in 'lachen'.");
    if (has("z") || hasCeCi()) add("'z', 'ce' en 'ci' spreek je uit als een gewone 's' — niet als de Engelse 'th'.");
    if (has("rr")) add("Rol de dubbele 'rr' met een trillende tongpunt, langer dan een Nederlandse r.");
    if (has("ll")) add("'ll' klinkt als de Nederlandse 'j', zoals in 'ja'.");
    if (has("ñ")) add("'ñ' spreek je uit als 'nj', zoals in 'oranje'.");
    if (has("v")) add("De 'v' klinkt in het Spaans als een 'b'.");
    if (has("qu")) add("'qu' klink je als 'k'; de 'u' blijft stil.");
    if (hasSilentH(w)) add("De 'h' is stom — die spreek je niet uit.");

    if (!features.length) features.push("Spreek elke klinker helder en kort uit; vermijd de Nederlandse stomme e (de 'sjwa').");
    return features.concat(["Klemtoon op '" + stressedSyllableText + "'."]);
  }

  function hasSilentH(w) {
    const a = Array.from(w);
    for (let i = 0; i < a.length; i++) {
      if (a[i] === "h" && (i === 0 || a[i - 1] !== "c")) return true;
    }
    return false;
  }

  function pronounce(word) {
    const trimmed = String(word).trim();
    const r = analyze(trimmed);
    const stressed = r.syllables[r.stressIndex] !== undefined ? r.syllables[r.stressIndex] : trimmed;
    return {
      word: trimmed,
      ipa: r.ipa,
      syllables: r.syllables,
      stressIndex: r.stressIndex,
      tips: tips(trimmed, stressed),
    };
  }

  function range(a, b) { const out = []; for (let i = a; i < b; i++) out.push(i); return out; }

  const Pronouncer = { pronounce, analyze };
  if (typeof module !== "undefined" && module.exports) module.exports = Pronouncer;
  else root.Pronouncer = Pronouncer;
})(typeof window !== "undefined" ? window : this);

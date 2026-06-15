// Verifies the JS engine against the same cases as the Swift verifier.
const P = require("./engine.js");
let fail = 0;
const eq = (label, got, want) => { if (got !== want) { fail++; console.log(`FAIL ${label}: got ${got}  want ${want}`); } };
const ok = (label, cond) => { if (!cond) { fail++; console.log(`FAIL ${label}`); } };

const ipa = [
  ["museo", "muˈse.o"], ["jamón", "xaˈmon"], ["gracias", "ˈɡɾa.sjas"],
  ["niño", "ˈni.ɲo"], ["cerveza", "seɾˈbe.sa"], ["llave", "ˈʝa.be"],
  ["guitarra", "ɡiˈta.ra"], ["perro", "ˈpe.ro"], ["pero", "ˈpe.ɾo"],
  ["español", "es.paˈɲol"], ["ciudad", "sjuˈdad"], ["corazón", "ko.ɾaˈson"],
  ["hola", "ˈo.la"], ["queso", "ˈke.so"], ["agua", "ˈa.ɡwa"],
  ["buenos", "ˈbwe.nos"], ["día", "ˈdi.a"],
];
for (const [w, want] of ipa) eq(`IPA ${w}`, P.pronounce(w).ipa, want);

eq("syll museo", P.pronounce("museo").syllables.join("-"), "mu-se-o");
eq("syll español", P.pronounce("español").syllables.join("-"), "es-pa-ñol");
eq("syll guitarra", P.pronounce("guitarra").syllables.join("-"), "gui-ta-rra");
eq("stress jamón", String(P.pronounce("jamón").stressIndex), "1");
eq("stress español", String(P.pronounce("español").stressIndex), "2");

const cerveza = P.pronounce("cerveza").tips;
ok("seseo tip", cerveza.some((t) => t.includes("gewone 's'")));
ok("v→b tip", cerveza.some((t) => t.includes("als een 'b'")));
ok("stress last", cerveza[cerveza.length - 1].startsWith("Klemtoon op"));
ok("jota tip", P.pronounce("jamón").tips.some((t) => t.includes("harde g")));
ok("trill tip", P.pronounce("guitarra").tips.some((t) => t.includes("trillende tongpunt")));
for (const w of ["cerveza", "guitarra", "jamón", "español", "museo"]) ok(`≤3 tips ${w}`, P.pronounce(w).tips.length <= 3);

console.log(fail === 0 ? `ALL PASS (${ipa.length} IPA + syllable/stress/coaching checks)` : `${fail} FAILURE(S)`);
process.exit(fail === 0 ? 0 : 1);

// Spanish -> Dutch glossary for the demo. Offline, curated.
// Covers every word in the sample museum panel, plus common travel/museum
// vocabulary. Deterministic lookup with light morphology (plural -> singular).
// Not a full MT system: unknown words return null and the UI says so.
(function (root) {
  "use strict";

  // Lemma -> Dutch gloss. Slash = alternatives; parens = clarification.
  const DICT = {
    // --- articles / determiners / pronouns ---
    el: "de/het", la: "de", los: "de", las: "de",
    un: "een", una: "een", unos: "enkele", unas: "enkele",
    del: "van de", al: "naar de/aan de",
    este: "deze/dit", esta: "deze", esto: "dit",
    ese: "die/dat", esa: "die", eso: "dat",
    su: "zijn/haar", sus: "zijn/haar (mv.)",
    mi: "mijn", tu: "jouw", nuestro: "ons/onze",
    se: "zich", le: "hem/haar (aan)", les: "hun (aan)",
    lo: "het", me: "mij", te: "jou", nos: "ons",
    que: "die/dat", quien: "wie", cual: "welke",

    // --- prepositions / conjunctions / adverbs ---
    de: "van", en: "in/op", a: "naar/aan", con: "met", sin: "zonder",
    por: "door/voor", para: "voor/om te", sobre: "over/op",
    entre: "tussen", hasta: "tot", desde: "vanaf", durante: "tijdens",
    antes: "voor/eerder", despues: "daarna", "después": "daarna",
    y: "en", o: "of", pero: "maar", porque: "omdat", si: "als/indien",
    no: "niet/nee", mas: "meer", "más": "meer/meest", menos: "minder",
    muy: "heel/zeer", ya: "al/reeds", casi: "bijna", tambien: "ook",
    "también": "ook", siempre: "altijd", nunca: "nooit", aqui: "hier",
    "aquí": "hier", alli: "daar", "allí": "daar", toda: "heel/de hele",
    todo: "alles/heel", todos: "allen/alle", todas: "alle",

    // --- sample-panel content words ---
    velorio: "dodenwake/nachtwake",
    angelito: "engeltje (overleden kind)",
    "ángel": "engel", angel: "engel",
    es: "is", son: "zijn", "está": "is (bevindt zich)",
    "están": "zijn (bevinden zich)", ser: "zijn", estar: "zijn",
    tradiciones: "tradities", "tradición": "traditie", tradicion: "traditie",
    populares: "populaire/volks-", popular: "populair/volks-",
    arraigadas: "diepgeworteld", arraigada: "diepgeworteld",
    arraigado: "geworteld", arraigar: "wortel schieten",
    campo: "platteland/veld", chileno: "Chileens", chilena: "Chileens",
    costumbre: "gewoonte/gebruik", costumbres: "gewoonten",
    extinta: "uitgestorven", extinto: "uitgestorven",
    dedicaba: "wijdde/droeg op", dedicaban: "wijdden/droegen op",
    dedicado: "gewijd/opgedragen", dedicada: "gewijd",
    dedicar: "wijden/opdragen",
    "niños": "kinderen", ninos: "kinderen", "niño": "kind", nino: "kind",
    "niña": "meisje", nina: "meisje",
    "fallecían": "stierven", fallecian: "stierven",
    fallecen: "overlijden", fallecer: "overlijden", fallecio: "overleed",
    "falleció": "overleed",
    cantores: "zangers", cantor: "zanger", cantante: "zanger/zangeres",
    "décimas": "tienregelige verzen", decimas: "tienregelige verzen",
    "décima": "tienregelig vers", decima: "tienregelig vers",
    noche: "nacht", noches: "nachten", dia: "dag", "día": "dag",
    ritual: "ritueel", rituales: "rituelen",
    funerario: "uitvaart-/begrafenis-", funeraria: "uitvaart-",
    apela: "doet een beroep op", apelar: "een beroep doen op",
    antigua: "oude", antiguo: "oud/antiek",
    cultura: "cultuur", culturas: "culturen",
    campesina: "boeren-/plattelands-", campesino: "boer/plattelands-",
    campesinos: "boeren",
    cumplir: "vervullen/bereiken (leeftijd)",
    tres: "drie", "años": "jaar/jaren", anos: "jaar/jaren",
    "año": "jaar", ano: "jaar",

    // --- common travel / museum words ---
    museo: "museum", obra: "werk/kunstwerk", obras: "werken",
    sala: "zaal", entrada: "ingang/toegang", salida: "uitgang",
    abierto: "open", cerrado: "gesloten", gratis: "gratis",
    horario: "openingstijden", prohibido: "verboden",
    foto: "foto", fotos: "foto's", cuadro: "schilderij",
    pintura: "schilderij/verf", escultura: "beeldhouwwerk",
    artista: "kunstenaar", siglo: "eeuw", historia: "geschiedenis",
    arte: "kunst", exposicion: "tentoonstelling",
    "exposición": "tentoonstelling",
    hola: "hallo", gracias: "dank je", adios: "tot ziens",
    "adiós": "tot ziens", agua: "water",
    bano: "wc/badkamer", "baño": "wc/badkamer", calle: "straat",
    ciudad: "stad", pueblo: "dorp", iglesia: "kerk", plaza: "plein",
    casa: "huis", mujer: "vrouw", hombre: "man", gente: "mensen",
    grande: "groot", pequeno: "klein", "pequeño": "klein",
    nuevo: "nieuw", viejo: "oud", bueno: "goed", malo: "slecht",
    vida: "leven", muerte: "dood", amor: "liefde", tiempo: "tijd",
    corazon: "hart", "corazón": "hart",
    musica: "muziek", "música": "muziek", pais: "land", "país": "land",
    mundo: "wereld", tierra: "aarde/land",
  };

  const strip = (s) =>
    String(s).toLowerCase().replace(/[^a-záéíóúñü]/g, "");

  // Look up a word: exact lemma, then a few morphology fallbacks.
  function lookup(rawWord) {
    const w = strip(rawWord);
    if (!w) return null;
    if (DICT[w]) return DICT[w];

    // plural -> singular
    if (w.endsWith("es") && DICT[w.slice(0, -2)]) return DICT[w.slice(0, -2)];
    if (w.endsWith("es") && DICT[w.slice(0, -1)]) return DICT[w.slice(0, -1)];
    if (w.endsWith("s") && DICT[w.slice(0, -1)]) return DICT[w.slice(0, -1)];

    // feminine -> masculine (-a -> -o)
    if (w.endsWith("a") && DICT[w.slice(0, -1) + "o"]) return DICT[w.slice(0, -1) + "o"];

    return null;
  }

  const Dict = { lookup };
  if (typeof module !== "undefined" && module.exports) module.exports = Dict;
  else root.Dict = Dict;
})(typeof window !== "undefined" ? window : this);

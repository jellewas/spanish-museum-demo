// Real OCR test: runs Tesseract on the sample panel with the same config + filter
// as the app, and prints RAW vs FILTERED so we can confirm the noise is gone.
const { createWorker } = require("tesseract.js");

const ONE_LETTER_WORDS = new Set(["y", "o", "a", "e", "u"]);
function plausible(text){
  const clean = text.replace(/[^A-Za-zÁÉÍÓÚáéíóúÑñÜü]/g, "");
  if(clean.length === 1) return ONE_LETTER_WORDS.has(clean.toLowerCase());
  return clean.length >= 2 && clean.length / text.length >= 0.6 && /[aeiouáéíóúü]/i.test(text);
}
function keepWord(w){
  if(!w || typeof w.text !== "string") return false;
  const conf = w.confidence || 0;
  const clean = w.text.replace(/[^A-Za-zÁÉÍÓÚáéíóúÑñÜü]/g, "");
  if(clean.length === 1) return ONE_LETTER_WORDS.has(clean.toLowerCase()) && conf >= 85;
  return conf >= 60 && plausible(w.text);
}
const letterCount = (s) => (s.match(/[A-Za-zÁÉÍÓÚáéíóúÑñÜü]/g) || []).length;
function collectLines(data){
  const out = [];
  for(const b of (data.blocks || []))
    for(const p of (b.paragraphs || []))
      for(const l of (p.lines || [])){
        const text = (l.words || []).filter(keepWord).map(w => w.text).join(" ").trim();
        if(letterCount(text) >= 2) out.push({ text, y0: l.bbox.y0, y1: l.bbox.y1 });
      }
  return out;
}
function collectParagraphs(data){
  const lines = collectLines(data);
  if(!lines.length) return [];
  const heights = lines.map(l => l.y1 - l.y0).sort((a,b)=>a-b);
  const medH = heights[Math.floor(heights.length/2)] || 1;
  const paras = []; let cur = [lines[0]];
  for(let i=1;i<lines.length;i++){
    const gap = lines[i].y0 - lines[i-1].y1;
    if(gap > medH * 0.8){ paras.push(cur.map(l=>l.text).join(" ")); cur = [lines[i]]; }
    else cur.push(lines[i]);
  }
  paras.push(cur.map(l=>l.text).join(" "));
  return paras;
}

(async () => {
  const img = process.argv[2] || "../samples/museum_panel.jpg";
  const worker = await createWorker("spa");
  await worker.setParameters({
    tessedit_pageseg_mode: "6",
    preserve_interword_spaces: "1",
    tessedit_char_whitelist:
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚáéíóúÑñÜü.,;:()¡!¿?-\"' "
  });
  const { data } = await worker.recognize(img, {}, { blocks: true, text: true });
  await worker.terminate();

  console.log("===== RAW data.text =====");
  console.log(data.text.trim());

  const paras = collectParagraphs(data);
  console.log("\n===== PARAGRAPHS (title + alineas, blank line between) =====");
  console.log(paras.join("\n\n"));
})();

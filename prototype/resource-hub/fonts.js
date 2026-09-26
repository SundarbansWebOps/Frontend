// PROTOTYPE tooling — three candidate typefaces, compared live on real pages (?font= or F).
// Only the chosen family is downloaded.
export const FONTS = [
  // Ek Type, Mumbai. Variable width + weight; Bangla, Devanagari and Tamil siblings exist.
  { id: 'anek', name: 'Anek Latin', q: 'Anek+Latin:wdth,wght@75..125,300..800' },
  { id: 'familjen', name: 'Familjen Grotesk', q: 'Familjen+Grotesk:wght@400..700' },
  { id: 'schibsted', name: 'Schibsted Grotesk', q: 'Schibsted+Grotesk:wght@400..900' },
];
export const fontById = Object.fromEntries(FONTS.map((f) => [f.id, f]));

let link;
export function useFont(id) {
  const f = fontById[id] ?? FONTS[0];
  link ??= document.head.appendChild(
    Object.assign(document.createElement('link'), { rel: 'stylesheet' })
  );
  link.href = `https://fonts.googleapis.com/css2?family=${f.q}&display=swap`;
  document.documentElement.style.setProperty(
    '--font',
    `'${f.name}', ui-sans-serif, system-ui, sans-serif`
  );
  document.documentElement.dataset.font = f.id;
}

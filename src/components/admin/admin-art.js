const plates = import.meta.glob('../../assets/admin/region-*.webp', {
  eager: true,
  import: 'default',
});
export function regionArt(region) {
  const name = region?.name?.toLowerCase();
  const slug = name?.startsWith('delhi') ? 'delhi' : name?.replaceAll(' ', '-');
  return plates[`../../assets/admin/region-${slug}.webp`] || null;
}

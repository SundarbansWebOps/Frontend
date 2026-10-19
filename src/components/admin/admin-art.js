const DELIVERY =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto:good,w_1000,c_limit';
const art = (version, file) => `${DELIVERY}/v${version}/sundarbans/admin-command-desk/${file}`;

export const ADMIN_ART = {
  banner: art('1792400425', 'banner.webp'),
  bannerAfternoon: art('1792400422', 'banner-afternoon.webp'),
  bannerEvening: art('1792400423', 'banner-evening.webp'),
  emptyBoat: art('1792400426', 'empty-boat.webp'),
  emptyClear: art('1792400427', 'empty-clear.webp'),
  avatarHead: art('1792400419', 'avatar-head.webp'),
  avatarRc: art('1792400420', 'avatar-rc.webp'),
  avatarSuper: art('1792400421', 'avatar-super.webp'),
  regions: {
    bengaluru: art('1792400428', 'region-bengaluru.webp'),
    chandigarh: art('1792400428', 'region-chandigarh.webp'),
    chennai: art('1792400430', 'region-chennai.webp'),
    delhi: art('1792400431', 'region-delhi.webp'),
    hyderabad: art('1792400433', 'region-hyderabad.webp'),
    international: art('1792400434', 'region-international.webp'),
    kolkata: art('1792400435', 'region-kolkata.webp'),
    lucknow: art('1792400436', 'region-lucknow.webp'),
    mumbai: art('1792400437', 'region-mumbai.webp'),
    patna: art('1792400439', 'region-patna.webp'),
  },
};

export function regionArt(region) {
  const name = region?.name?.toLowerCase();
  const slug = name?.startsWith('delhi') ? 'delhi' : name?.replaceAll(' ', '-');
  return ADMIN_ART.regions[slug] || null;
}

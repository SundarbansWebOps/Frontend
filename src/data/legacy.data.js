// The last five councils, 2021–2025. Names come from the green workbook rows and
// Raja's year lists; portraits use the linked Cloudinary photos where available.
const CLOUDINARY = 'https://res.cloudinary.com/l59gy0g2/image/upload';
const DELIVERY = `${CLOUDINARY}/f_auto,q_auto:good,w_1000,c_limit`;
const legacyPhoto = (version, file) => `${DELIVERY}/v${version}/sundarbans/teams/${file}`;
const teamPhoto = (version, file) => `${DELIVERY}/v${version}/sundarbans/src/assets/teams/${file}`;
const councilPhoto = (version, file) => `${DELIVERY}/v${version}/sundarbans/legacy-council/${file}`;

const AVATARS = {
  abhigyan: councilPhoto('1792177325', 'avatar-abhigyan-das.webp'),
  aman: councilPhoto('1792177326', 'avatar-aman-kankriya.webp'),
  avijeet: councilPhoto('1792177328', 'avatar-avijeet-palit.webp'),
  bhairavee: councilPhoto('1792177330', 'avatar-bhairavee-naik.webp'),
  celine: councilPhoto('1792177332', 'avatar-celine-rose-sajee.webp'),
  chankya: councilPhoto('1792177333', 'avatar-chankya-sharma.webp'),
  charvi: councilPhoto('1792177334', 'avatar-charvi-gupta.webp'),
  hardik: councilPhoto('1792177335', 'avatar-hardik-minocha.webp'),
  harshit: councilPhoto('1792177337', 'avatar-harshit-gunjal.webp'),
  kushagrah: councilPhoto('1792177339', 'avatar-kushagrah-tripathi.webp'),
  madhugandha: councilPhoto('1792177340', 'avatar-madhugandha.webp'),
  manaswita: councilPhoto('1792177341', 'avatar-manaswita-mandal.webp'),
  nupoor: councilPhoto('1792177343', 'avatar-nupoor-upadhye.webp'),
  rituparno: councilPhoto('1792177345', 'avatar-rituparno-dhar.webp'),
  sadhana: councilPhoto('1792177347', 'avatar-sadhana-chandekar.webp'),
  suhaas: councilPhoto('1792177348', 'avatar-suhaas-neel.webp'),
  veda: councilPhoto('1792177349', 'avatar-veda-samhith-manthena.webp'),
  venkatesh: councilPhoto('1792177350', 'avatar-venkatesh-k-iyengar.webp'),
};
const PHOTOS = {
  aakash: councilPhoto('1792177321', 'aakash-rawal.webp'),
  aditri: councilPhoto('1792177322', 'aditri-bordoloi.webp'),
  aditya2025: councilPhoto('1792177324', 'aditya-vaidhya-2025.webp'),
  chandan: councilPhoto('1792177352', 'chandan-saw.webp'),
  dishi: councilPhoto('1792177354', 'dishi-gupta.webp'),
  kartik: councilPhoto('1792177355', 'kartik-singh.webp'),
  laksh: councilPhoto('1792177356', 'laksh-wadhawan.webp'),
  mannu: councilPhoto('1792177357', 'mannu-yadav.webp'),
  nivash: councilPhoto('1792177358', 'nivash-kumar.webp'),
  saiSahanaa: councilPhoto('1792177360', 'r-sai-sahanaa.webp'),
  rushabh: councilPhoto('1792177361', 'rushabh-kapse.webp'),
  samar: councilPhoto('1792177362', 'samar-ahmed.webp'),
};
const person = (name, role, photo, isIllustrated = false) => ({
  name,
  role,
  photo,
  illustrated: isIllustrated,
});
const team = (members) =>
  members.map(([name, role, photo, isIllustrated = false], index) => ({
    id: index + 1,
    name,
    role,
    photo,
    illustrated: isIllustrated,
  }));

export const FOUNDED = 2021;
const kunal2021 = councilPhoto('1792177588', 'kunal-2021-tiger.webp');
const anshuman2021 = councilPhoto('1792223335', 'anshuman-2021-tiger.jpg');
const utkarsh2021 = councilPhoto('1792177589', 'utkarsh-2021-tiger.webp');

export const LEGACY = [
  {
    year: 2021,
    secretary: person('Anshuman Bhasin', 'Secretary', anshuman2021),
    deputy: person('Utkarsh Gaurav', 'Deputy Secretary', utkarsh2021),
    team: team([
      ['Abhigyan Das', 'WebOps Head', AVATARS.abhigyan, true],
      ['Bhairavee Naik', 'GL', AVATARS.bhairavee, true],
      ['Rituparno Dhar', 'GL', AVATARS.rituparno, true],
      ['Manaswita Mandal', 'GL', AVATARS.manaswita, true],
      ['Suhaas Neel', 'GL', AVATARS.suhaas, true],
      ['Madhugandha', 'GL', AVATARS.madhugandha, true],
      ['Kushagrah Tripathi', 'GL', AVATARS.kushagrah, true],
      ['Kunal Chaturvedi', 'GL', kunal2021],
      ['Hardik Minocha', 'GL', AVATARS.hardik, true],
      ['Charvi Gupta', 'GL', AVATARS.charvi, true],
      ['Nupoor Upadhye', 'GL', AVATARS.nupoor, true],
    ]),
  },
  {
    year: 2022,
    secretary: person('Kunal Chaturvedi', 'Secretary', kunal2021),
    deputy: person(
      'Abhishek Ojha',
      'Deputy Secretary',
      legacyPhoto('1792094947', 'Abhishek_ojha.png')
    ),
    team: team([
      ['Kushagrah Tripathi', 'GL', AVATARS.kushagrah, true],
      ['Chankya Sharma', 'GL', AVATARS.chankya, true],
      ['Veda Samhith Manthena', 'GL', AVATARS.veda, true],
      ['Harshit Gunjal', 'GL', AVATARS.harshit, true],
      ['Manaswita Mandal', 'GL', AVATARS.manaswita, true],
      ['Celine Rose Sajee', 'GL', AVATARS.celine, true],
      ['Venkatesh K Iyengar', 'GL', AVATARS.venkatesh, true],
      ['Sadhana Chandekar', 'GL', AVATARS.sadhana, true],
      ['Avijeet Palit', 'GL', AVATARS.avijeet, true],
      ['Aman Kankriya', 'GL', AVATARS.aman, true],
    ]),
  },
  {
    year: 2023,
    secretary: person('Abhishek Ojha', 'Secretary', legacyPhoto('1792094947', 'Abhishek_ojha.png')),
    deputy: person('Ravi Kant', 'Deputy Secretary', legacyPhoto('1792095019', 'ravikant.png')),
    team: team([
      ['Ravi Kumawat', 'WebOps Head', legacyPhoto('1792095015', 'Ravi_Kumawat.png')],
      ['Afrin Gowhar', 'GL', legacyPhoto('1792094953', 'Afrin_Gowhar.png')],
      ['Shreyansh Mall', 'GL', legacyPhoto('1792095027', 'shreyansh.png')],
      ['Aditya Vaidhya', 'GL', legacyPhoto('1792094950', 'Aditya_Vadiya.png')],
      ['Mannu Yadav', 'GL', PHOTOS.mannu],
      ['Kanak Prajapati', 'GL', legacyPhoto('1792094992', 'Kanak_Prajapati.png')],
      ['Divya Chinmay', 'GL', legacyPhoto('1792094976', 'divya.png')],
      ['Anshi Jain', 'GL', legacyPhoto('1792094964', 'Anshi_jain.png')],
      ['Namai Chandra', 'GL', legacyPhoto('1792095482', 'Namai_Chandra.png')],
    ]),
  },
  {
    year: 2024,
    secretary: person('Shreyansh Mall', 'Secretary', legacyPhoto('1792095027', 'shreyansh.png')),
    deputy: person('Divya Chinmay', 'Deputy Secretary', legacyPhoto('1792094976', 'divya.png')),
    team: team([
      ['Aditya Vaidhya', 'RC', legacyPhoto('1792094950', 'Aditya_Vadiya.png')],
      ['Tanish Shali Bopanna', 'RC', legacyPhoto('1792095045', 'tanish_shali_bopanna.png')],
      ['Nitin Faldoliya', 'RC', legacyPhoto('1792095006', 'nitinfaldoliya.png')],
      ['Varanasi Sai Sirichandana', 'RC', legacyPhoto('1792095022', 'sai_sirichandana.png')],
      ['Swati Singh', 'RC', legacyPhoto('1792095037', 'swati_singh.png')],
      ['Krish Gupta', 'RC', legacyPhoto('1792094998', 'krish_gupta.png')],
      ['Aman Sagar', 'RC', legacyPhoto('1792094958', 'aman_sagar.png')],
      ['Lata', 'RC', legacyPhoto('1792095001', 'lata.png')],
      ['Piush Das', 'RC', legacyPhoto('1792095009', 'piush_das.png')],
    ]),
  },
  {
    year: 2025,
    secretary: person('Mannu Yadav', 'Secretary', PHOTOS.mannu),
    deputy: person('Aditya Vaidhya', 'Deputy Secretary', PHOTOS.aditya2025),
    team: team([
      ['Samar Ahmed', 'WebOps Head', PHOTOS.samar],
      ['Aakash Rawal', 'RC', PHOTOS.aakash],
      ['Aditri Bordoloi', 'RC', PHOTOS.aditri],
      ['Chandan Saw', 'RC', PHOTOS.chandan],
      ['Dishi Gupta', 'RC', PHOTOS.dishi],
      ['Divya Prakash', 'RC', legacyPhoto('1791953706', 'Divya_Prakash.png')],
      ['Kartik Singh', 'RC', PHOTOS.kartik],
      ['Laksh Wadhawan', 'RC', PHOTOS.laksh],
      ['Nivash Kumar', 'RC', PHOTOS.nivash],
      ['R Sai Sahanaa', 'RC', PHOTOS.saiSahanaa],
      ['Rushabh Kapse', 'RC', PHOTOS.rushabh],
    ]),
  },
];

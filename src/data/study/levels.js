// Display order of every course, grouped by level. Each code has one file in ./courses/.
// Plain module (no Vite features) so scripts/check-study-data.mjs can import it in Node.
export const STUDY_LEVELS = {
  foundation: [
    'BSMA1001',
    'BSMA1002',
    'BSCS1001',
    'BSHS1001',
    'BSMA1003',
    'BSMA1004',
    'BSCS1002',
    'BSHS1002',
  ],
  diploma: [
    'BSCS2001',
    'BSCS2002',
    'BSCS2003',
    'BSCS2005',
    'BSCS2006',
    'BSCS2004',
    'BSMS2001',
    'BSCS2007',
    'BSCS2008',
    'BSSE2001',
    'BSSE2002',
  ],
  bs: ['BSCS3001', 'BSCS3002', 'BSCS3003', 'BSCS3004'],
};

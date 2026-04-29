import bengaluruRegion from './region_exports_json_and_csv/json/bengaluru_region.json'
import chandigarhRegion from './region_exports_json_and_csv/json/chandigarh_region.json'
import chennaiRegion from './region_exports_json_and_csv/json/chennai_region.json'
import delhiRegion from './region_exports_json_and_csv/json/delhi_region.json'
import hyderabadRegion from './region_exports_json_and_csv/json/hyderabad_region.json'
import kolkataRegion from './region_exports_json_and_csv/json/kolkata_region.json'
import mumbaiRegion from './region_exports_json_and_csv/json/mumbai_region.json'
import patnaRegion from './region_exports_json_and_csv/json/patna_region.json'

const regionMeta = {
  bangalore: {
    chapterLabel: 'Bangalore Chapter',
    heroTitle: 'Bangalore',
    heroDesc: 'India\'s Silicon Valley meets IITM BS. Where techies, builders, and curious minds come together to grow beyond the screen.',
  },
  chandigarh: {
    chapterLabel: 'Chandigarh Chapter',
    heroTitle: 'Chandigarh',
    heroDesc: 'India\'s most planned city hosts one of IITM BS\'s most organised student chapters. Clean, purposeful, and growing fast.',
  },
  chennai: {
    chapterLabel: 'Chennai Chapter',
    heroTitle: 'Chennai',
    heroDesc: 'The city closest to IIT Madras. Chennai\'s chapter carries a special pride, linking students, alumni, and aspirants close to the programme\'s home base.',
  },
  delhi: {
    chapterLabel: 'Delhi NCR Chapter',
    heroTitle: 'Delhi',
    heroDesc: 'Connecting students across Delhi, Noida, and Gurgaon through real meetups, student collaboration, and a strong IITM BS community.',
  },
  hyderabad: {
    chapterLabel: 'Hyderabad Chapter',
    heroTitle: 'Hyderabad',
    heroDesc: 'Cyberabad to Charminar. Hyderabad\'s chapter blends city energy, student initiative, and a growing offline community.',
  },
  kolkata: {
    chapterLabel: 'Kolkata Chapter',
    heroTitle: 'Kolkata',
    heroDesc: 'The city of joy, culture, and intellectual tradition. Kolkata\'s Sundarbans chapter brings warmth and academic rigour together.',
  },
  mumbai: {
    chapterLabel: 'Mumbai Chapter',
    heroTitle: 'Mumbai',
    heroDesc: 'A wide regional chapter spanning Mumbai, Pune, Nagpur, Ahmedabad, and beyond. High energy, large turnouts, and steady community momentum.',
  },
  patna: {
    chapterLabel: 'Patna Chapter',
    heroTitle: 'Patna',
    heroDesc: 'One of the fastest-growing Sundarbans chapters, with meetups across Bihar and neighbouring cities built around strong student participation.',
  },
}

function cleanText(value) {
  if (value == null) return null
  const text = String(value).replace(/\uFEFF/g, '').replace(/\s+/g, ' ').trim()
  return text && text.toUpperCase() !== 'NA' ? text : null
}

function cleanUrl(value) {
  const url = cleanText(value)
  return url ? url.replace(/\s+/g, '') : null
}

function parseCount(value) {
  if (value == null) return null
  if (typeof value === 'number') return value
  const match = String(value).match(/\d+/)
  return match ? Number(match[0]) : null
}

function normalizeMeetupNumber(value) {
  const text = cleanText(value)
  if (!text) return null
  const match = text.match(/\d+/)
  return match ? `#${match[0]}` : text
}

function parseDate(value) {
  const text = cleanText(value)
  if (!text) return null

  const iso = Date.parse(text)
  if (!Number.isNaN(iso)) return new Date(iso)

  const normalized = text
    .replace(/(\d+)(st|nd|rd|th)/gi, '$1')
    .replace(/\./g, '')
    .replace(/'(\d{2})\b/g, ' 20$1')
  const parsed = Date.parse(normalized)
  return Number.isNaN(parsed) ? null : new Date(parsed)
}

function formatDate(value) {
  const parsed = parseDate(value)
  if (!parsed) return cleanText(value)
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(parsed)
}

function formatBadge(value, meetupNo) {
  const parsed = parseDate(value)
  if (parsed) {
    return new Intl.DateTimeFormat('en-GB', {
      month: 'long',
      year: 'numeric',
    }).format(parsed)
  }
  return meetupNo ? `Meetup ${meetupNo}` : 'Community Meetup'
}

function buildTags(parts) {
  return parts.filter(Boolean).slice(0, 6)
}

function splitCollaboration(value) {
  const text = cleanText(value)
  if (!text) return []
  return text
    .replace(/[()]/g, '')
    .split(/\s+[xX×]\s+/)
    .map(cleanText)
    .filter(Boolean)
}

function normalizeRecords(records, mapper) {
  return records
    .map(mapper)
    .filter((record) => record && (record.about || record.instaUrl || record.attended || record.numberDisplay))
    .sort((a, b) => {
      const aDate = a.sortDate ? a.sortDate.getTime() : -Infinity
      const bDate = b.sortDate ? b.sortDate.getTime() : -Infinity
      if (aDate !== bDate) return bDate - aDate

      const aNum = a.sortNo ?? -Infinity
      const bNum = b.sortNo ?? -Infinity
      return bNum - aNum
    })
    .map(({ sortDate, sortNo, ...record }) => record)
}

function buildStats(meetups) {
  const locations = new Set(meetups.map((meetup) => meetup.location).filter(Boolean))
  const members = meetups.reduce((sum, meetup) => sum + (meetup.attended || 0), 0)
  return {
    total: meetups.length,
    cities: locations.size,
    members,
  }
}

function titleFromVenue(venue, fallbackCity) {
  const cleanVenue = cleanText(venue)
  if (!cleanVenue) return `${fallbackCity} Meetup`
  const venueLower = cleanVenue.toLowerCase()
  const cityLower = fallbackCity.toLowerCase()
  return venueLower === cityLower || venueLower === `${cityLower} city`
    ? `${fallbackCity} Meetup`
    : cleanVenue
}

function mapChandigarh(record, index) {
  const meetupNo = record.meetup_no ? `#${record.meetup_no}` : null
  const location = cleanText(record.venue)
  const posterName = cleanText(record.meetup_poster)
  const title = posterName && posterName.toLowerCase() !== 'meetup'
    ? `${location} – ${posterName}`
    : location ? `${location} Meetup` : 'Chandigarh Region Meetup'
  return {
    id: index + 1,
    badge: meetupNo ? `Meetup ${meetupNo}` : 'Community Meetup',
    instaUrl: cleanUrl(record.social_media_link),
    title,
    date: cleanText(record.date),
    location,
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record.description) || 'Meetup details coming soon.',
    attended: record.total_students ?? null,
    tags: buildTags([location, ...splitCollaboration(record.collaboration)]),
    sortDate: parseDate(record.date),
    sortNo: record.meetup_no ?? null,
  }
}

function mapBangalore(record, index) {
  const meetupNo = normalizeMeetupNumber(record['Meetup No.'])
  const location = cleanText(record.Venue)
  const attended = parseCount(record['Total Students'])
  return {
    id: index + 1,
    badge: formatBadge(null, meetupNo),
    instaUrl: cleanUrl(record['Social Media link']),
    title: titleFromVenue(location, 'Bangalore'),
    date: null,
    location,
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record.Description) || 'Meetup details have not been added yet, but the chapter turnout is recorded in the export.',
    attended,
    tags: buildTags([location, ...splitCollaboration(record.Collaboration)]),
    sortDate: null,
    sortNo: parseCount(record['Meetup No.']),
  }
}

function mapDelhi(record, index) {
  const meetupNo = normalizeMeetupNumber(record['MEET-UP NO'])
  const date = formatDate(record.Date)
  const attended = parseCount(record.Attendees)
  return {
    id: index + 1,
    badge: formatBadge(record.Date, meetupNo),
    instaUrl: cleanUrl(record['Attachments (Insta Link)']),
    title: cleanText(record.Meetup) || 'Delhi Meetup',
    date,
    location: 'Delhi NCR',
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record.Summary),
    attended,
    tags: buildTags(splitCollaboration(record.COLLAB)),
    sortDate: parseDate(record.Date),
    sortNo: parseCount(record['MEET-UP NO']),
  }
}

function mapHyderabad(record, index) {
  const meetupNo = normalizeMeetupNumber(record['MEET-UP NO'])
  const title = cleanText(record.Meetup) || 'Hyderabad Meetup'
  return {
    id: index + 1,
    badge: formatBadge(record.Date, meetupNo),
    instaUrl: cleanUrl(record['Attachments (Insta Link)']),
    title,
    date: formatDate(record.Date),
    location: 'Hyderabad',
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record.Summary),
    attended: parseCount(record.Attendees),
    tags: buildTags(splitCollaboration(record.COLLAB)),
    sortDate: parseDate(record.Date),
    sortNo: parseCount(record['MEET-UP NO']),
  }
}

function mapKolkata(record, index) {
  const meetupNo = normalizeMeetupNumber(record['MEETUP NO'])
  const location = cleanText(record.Location) || 'Kolkata'
  return {
    id: index + 1,
    badge: formatBadge(null, meetupNo),
    instaUrl: cleanUrl(record['Insta post link']),
    title: titleFromVenue(location, 'Kolkata'),
    date: null,
    location,
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record['2-4 line about that meetup']),
    attended: parseCount(record['No of student attended']),
    tags: buildTags([location, ...splitCollaboration(record['Collaboration with'])]),
    sortDate: null,
    sortNo: parseCount(record['MEETUP NO']),
  }
}

function mapMumbai(record, index) {
  if (cleanText(record.Description) === 'Upcoming') return null
  const meetupNo = normalizeMeetupNumber(record['Meetup No.'])
  const location = cleanText(record.Venue)
  return {
    id: index + 1,
    badge: formatBadge(null, meetupNo),
    instaUrl: cleanUrl(record['Social Media link']),
    title: titleFromVenue(location, 'Mumbai'),
    date: null,
    location,
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record.Description),
    attended: parseCount(record['Total Students']),
    tags: buildTags([location, ...splitCollaboration(record.Collaboration)]),
    sortDate: null,
    sortNo: parseCount(record['Meetup No.']),
  }
}

function mapPatna(record, index) {
  const meetupNo = normalizeMeetupNumber(record['Meetup No.'])
  const organizer = cleanText(record.Organizer)
  return {
    id: index + 1,
    badge: formatBadge(record.Date, meetupNo),
    instaUrl: cleanUrl(record['Insta Post Link']),
    title: cleanText(record['Meetup Name']) || 'Patna Meetup',
    date: formatDate(record.Date),
    location: cleanText(record.Region) || 'Patna',
    duration: null,
    meetupNumber: meetupNo,
    numberDisplay: meetupNo,
    special: null,
    about: cleanText(record['Meetup Details in Brief']),
    attended: parseCount(record['No. of Attendes']),
    organizer,
    tags: buildTags(splitCollaboration(record['House/Society'])),
    sortDate: parseDate(record.Date),
    sortNo: parseCount(record['Meetup No.']),
  }
}

function buildConfig(meta, meetups) {
  return {
    ...meta,
    stats: buildStats(meetups),
    upcoming: null,
    pastMeetups: meetups,
  }
}

export const regionConfigs = {
  bangalore: buildConfig(regionMeta.bangalore, normalizeRecords(bengaluruRegion.records || [], mapBangalore)),
  chandigarh: buildConfig(regionMeta.chandigarh, normalizeRecords(chandigarhRegion.records || [], mapChandigarh)),
  chennai: buildConfig(regionMeta.chennai, normalizeRecords(chennaiRegion.records || [], () => null)),
  delhi: buildConfig(regionMeta.delhi, normalizeRecords(delhiRegion.records || [], mapDelhi)),
  hyderabad: buildConfig(regionMeta.hyderabad, normalizeRecords(hyderabadRegion.records || [], mapHyderabad)),
  kolkata: buildConfig(regionMeta.kolkata, normalizeRecords(kolkataRegion.records || [], mapKolkata)),
  mumbai: buildConfig(regionMeta.mumbai, normalizeRecords(mumbaiRegion.records || [], mapMumbai)),
  patna: buildConfig(regionMeta.patna, normalizeRecords(patnaRegion.records || [], mapPatna)),
}

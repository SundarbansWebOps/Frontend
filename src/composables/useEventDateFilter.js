/**
 * useEventDateFilter.js
 * ---------------------
 * Shared composable that dynamically splits a flat event list into:
 *   - upcomingEvents  → events whose date is today or in the future
 *   - pastEvents      → statically curated past events +
 *                       any events auto-demoted because their date passed
 *
 * Each event in `allEvents` may carry:
 *   - dateISO   : 'YYYY-MM-DD'  — highest priority, most reliable
 *   - day + month: e.g. day:'25', month:'APR'  — parsed with current year then
 *                  rolled to next year if the result is already in the past
 *                  (handles "same month" edge cases gracefully)
 *
 * If neither field is present the event is kept in upcoming (fail-open).
 *
 * Usage:
 *   import { useEventDateFilter } from '@/composables/useEventDateFilter'
 *   const { upcomingEvents, allPastEvents } = useEventDateFilter(allEvents, staticPastEvents)
 */

import { computed } from 'vue'

const MONTH_MAP = {
  JAN: 0, FEB: 1, MAR: 2, APR: 3, MAY: 4, JUN: 5,
  JUL: 6, AUG: 7, SEP: 8, OCT: 9, NOV: 10, DEC: 11,
}

/**
 * Parse a machine date (dateISO) or a day+month pair into a Date object.
 * Returns null when neither is parseable.
 */
function parseEventDate(event) {
  // 1. Prefer explicit ISO date
  if (event.dateISO) {
    const d = new Date(event.dateISO)
    if (!isNaN(d)) return d
  }

  // 2. Fall back to day + month (assume current year)
  if (event.day && event.month) {
    const day   = parseInt(event.day, 10)
    const month = MONTH_MAP[String(event.month).toUpperCase().slice(0, 3)]
    if (!isNaN(day) && month !== undefined) {
      const now  = new Date()
      let year   = now.getFullYear()
      return new Date(year, month, day)
    }
  }

  return null
}

/**
 * @param {Array}  allEvents         – upcoming event objects (mutable array or ref)
 * @param {Array}  staticPastEvents  – hardcoded past events array
 * @returns {{ upcomingEvents: ComputedRef, allPastEvents: ComputedRef }}
 */
export function useEventDateFilter(allEvents, staticPastEvents = []) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  /** Events whose parsed date is today or future (or unparseable → kept) */
  const upcomingEvents = computed(() =>
    allEvents.filter((e) => {
      const d = parseEventDate(e)
      return d === null || d >= today
    })
  )

  /** Events from allEvents whose date has already passed → auto-demoted */
  const autoDemotedEvents = computed(() =>
    allEvents
      .filter((e) => {
        const d = parseEventDate(e)
        return d !== null && d < today
      })
      .map((e) => ({
        // Normalize to the shape used by the past-event cards
        id:          e.id ?? Math.random(),
        title:       e.title,
        type:        e.type,
        description: e.description,
        date:        e.dateISO
          ? new Date(e.dateISO).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
          : `${e.day ?? ''} ${e.month ?? ''}`.trim(),
        attendees:   e.attendees ?? '—',
        image:       e.image,
        // ESports-style fields
        day:         e.day,
        month:       e.month,
        time:        e.time,
        venue:       e.venue,
      }))
  )

  /** Combined: auto-demoted first (most recent), then static past events */
  const allPastEvents = computed(() => [
    ...autoDemotedEvents.value,
    ...staticPastEvents,
  ])

  return { upcomingEvents, allPastEvents }
}

# Lounge sky motion research

Research date: 2026-10-10. Scope: a calm painted riverside scene; user requested birds at 50% of their current speed and clouds with barely noticeable motion and clear spacing.

## Source facts

- Bird flight varies by species and wing shape. Cornell Lab distinguishes soaring, gliding, swooping and hovering. Its educational table gives 20 wingbeats per ten seconds for a crow, 23 for a robin and 30 for a pigeon. These are illustrative rates, not a universal animation target. [Cornell Lab: Animals in Flight](https://www.birds.cornell.edu/k12/animals-in-flight/)
- Cornell describes long, narrow wings in gulls and other active soaring birds as supporting extended flight without flapping. Elliptical wings in crows and sparrows support short bursts and maneuverability. A held-wing glide is plausible for some birds, but the artwork alone does not establish species. [Cornell Lab: Birds and their Wing Shapes](https://www.birds.cornell.edu/k12/wp-content/uploads/2018/11/Bird-Wing-Types-Handout.pdf)
- Meteorologists infer wind speed and direction from cloud movement. Clouds are atmospheric water droplets or ice crystals rather than solid objects. Differing air-layer speeds can affect cloud forms. The sources do not prescribe a screen-space speed or guarantee that real clouds never overlap. [Met Office: Satellite pictures](https://weather.metoffice.gov.uk/learn-about/how-forecasts-are-made/observations/satellite-pictures), [Clouds](https://weather.metoffice.gov.uk/learn-about/weather/types-of-weather/clouds), [Kelvin-Helmholtz cloud](https://weather.metoffice.gov.uk/learn-about/weather/types-of-weather/clouds/unusual-cloud-formations/kelvin-helmholtz)

## Artistic implementation choices

- Double existing bird travel durations over unchanged paths to halve apparent speed exactly. Keep motion predominantly forward, with shallow smooth height changes rather than rapid whole-body bouncing. Offset individual timing so the flock does not move mechanically in lockstep.
- If separate wing artwork exists, use short flapping passages and longer held-wing glides. Wingbeat and travel speed are separate controls. Do not call slower playback a scientifically measured flight speed: camera scale, depth and species are unknown.
- Place clouds in distinct lanes with a reserved envelope covering their image width plus their entire drift. Account for any clouds painted into the background as well as animated overlays. Keep envelopes separate on desktop and narrow screens.
- Prefer coherent, very slow horizontal drift over visible vertical bobbing or repeated direction changes. A starting range of 12–24 screen pixels over 90–150 seconds suits the requested close-observation effect; these numbers are visual design choices, not meteorological measurements.
- Preserve reduced-motion and inactive-page pausing. Verify spacing at the start, intermediate positions and extrema, including responsive layouts; judge the motion in the actual browser before completion.

No animation code or real-weather measurements were changed by this research.

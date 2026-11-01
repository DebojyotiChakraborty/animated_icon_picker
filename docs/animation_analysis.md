# App Icon Picker: frame-by-frame animation analysis

Source: `kavsoft.mp4` (1080x1080, 60 fps, 31 s, 1859 frames). Frame N is at t = (N-1)/60 s.
All measurements were made with numpy/scipy on the extracted frames (scripts in the session scratchpad
`analysis_scripts/`: `timeline.py`, `iconfit.py`, `run_track.py`, `pmap.py`, `pfit.py`, `settle.py`,
`sheetfit.py`, `dismissfit.py`, `label.py`, `btnanim.py`, `digit.py`, `fontfit.py`, `iconcolors.py`).

## 0. Coordinate system and scale

| item | value |
|---|---|
| Phone screen in video | x 312..767, y 44..1035 (456 x 992 px) |
| Device | 402 x 874 pt |
| Scale | **1 pt = 1.1343 px** (456/402; height check 992/874 = 1.135) |
| Sheet origin used below | sheet top-left corner = screen (7.9 pt, 449.2 pt) |

Unless stated otherwise: positions are in pt, X to the right and Y downwards, rotation positive = clockwise
(same convention as Flutter `Transform.rotate`), and blur is a Gaussian sigma in pt (= Flutter `ImageFilter.blur` sigma).

The recording has occasional duplicated or dropped frames (for example 33=34, 109=110, 114=115, 830=831),
so single-frame timings are good to about ±1 frame (±17 ms).

### Event timeline

| frames | time (s) | event |
|---|---|---|
| 1-25 | 0.00-0.40 | list screen |
| 26-52 | 0.42-0.85 | sheet opens on Default (01/06, "Currently Active") |
| 94-136 | 1.55-2.25 | **T1** drag + settle Default -> Blush |
| 156-194 | 2.58-3.22 | **T2** drag + settle Blush -> Grape |
| 231-264 | 3.83-4.38 | fling Grape -> Midnight -> Mono -> Ocean (3 pages in 0.55 s) |
| 297-337 | 4.93-5.60 | fling back Ocean -> ... -> Blush |
| 399-416 | 6.63-6.92 | press "Activate App Icon" (Blush) |
| 415-430 / 489-498 | 6.90 / 8.15 | system alert appears / dismissed (OK) |
| 515-530 | 8.57-8.82 | sheet dismisses by itself 0.28 s after the alert is gone |
| 569-690 | 9.47-11.48 | home screen shows the Blush icon, back into the app |
| 743-770 | 12.37-12.82 | sheet opens on Blush (02/06, "Currently Active") |
| 818-850 | 13.62-14.15 | **T3** swipe Blush -> Default (rightward) |
| 883-918 | 14.70-15.28 | fling Default -> Mono |
| 976-1085 | 16.25-18.07 | activate Mono, alert, auto-dismiss (1073) |
| 1317-1348 | 21.93-22.45 | sheet opens on Mono; 1378-1409 fling back to Default |
| 1475-1584 | 24.57-26.38 | activate Default, alert, auto-dismiss (1572) |
| 1634-1660 | 27.22-27.65 | sheet opens on Default |
| 1696-1741 | 28.25-29.00 | user pulls the sheet up (rubber band) |
| 1779-1797 | 29.63-29.93 | interactive drag-down dismiss |

## 1. Sheet

### Geometry and colours

| property | measured |
|---|---|
| Width | 438 px = **386 pt** |
| Height | 473.5 px = **417 pt** (top edge at 449 pt, bottom edge at 866.6 pt) |
| Inset from screen edges | left 7.9, right 7.9, bottom 7.9 pt -> **8 pt** on all three sides |
| Top corner radius | ~40 px = **35 pt** (circular equivalent; edge profile dy 3/12/24 px -> inset 26/12/4 px) |
| Bottom corner radius | ~59 px = **52 pt** (concentric with the display corner: ~60 pt display radius minus 8 pt inset) |
| Background | **#DEDDE2** (flat; 219-224 luminance across the sheet) |
| Top rim | 1-2 px bright highlight #EAE9EE, then a slightly darker 10 px band #D8D7DC (Liquid Glass edge) |
| Outer edge | 1 px darker hairline (scrim 178 -> 150 luminance), very soft shadow (scrim 186 -> 178 within ~8 px) |
| List behind | **does not scale or blur**: large title ink box is 19..295 x 144..179 px in every frame |

### Scrim

| state | list bg | ratio | equivalent |
|---|---|---|---|
| sheet closed | #EFEEF3 | 1.000 | none |
| sheet open | #BAB9BE | 0.778 | **black at 22 % opacity** |
| system alert on top | luminance 144 | 0.60 | black at ~40 % total (alert adds ~22.6 %) |

The scrim opacity is locked to the sheet position: opacity = 0.22 x (1 - sheetOffset/hiddenOffset). Checked during the
dismiss: at 45.7 % of travel alpha = 0.120 (0.54 x 0.222), at 70.6 % alpha = 0.064 (0.29 x 0.222).

### Open animation (4 occurrences)

Sheet top distance from rest, in px (rest top = 509.5 px):

| frame | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 45 | 46 | 48 | 50 | 52 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| d (px) | 392 | 335 | 283 | 235 | 193 | 156 | 126 | 91 | 79 | 63 | 50 | 36 | 28 | 19 | 15 | 11 | 7 | 5 | 4 | 1 | 0 |

Fit (critically damped spring starting at rest from the hidden position):

| open | omega (rad/s) | zeta (free fit) | hidden offset | visible duration to <1 pt |
|---|---|---|---|---|
| 1 (f26) | 16.45 | 0.985 | 467 pt | 0.45 s |
| 2 (f742) | 16.95 | 0.914 | 425 pt | 0.47 s |
| 3 (f1316) | 16.40 | 0.956 | 425 pt | 0.55 s |
| 4 (f1633) | 17.75 | 0.958 | 425 pt | 0.43 s |

-> spring, **no overshoot** (minimum top 508-510 px vs rest 509.5 px), omega ~16.5 rad/s (SwiftUI response ~0.38 s,
damping fraction ~0.95-1.0). The sheet starts fully below the screen (offset ~425 pt = sheet height + 8 pt) and slides
straight up; the content inside is rigid (no internal stagger). The scrim fades in over the same 0.32-0.45 s.

### Dismiss animation

Distance travelled (pt) per frame after the dismiss starts:

| dismiss | f+0 | +1 | +2 | +3 | +4 | +5 | +6 | +7 | +8 | +9 | +10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| f1073 | 14 | 52 | 97 | 148 | 193 | 234 | 271 | 302 | 328 | 350 | 368 |
| f1572 | 17 | 56 | 104 | 154 | 199 | 238 | 275 | 305 | 331 | 352 | 370 |

Fit: critically damped spring towards ~435 pt (just off-screen), **omega 18.3 rad/s (response 0.34 s)**, rms 0.7 pt.
Visible part (until the top leaves the screen) ~0.2 s, finished ~0.3 s. Scrim fades out with it.
After activation the sheet dismisses itself 17-20 frames (0.28-0.33 s) after the alert has finished disappearing; the X
button shows no press state in those frames, so this is programmatic.

Drag-to-dismiss (f1779-1797): finger-driven 10, 19, 30, 42, 54, 68, 82, 104, 127, 144, 167 pt, then after release
197, 241, 275, 308, 351, 382 pt (off-screen in ~0.12 s).

### Rubber band when pulled up (f1696-1741)

Pulling the detent up makes the sheet taller (top rises up to 77 pt) while its width stays 386 pt; the carousel area
grows and **the centre icon grows with it** (154 px -> 196 px, i.e. 135 -> 173 pt, ~0.46 pt of icon per pt of extra
height) and moves up by about half the stretch. On release it returns in ~16 frames (0.27 s) with no overshoot.
During normal swipes the sheet top jitters by ±1.5 pt (layout re-measure), which can be ignored.

## 2. Layout inside the sheet (pt, relative to the sheet top-left; sheet is 386 x 417)

| element | measured |
|---|---|
| Close button | glass circle **44 pt** diameter, centre (35.3, 35.3) -> 13 pt from top and left. Fill ~#EEEDF1 (luminance 230-245 vs sheet 222) with a faint darker rim and soft shadow. Glyph: black "xmark", ink 12.3 x 12.3 pt (SF Symbol xmark, ~17 pt, medium weight) |
| Counter "01" | **SF Mono, 20 pt, bold**, accent blue (fill sampled #0169BD in the thin strokes, use the same blue as the button, #007AFF). Ink x 170.2..192.2, cap top 23.4, baseline 38.8 |
| Counter "/ 06" | **SF Mono, 11 pt, semibold**, grey #737277. Ink x 196.6..216.0; baseline 41.4, i.e. **2.6 pt below** the big digits' baseline; gap "01" -> "/" ink 4.4 pt (about 3 pt of layout spacing) |
| Counter group | horizontally centred on the sheet (ink centre 193.1 vs sheet centre 193.0); vertical ink centre 30.4 (4-5 pt above the close button centre) |
| Centre icon | **135 pt** square (153-154 px), centre (193, 148.6), top 81, bottom 216. Continuous (squircle) corners: area/side^2 = 0.9385 -> circular equivalent radius 36 pt (26.6 %); as an iOS continuous corner ~30 pt (22.5 %). No shadow |
| Name label | **SF Pro 22 pt semibold**, black (#000000). Cap top 236.7, baseline 252.1 (20.7 pt below the icon) |
| Caption | **SF Pro 15 pt regular**, grey (darkest stroke #646267), centred, 2 lines "Choose a look for your home screen. You can" / "switch back to any icon at any time." Baselines 300.2 and 324.0 -> **line pitch 23.8 pt** (font height 1.59). Ink widths 313 / 245 pt |
| Button | capsule, x 28.2..358.8 (**330.6 pt wide, 28 pt side inset**), y 348.7..395.0 (**46 pt tall**), 22.4 pt above the sheet bottom. Text **SF Pro 17 pt regular**, centred |
| Button "Activate App Icon" | fill **#007AFF** (sampled #017AFD..#027BFE; top 6 px slightly lighter #0580FF), text white |
| Button "Currently Active" | fill **#CFCED3** (= black ~6.7 % over the sheet), 1 px darker rim at the top, text grey **#77767B**, not tappable |
| Button pressed | grows to ~**1.055x** (374 -> 396 px wide, 53 -> 55 px tall) and lightens to #008DFE, in ~7 frames (0.12 s); returns in ~5 frames on release |

Font sizes were confirmed by rendering SF Pro / SF Mono at candidate sizes and matching ink widths
("Currently Active" 120.8 pt -> 17.0 pt regular; "Activate App Icon" 130.5 pt -> 16.75 pt regular; "Blush" 53.8 pt ->
22.25 pt semibold; "Default" 69.6 pt -> 21.5 pt semibold; caption lines -> 15 pt regular; "01" 22.9 pt -> 20 pt mono).

List screen (for completeness): large title "App Icon Picker" SF Pro 34 pt bold black, ink starts 16.7 pt from the
left; grouped background #EFEEF3; one white rounded row (16.7 pt side inset, ~56 pt tall, top at 167.5 pt) with the
blue 17 pt regular text "Change App Icon".

## 3. Carousel at rest

Order: Default, Blush, Grape, Midnight, Mono, Ocean (6 pages). Centre icon centre is at (193, 148.6) in sheet
coordinates (screen (228, 678) px). Neighbours, measured with a full template fit (position, scale, rotation,
blur sigma, opacity) on rest frames 60, 140, 200, 812:

| property | right neighbour (p = +1) | left neighbour (p = -1) |
|---|---|---|
| centre offset from centre icon | **(+157.7, -63.4) pt** (up-right) | **(-157.7, +63.4) pt** (down-left) |
| direction | 21.9 deg above horizontal | 21.9 deg below horizontal |
| scale | **0.70** (0.697-0.705) | **0.706** |
| rotation | **-69.5 deg** (counter-clockwise) | **-69.3 deg** (also counter-clockwise) |
| blur sigma | 3.7-3.95 pt | 3.3 pt |
| opacity | 0.95-1.0 (treat as 1.0) | 1.0 |

The rotation sign was checked by a full 360 deg scan: -70 deg gives a loss of 296 vs 596 for +20 deg (the
same square outline, but the blurred apple glyph only matches at -70 deg). Both neighbours are rotated the same way.

Clipping: the neighbours are **clipped by the sheet's rounded rectangle**, they never draw outside it. A neighbour's
rotated bounding box is ±61 pt wide, so ~26 pt (about 21 %) of each neighbour is cut off by the left/right sheet
edge. Items at |p| >= 2 are fully outside.

## 4. Paging transition

### Method

Each icon was tracked frame by frame with a template fit: the sharp rest-state icon (alpha-matted from the
video) is translated, rotated, scaled, Gaussian-blurred and alpha-composited over #DEDDE2, and the 6 parameters
are optimised (Powell) against the frame, excluding pixels outside the sheet and pixels of the other icons'
colours. Residuals are 1-3 % RMS. Three transitions were tracked with three icons each:

* T1 (f92-140) swipe left: Default (centre -> left), Blush (right -> centre), Grape (p 2 -> 1).
* T2 (f155-205) swipe left: Blush (centre -> left), Grape (right -> centre), Default (left -> off-screen).
* T3 (f812-850) swipe right: Default (left -> centre), Blush (centre -> right), Grape (p 1 -> 2).

### Result: everything is a pure function of the page position p

Define p for every item as its signed distance from the centre in pages (p = index - scrollPage). With p taken
from the scale (|p| = (1 - scale)/0.2955), the outgoing and incoming icons of the same frame always satisfy
|p_out| + |p_in| = 1 within ±0.006 (scale sum 1.705-1.717 in every frame), the rotation sum is constant
(-69.6 ± 0.15 deg), and the X/Y/blur curves of all six tracks (drag phase and settle phase, both directions)
collapse onto one curve:

| fit | formula (|p| <= 1) | rms |
|---|---|---|
| X (pt) | 218.86 p - 47.41 p\|p\| - 13.61 p^3 | 0.87 pt |
| Y (pt) | -92.38 p\|p\| + 29.21 p^3 | 0.45 pt |
| rotation (deg) | -69.24 \|p\| | 0.41 deg |
| scale | 1 - 0.2925 \|p\| | 0.004 |
| blur sigma (pt) | 0.17 + 3.37 \|p\| (video softness ~0.2 pt included) | 0.16 pt |
| opacity | 0.94-1.02, no trend | n/a |

Per track residuals: X 0.4-1.3 pt, Y 0.3-0.7 pt, rotation 0.3-0.6 deg. So **the transforms are a function of scroll
position only**; there is no time-based animation layered on top.

For |p| > 1 (Grape going 1 -> 1.33 in T1, 1 -> 1.26 in T3) scale, rotation and blur stay **constant** at their
|p| = 1 values (0.70, -69.5 deg, 3.9 pt), and the position continues on the straight line:
X/p = 156.5-161, Y/p = -62.8..-64.8, i.e. **position = p * (157.7, -63.4)**.

### Equivalent geometric description (useful for implementation)

Split the offset into the direction of the line V = (157.7, -63.4) pt (|V| = 170 pt, 21.9 deg up-right) and its normal:

* along the line: u = 170 p + 44.9 p (1 - |p|) (rms 1.1 pt)
* perpendicular (down-right positive): v = 71.2 p (1 - |p|) (rms 0.7 pt)

i.e. **offset(p) = p V + p (1 - |p|) W for |p| <= 1, and p V for |p| > 1**, with W = (68.2, 49.3) pt.
The extra term vanishes at p = 0 and |p| = 1, so the icon **does fly along an arc**: it leaves the centre almost
horizontally (dY/dp = 0 at p = 0, horizontal speed 219 pt per page) and bends onto the 21.9 deg diagonal, bulging up to
17.7 pt off the straight line at |p| = 0.5. The right side curves up, the left side curves down (odd symmetry).

### Mapping table (from the fitted curves)

| \|p\| | X | Y | scale | rotation | blur sigma |
|---|---|---|---|---|---|
| 0.0 | 0.0 | 0.0 | 1.000 | 0.0 | 0.0 |
| 0.1 | 21.4 | -0.9 | 0.971 | -6.9 | 0.34 |
| 0.2 | 41.8 | -3.5 | 0.941 | -13.8 | 0.67 |
| 0.3 | 61.0 | -7.5 | 0.912 | -20.8 | 1.01 |
| 0.4 | 79.1 | -12.9 | 0.883 | -27.7 | 1.35 |
| 0.5 | 95.9 | -19.4 | 0.854 | -34.6 | 1.69 |
| 0.6 | 111.3 | -26.9 | 0.824 | -41.5 | 2.02 |
| 0.7 | 125.3 | -35.2 | 0.795 | -48.5 | 2.36 |
| 0.8 | 137.8 | -44.1 | 0.766 | -55.4 | 2.70 |
| 0.9 | 148.6 | -53.5 | 0.737 | -62.3 | 3.03 |
| 1.0 | 157.8 | -63.1 | 0.707 | -69.2 | 3.37 |

(For negative p, X and Y change sign; scale, rotation and blur do not. Blur column has the video softness removed.)

### Per-frame data, T1 (swipe left; a = Default, b = Blush, c = Grape). X/Y in pt from the centre icon rest position

| frame | t (s) | a p | a X | a Y | a scale | a rot | a sigma | b p | b X | b Y | b scale | b rot | b sigma | c p | c X | c Y | c scale | c rot | c sigma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 92 | 1.517 | +0.000 | -0.0 | -0.6 | 1.009 | +0.0 | 0.46 | +1.000 | +158.5 | -64.1 | 0.697 | -69.9 | 3.69 | – | – | – | – | – | – |
| 94 | 1.550 | -0.011 | -7.3 | -0.4 | 0.999 | -2.5 | 0.50 | +0.989 | +155.6 | -60.7 | 0.710 | -67.4 | 3.69 | – | – | – | – | – | – |
| 96 | 1.583 | -0.070 | -18.1 | +0.1 | 0.983 | -6.1 | 0.54 | +0.930 | +150.8 | -55.8 | 0.728 | -63.5 | 3.53 | – | – | – | – | – | – |
| 98 | 1.617 | -0.127 | -28.7 | +1.1 | 0.967 | -9.8 | 0.69 | +0.873 | +145.3 | -50.9 | 0.747 | -59.6 | 3.31 | – | – | – | – | – | – |
| 100 | 1.650 | -0.196 | -42.0 | +3.0 | 0.947 | -14.4 | 0.85 | +0.804 | +137.7 | -44.6 | 0.767 | -55.3 | 3.07 | – | – | – | – | – | – |
| 102 | 1.683 | -0.262 | -55.1 | +5.6 | 0.927 | -19.2 | 1.03 | +0.738 | +129.3 | -38.5 | 0.787 | -50.5 | 2.74 | – | – | – | – | – | – |
| 104 | 1.717 | -0.331 | -67.4 | +8.8 | 0.908 | -23.6 | 1.22 | +0.669 | +120.3 | -32.7 | 0.809 | -45.9 | 2.49 | – | – | – | – | – | – |
| 106 | 1.750 | -0.410 | -81.4 | +13.2 | 0.885 | -28.9 | 1.43 | +0.590 | +109.0 | -26.3 | 0.832 | -41.0 | 2.21 | – | – | – | – | – | – |
| 108 | 1.783 | -0.483 | -94.0 | +18.1 | 0.864 | -34.0 | 1.67 | +0.517 | +97.4 | -20.8 | 0.854 | -35.7 | 1.90 | – | – | – | – | – | – |
| 110 | 1.817 | -0.562 | -106.5 | +23.8 | 0.841 | -39.3 | 1.90 | +0.438 | +84.3 | -15.4 | 0.877 | -30.2 | 1.57 | – | – | – | – | – | – |
| 112 | 1.850 | -0.608 | -113.3 | +27.4 | 0.827 | -42.2 | 2.01 | +0.392 | +76.7 | -12.8 | 0.891 | -27.4 | 1.45 | – | – | – | – | – | – |
| 114 | 1.883 | -0.767 | -135.1 | +41.2 | 0.780 | -53.4 | 2.51 | +0.233 | +46.9 | -5.0 | 0.938 | -16.3 | 0.94 | +1.232 | +196.1 | -79.0 | 0.710 | -69.7 | 3.93 |
| 116 | 1.917 | -0.801 | -139.1 | +44.6 | 0.768 | -55.7 | 2.70 | +0.199 | +39.9 | -3.6 | 0.947 | -13.8 | 0.80 | +1.198 | +189.8 | -76.3 | 0.705 | -69.9 | 4.03 |
| 118 | 1.950 | -0.862 | -145.4 | +50.2 | 0.749 | -60.0 | 2.91 | +0.138 | +28.1 | -1.8 | 0.963 | -9.6 | 0.52 | +1.138 | +179.9 | -72.4 | 0.704 | -69.7 | 4.00 |
| 120 | 1.983 | -0.902 | -149.1 | +54.1 | 0.735 | -62.5 | 3.00 | +0.098 | +20.1 | -0.9 | 0.973 | -6.8 | 0.42 | +1.098 | +173.2 | -69.5 | 0.703 | -70.0 | 3.98 |
| 122 | 2.017 | -0.933 | -151.8 | +56.9 | 0.726 | -64.8 | 3.18 | +0.067 | +13.9 | -0.4 | 0.982 | -4.6 | 0.36 | +1.067 | +168.1 | -67.4 | 0.701 | -69.7 | 4.01 |
| 124 | 2.050 | -0.952 | -153.5 | +58.8 | 0.720 | -65.8 | 3.24 | +0.048 | +9.6 | -0.2 | 0.987 | -3.1 | 0.33 | +1.048 | +164.2 | -66.1 | 0.697 | -69.1 | 3.96 |
| 126 | 2.083 | -0.966 | -154.8 | +60.3 | 0.716 | -67.4 | 3.28 | +0.034 | +6.7 | -0.1 | 0.991 | -2.0 | 0.26 | +1.034 | +162.2 | -65.0 | 0.699 | -69.5 | 4.00 |
| 128 | 2.117 | -0.976 | -155.8 | +61.3 | 0.714 | -67.9 | 3.31 | +0.024 | +4.3 | -0.0 | 0.995 | -1.3 | 0.22 | +1.024 | +160.2 | -64.4 | 0.700 | -69.4 | 3.96 |
| 130 | 2.150 | -0.984 | -156.5 | +62.0 | 0.711 | -68.4 | 3.22 | +0.016 | +2.9 | -0.0 | 0.997 | -0.7 | 0.25 | +1.016 | +159.1 | -63.9 | 0.699 | -69.7 | 3.96 |
| 132 | 2.183 | -0.990 | -156.9 | +62.5 | 0.709 | -68.6 | 3.24 | +0.010 | +1.9 | +0.0 | 0.998 | -0.4 | 0.05 | +1.010 | +158.3 | -63.6 | 0.699 | -69.5 | 3.98 |
| 136 | 2.250 | -0.998 | -157.5 | +63.1 | 0.706 | -69.2 | 3.28 | +0.002 | +0.5 | +0.0 | 1.001 | -0.0 | 0.03 | +1.002 | +157.1 | -63.1 | 0.698 | -69.6 | 3.98 |
| 140 | 2.317 | -0.998 | -157.7 | +63.3 | 0.706 | -69.3 | 3.28 | +0.002 | +0.0 | +0.0 | 1.000 | -0.0 | 0.26 | +1.002 | +156.8 | -62.9 | 0.700 | -69.4 | 3.95 |

(Grape before f113 is still mostly outside the sheet and could not be fitted reliably.)

### Per-frame data, T3 (swipe right; a = Default coming in from the left, b = Blush leaving to the right, c = Grape 1 -> 2)

| frame | t (s) | a p | a X | a Y | a scale | a rot | a sigma | b p | b X | b Y | b scale | b rot | b sigma | c p | c X | c Y | c scale | c rot | c sigma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 818 | 13.617 | -1.000 | -159.0 | +63.1 | 0.709 | -69.3 | 3.34 | +0.000 | +1.0 | -0.6 | 1.009 | -0.1 | 0.11 | +1.000 | +158.9 | -64.3 | 0.705 | -69.5 | 3.87 |
| 820 | 13.650 | -0.943 | -153.5 | +57.1 | 0.728 | -64.9 | 3.23 | +0.057 | +13.6 | -0.9 | 0.990 | -4.5 | 0.02 | +1.057 | +169.0 | -68.3 | 0.707 | -69.6 | 3.91 |
| 822 | 13.683 | -0.848 | -144.2 | +48.6 | 0.757 | -58.7 | 3.03 | +0.152 | +31.8 | -2.6 | 0.963 | -10.8 | 0.51 | +1.152 | +183.6 | -74.0 | 0.708 | -69.5 | 3.92 |
| 824 | 13.717 | -0.739 | -130.8 | +38.3 | 0.788 | -51.2 | 2.64 | +0.261 | +53.3 | -6.3 | 0.929 | -18.4 | 0.89 | +1.261 | +201.3 | -81.2 | 0.712 | -69.8 | 3.89 |
| 826 | 13.750 | -0.600 | -111.3 | +26.4 | 0.830 | -41.5 | 2.11 | +0.400 | +78.8 | -13.4 | 0.889 | -27.9 | 1.38 | – | – | – | – | – | – |
| 828 | 13.783 | -0.506 | -96.7 | +19.4 | 0.857 | -35.3 | 1.83 | +0.494 | +94.6 | -19.4 | 0.860 | -34.3 | 1.79 | – | – | – | – | – | – |
| 830 | 13.817 | -0.369 | -73.2 | +10.6 | 0.897 | -25.9 | 1.43 | +0.630 | +115.9 | -29.9 | 0.820 | -43.6 | 2.29 | – | – | – | – | – | – |
| 834 | 13.883 | -0.194 | -40.7 | +2.9 | 0.948 | -14.2 | 0.90 | +0.806 | +138.7 | -45.0 | 0.767 | -55.6 | 2.87 | – | – | – | – | – | – |
| 838 | 13.950 | -0.112 | -24.0 | +0.9 | 0.969 | -8.2 | 0.67 | +0.888 | +147.1 | -52.3 | 0.739 | -61.6 | 3.27 | – | – | – | – | – | – |
| 842 | 14.017 | -0.051 | -12.0 | +0.3 | 0.984 | -4.2 | 0.57 | +0.949 | +152.2 | -57.6 | 0.718 | -65.2 | 3.35 | – | – | – | – | – | – |
| 846 | 14.083 | -0.018 | -5.8 | +0.1 | 0.992 | -1.9 | 0.55 | +0.982 | +154.7 | -60.2 | 0.707 | -67.4 | 3.42 | – | – | – | – | – | – |
| 850 | 14.150 | -0.001 | -2.4 | +0.0 | 0.997 | -0.8 | 0.54 | +0.999 | +156.0 | -61.8 | 0.702 | -68.5 | 3.45 | – | – | – | – | – | – |

Note that in T3 the icon leaving to the right rotates counter-clockwise (0 -> -69 deg) and the icon arriving from
the left un-rotates clockwise (-69 -> 0 deg): rotation depends on |p|, not on p.

### Drag vs settle, settle curve

Scroll progress (pages) per frame:

* T1: 94-107 constant finger speed ~0.032 pages/frame (1.9 pages/s); release around f108-113 (speed rises to
  ~0.05-0.06 pages/frame, partly a recording stutter); then decays: remaining distance 0.20 (f116), 0.138 (118),
  0.098 (120), 0.067 (122), 0.048 (124), 0.034 (126), 0.024 (128), 0.016 (130), 0.010 (132), 0.005 (134), 0.002 (136).
  The remaining distance shrinks by 0.70 every 2 frames -> exponential with **k = 9.8-10.4 /s (tau ~0.10 s)**.
* T2: tail k = 10.2-10.9 /s; T3: tail k ~8-10 /s.
* Critically damped spring fits of the tail: omega 13.8-16.0 rad/s, zeta 0.89-1.0.
* Release -> within 0.5 % of the page: ~0.40 s (T1 f112 -> 134, T2 f173 -> 191, T3 f826 -> 849).
* **No overshoot** in any transition (progress peaks at 0.998-1.000, scale never exceeds 1.0006).

k = 10/s is exactly UIScrollView's `.fast` deceleration (0.99 per ms -> 10.05 /s), i.e. this is a plain paging
scroll view, and the effects are applied on top as a function of p.

Not observable: how far the finger moved per page. The centre icon moves 219 pt per page near p = 0; a standard
paging scroll view inside the sheet would use the container width (386 pt) per page.

## 5. Counter, label and button transitions

All three switch at the same moment: when the nearest page changes (|p| crosses 0.5).

### Name label (scroll-driven, not time-driven)

The label shows the name of the nearest page and is offset and faded by that page's p (pc in [-0.5, 0.5]):

| pc | 0 | ±0.1 | ±0.2 | ±0.26 | ±0.3 | ±0.33 | ±0.38 | ±0.41 | ±0.43 | >=0.45 |
|---|---|---|---|---|---|---|---|---|---|---|
| X offset (pt) | 0 | ±15 | ±30 | ±40 | ±45 | ±49 | ±56 | ±62 | ±64 | hidden |
| opacity | 1.00 | 0.88 | 0.70 | 0.55 | 0.46 | 0.41 | 0.29 | 0.23 | 0.16 | 0 |

* offset X = **148 pt x pc** (moves with the scroll, slower than the icon's 219 pt/page)
* opacity = **1 - (2|pc|)^1.3** (fits all points within 0.03); no blur, no scale
* the old name is gone and the new one appears at the 0.5 crossing (f108 -> f109 in T1, f828 -> f829 in T3)

### Counter digits

Only the digit that changes animates ("0" stays). Like SwiftUI `.contentTransition(.numericText(value:))`:

* increasing (01 -> 02): old digit moves **up**, blurs and fades; new digit comes **from below**
* decreasing (02 -> 01): old digit moves **down**; new digit comes **from above**
* T1: trigger f109, visible motion f112 -> crossover f116-118 -> settled f124-125 (~0.22 s of motion, ~0.27 s total)
* T3: trigger f829, motion f832 -> crossover f836-837 -> settled f843 (~0.2 s)
* travel ~0.5-0.6 em (10-12 pt), blur up to ~3 pt at the crossover, ink at crossover ~60 % of rest
* the "/ 06" part does not animate

### Button state change ("Currently Active" <-> "Activate App Icon")

Fill colour of the button over T1 (it starts at the same f109 trigger):

| frame | 108 | 109 | 112 | 114 | 116 | 117 | 118 | 119 | 120 | 121 | 123 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| fill | #CFCED3 | #BDBCC1 | #A8A9B0 | #97A6B9 | #709CCB | #5696D9 | #368EE5 | #0487EF | #0282F6 | #007EFC | #007CFE |

* fill transition ~13 frames (0.22 s), ease-in-out, with a darker grey first step (glass tint change)
* text: blur-replace. Old text scales down slightly, blurs and fades out over f112-116; new text fades in from
  f117 starting at ~0.8x scale and blurred (ink width 118 -> 147 px over f118-132), sharp by ~f121, full size by ~f128
* T3 (Blush active -> Default) shows the identical timing (f829 -> f842)

## 6. Other details

### Activation flow

* Press "Activate App Icon": button grows to ~1.055x and lightens to #008DFE over 0.12 s, shrinks back on release
  (f399-416). No haptic-style bounce elsewhere.
* The iOS system alert ("You have changed the icon for "App Icon".", OK) appears on release (f415), fades/zooms in over
  ~0.17 s and deepens the dim to ~40 % black. OK dismisses it in ~0.15 s (f489-498).
* The button does **not** switch to "Currently Active" before the sheet closes; the sheet auto-dismisses ~0.28 s
  after the alert is gone (f515), using the dismiss spring above. Reopening the sheet starts on the active icon and
  shows "Currently Active" there.

### Icon colours (sampled from the sharp centre icon)

| icon | background | glyph (apple) |
|---|---|---|
| Default | #01D886 | #003825 |
| Blush | #FCA5BE | #7D1837 |
| Grape | #7941FC | #EADEFB |
| Midnight | #1F1F26 (top #22232A, bottom #1D1D24) | #F5E8E3 |
| Mono | #F3F2F6 (near white) | #18171C |
| Ocean | #016A88 | #B1F3FA |

## Implementation spec

All values in logical pixels (pt), for a 402 x 874 screen.

### Sheet

```dart
const kSheetInset = 8.0;                 // left, right, bottom
const kSheetHeight = 417.0;              // width = screenWidth - 16 (386 on 402)
const kSheetTopRadius = 35.0;
const kSheetBottomRadius = 52.0;         // concentric with the device corner
const kSheetColor = Color(0xFFDEDDE2);
const kSheetTopHighlight = Color(0xFFEAE9EE); // 1 px inner rim at the top
const kSheetHairline = Color(0x2E000000);    // 1 px outer edge, ~18 % black
const kScrimColor = Color(0x38000000);       // black 22 %
// Scrim opacity follows the sheet: 0.22 * (1 - offset / hiddenOffset)
// Hidden offset = kSheetHeight + kSheetInset (425): sheet starts fully below the screen
final kSheetOpenSpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 272, ratio: 0.97); // omega 16.5
final kSheetCloseSpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 335, ratio: 1.0);  // omega 18.3
// Open ~0.45 s, close ~0.30 s, no overshoot. List behind: no scale, no blur.
// Clip the carousel to the sheet's rounded rect.
// Over-drag upwards: rubber-band the height (max ~77 pt), let the icon grow ~0.46 pt per pt, spring back ~0.27 s.
const kAutoDismissAfterAlert = Duration(milliseconds: 300);
```

### Sheet contents (y from sheet top, x from sheet left, sheet 386 wide)

```dart
// Close button
const kCloseSize = 44.0;                 // glass circle, centre (35, 35) -> 13 pt from top/left
const kCloseFill = Color(0xFFEEEDF1);
const kCloseIcon = 17.0;                 // xmark, medium weight, black, ink ~12 pt
// Counter (centred horizontally, big-digit baseline at y = 38.8)
const kCounterBig = TextStyle(fontFamily: 'SF Mono', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF007AFF));
const kCounterSmall = TextStyle(fontFamily: 'SF Mono', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF737277));
const kCounterGap = 3.0;                 // between "01" and "/ 06"
const kCounterSmallBaselineDrop = 2.6;   // small text baseline sits 2.6 pt lower
// Centre icon
const kIconSize = 135.0;                 // centre at y = 148.6 (top 81)
const kIconCornerRadius = 30.0;          // continuous / squircle (or 36 with a plain circular RRect)
// Name label: baseline y = 252 (cap top 236.7, 20.7 below the icon)
const kNameStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF000000));
// Caption: baselines y = 300.2 and 324.0, centred
const kCaptionStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 23.8 / 15, color: Color(0xFF646267));
// Button
const kButtonTop = 348.7, kButtonHeight = 46.0, kButtonSideInset = 28.0, kButtonBottomGap = 22.4; // capsule
const kButtonActiveFill = Color(0xFF007AFF), kButtonActiveText = Color(0xFFFFFFFF);
const kButtonPressedFill = Color(0xFF008DFE), kButtonPressedScale = 1.055; // 120 ms in, 90 ms out
const kButtonDisabledFill = Color(0xFFCFCED3), kButtonDisabledText = Color(0xFF77767B);
const kButtonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
```

### Carousel mapping (p = itemIndex - page, page from a paging scroll position)

```dart
const kNeighbourOffset = Offset(157.7, -63.4);   // p = +1 (left neighbour is the negative)
const kArcBulge = Offset(68.2, 49.3);             // extra offset * p * (1 - |p|)
const kNeighbourScale = 0.705;
const kNeighbourRotationDeg = -69.3;              // counter-clockwise, same sign on BOTH sides
const kNeighbourBlurSigma = 3.5;                  // Gaussian sigma in pt at |p| >= 1

Offset offsetFor(double p) {
  final a = p.abs();
  if (a >= 1) return kNeighbourOffset * p;        // straight line beyond the neighbours
  return kNeighbourOffset * p + kArcBulge * (p * (1 - a));
  // Equivalent polynomial (rms 0.9 / 0.45 pt):
  // x = 218.86*p - 47.41*p*a - 13.61*p*p*p ;  y = -92.38*p*a + 29.21*p*p*p
}
double t(double p) => p.abs().clamp(0.0, 1.0);
double scaleFor(double p) => 1 - (1 - kNeighbourScale) * t(p);           // linear
double rotationFor(double p) => kNeighbourRotationDeg * t(p) * math.pi / 180; // radians
double blurFor(double p) => kNeighbourBlurSigma * t(p);                  // ImageFilter.blur sigma
const kNeighbourOpacity = 1.0;                    // no fade
// Transform order per item: translate(offsetFor(p)) * rotate(rotationFor(p)) * scale(scaleFor(p)), about the icon centre,
// then ImageFilter.blur(sigmaX: blurFor(p), sigmaY: blurFor(p)). Only build |p| < 2.
```

### Paging physics

```dart
// Pure function of scroll position: no time-based tweening of the icons.
// Release settle: exponential tail k = 10/s (UIScrollView .fast), 0.40 s from release to rest, no overshoot.
final kPageSettleSpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 225, ratio: 1.0); // omega 15
// Page extent for drag: the scroll view width (386 pt) if native-like; 219 pt makes the centre icon track the finger 1:1.
// Fling: 3 pages in ~0.55 s was observed, so allow multi-page flings.
```

### Label, counter, button

```dart
// Index = page.round(). pc = index - page, in [-0.5, 0.5].
const kLabelTravel = 148.0;                       // label dx = kLabelTravel * pc
double labelOpacity(double pc) => 1 - math.pow((2 * pc.abs()).clamp(0.0, 1.0), 1.3).toDouble();
// Counter: on index change, roll only the changed digits.
const kCounterDuration = Duration(milliseconds: 260);
const kCounterCurve = Curves.easeOutCubic;
const kCounterTravel = 11.0;                       // ~0.55 em; up when increasing, down when decreasing
const kCounterBlurMax = 3.0;                       // blur at the crossover, fade out/in
// Button state change on index change:
const kButtonColorDuration = Duration(milliseconds: 220);
const kButtonColorCurve = Curves.easeInOut;        // grey -> blue (via a slightly darker grey first)
const kButtonTextOutDuration = Duration(milliseconds: 120);   // scale 1 -> 0.85, blur 0 -> 4, fade out
const kButtonTextInDuration = Duration(milliseconds: 250);    // scale 0.8 -> 1, blur 4 -> 0, fade in (easeOut)
```

### Icon colours

```dart
const kIcons = [
  ('Default',  Color(0xFF01D886), Color(0xFF003825)),
  ('Blush',    Color(0xFFFCA5BE), Color(0xFF7D1837)),
  ('Grape',    Color(0xFF7941FC), Color(0xFFEADEFB)),
  ('Midnight', Color(0xFF1F1F26), Color(0xFFF5E8E3)),
  ('Mono',     Color(0xFFF3F2F6), Color(0xFF18171C)),
  ('Ocean',    Color(0xFF016A88), Color(0xFFB1F3FA)),
];
```

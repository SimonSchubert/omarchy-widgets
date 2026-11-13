# Daily learning

A full-page OWL face with Merriam-Webster's word of the day and a daily selection of sourced college mathematics problems from Mathematics Stack Exchange. Scroll to see diagrams, attribution and links to the original entry or solution. Colors follow the launcher theme.

Requires Arch Linux with `nodejs` and `npm`, both declared in `requires` and installed through pacman. All helper code and a pinned npm lockfile are embedded in `face.owl`; no separately copied scripts, account or API key are needed. On first use, the inline command runs `npm ci --ignore-scripts` to install `mathjax-full` 3.2.1 and `sharp` 0.35.5, with their integrity-checked dependencies from registry.npmjs.org, into a versioned directory under `~/.cache/daily-learning`. This initial setup needs an internet connection and can take a few minutes. npm lifecycle scripts, audit and funding requests are disabled. Later refreshes reuse that installation.

The face fetches Merriam-Webster and Mathematics Stack Exchange and caches their responses and generated formula images in `~/.cache/daily-learning` for offline reading after initial setup. A failed refresh keeps previously cached content and shows an error. The refresh button retries failed requests; successfully cached selections remain fixed for the day.

Equations use MathJax's TeX-to-SVG layout and are rasterized locally with sharp as transparent PNG masks, placed between the original text passages. TeX spacing and grouping are preserved, with no MathText substitutions, manual line splitting or zoom interface. OWL applies the active theme foreground at display time, so cached images follow subsequent theme changes. Wide expressions scale to the card width. A rendering or setup error leaves the source text and source link available. Math selections rotate among geometry, calculus, linear algebra, differential equations, integration and optimization.

## Content attribution

The MIT license below applies to this face's code, not to fetched third-party content. Word entries belong to Merriam-Webster. Mathematics Stack Exchange contributions retain their original authors and Creative Commons licenses, displayed in the face alongside the source link. Local typesetting modifies formatting; diagrams remain linked to their original hosts.

## MIT License

Copyright (c) 2026 Virrann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

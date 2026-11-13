# Daily learning

A full-page OWL face with Merriam-Webster's word of the day and a daily selection of sourced college mathematics problems from Mathematics Stack Exchange. Scroll to see diagrams, attribution and links to the original entry or solution. Colors follow the launcher theme.

Requires Arch Linux with `python` and `python-matplotlib`, both declared in `requires` and installed through pacman. All executable code is included in `face.owl`: no Node.js, npm, pip, external helper scripts or downloaded code. The inline Python command fetches the two public sources and caches their responses and generated formula images in `~/.cache/daily-learning` for offline reading. No account or API key is needed. A failed refresh keeps previously cached content and shows an error. The refresh button retries failed requests; successfully cached selections remain fixed for the day.

Equations are rendered locally with Matplotlib MathText as transparent PNG masks. OWL applies the current theme foreground at display time, so cached images also follow theme changes. MathText supports a subset of LaTeX: unsupported expressions remain visible as source TeX, with a notice linking readers to full typesetting and community answers. A failed equation does not hide the rest of the content. Wide expressions scale to the card width. Math selections rotate among geometry, calculus, linear algebra, differential equations, integration and optimization.

## Content attribution

The MIT license below applies to this face's code, not to fetched third-party content. Word entries belong to Merriam-Webster. Mathematics Stack Exchange contributions retain their original authors and Creative Commons licenses, displayed in the face alongside the source link. MathText rendering and source-TeX fallbacks modify formatting; diagrams remain linked to their original hosts.

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

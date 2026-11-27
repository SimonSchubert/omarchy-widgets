# Taskwatch

A standalone home-screen widget for watching processes and memory, and ending a
process when you need to. It is the process-and-memory part of the control face
on its own, with none of the face's other panels.

## Features

- **Memory gauge** with used/total RAM, a swap line, and a CPU gauge with core count.
- **Recent CPU, not lifetime average**: two `/proc` snapshots are compared, so a
  process that just woke up shows as busy. A sparkline keeps the last twelve
  samples (about three minutes). Snapshots are compared with the previous run
  rather than with a snapshot taken inside the poll, so the widget does not
  sleep in a shared shell.
- **Process list**: the twelve busiest processes by recent CPU, each with its
  PID, resident memory and CPU percentage. Scroll for more.
- **Two-step termination**: tap a process to select it, then tap `term`
  (`kill -TERM`) or `kill -9` (`kill -KILL`). Only the selected row shows the
  buttons. The list refreshes after the signal.
- **Manual refresh** (`↻`) and a **full-screen view** (`⤢`).

## Install and use

Install from the store, or add `widget.owl` to your widgets folder. The tile is
6×10 cells. Tap `↻` to refresh immediately; `pr` also polls every 15 seconds and
memory once a minute.

Requires `procps-ng` (for `free`); the process sampler itself uses `awk`,
`cat`, `nproc`, `sort` and `head` from the base system.

## Credits

The process sampler, memory reader, gauges and process panel — including the
two-step `term` / `kill -9` controls — are adapted from **SimonSchubert's
control face**, `faces/simonschubert/control/face.owl` in the
[omarchy-widgets](https://github.com/SimonSchubert/omarchy-widgets) store. The
idea of a dedicated task watcher came from an earlier local `taskwatch` widget.

Packaged and published by **CoderCat346**.

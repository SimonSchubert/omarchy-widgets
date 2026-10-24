# Offgrid solar for Victron VRM

A self-contained OWL widget for solar power, battery state of charge, battery power, AC output, DC loads and solar yield. Requires OWL 5 or later. Uses Android HTTP directly; no Linux installation, packages or helper scripts are needed.

## Install and connect

Install through the widget store when available, import a shared widget link, or copy widget.owl into ~/.config/omalauncher/widgets/ under a unique .owl filename.

1. In VRM, select **Preferences → Integrations**, then click **Add** to create an API access token.
2. Follow the VRM prompts to create the token and copy its value. The account/token must have access to the installation you want to monitor.
3. Open that installation in VRM. Copy the numeric ID from its dashboard URL (the number after `/installation/`).
4. In the widget, tap **set up**, enter the installation ID and paste the token, then tap **connect**. The dashboard reports whether the connection succeeds.

The setup screen also includes a **get a VRM token** button linking to https://vrm.victronenergy.com/access-tokens.

Tap the tile for details. **connection settings** lets you replace the connection or clear its saved details. When replacing credentials, enter a token again; the existing token is not displayed.

Settings persist locally in launcher state, separately from the source. The token is plain text on the local device and is visible while entering it. Share only widget.owl (or its launcher share link), not launcher state or device backups. New installations start with blank settings.

## Readings

Checks VRM once per minute while the widget is active. Measurements follow your GX upload interval; readings over 30 minutes old are flagged. Missing measurements appear as an ellipsis. Battery power is positive when charging and negative when discharging.

Solar power uses the DC-coupled system value, falling back to solar charger PV values. Yield totals the connected solar chargers. AC output totals available phases. Charger peaks is the sum of individual charger daily peaks, not necessarily the simultaneous system peak. AC-coupled solar generation is not included. Daily figures refer to the device's reported day. The timestamp follows the battery SOC record.

## Resizing and charts

Version 1.2 defaults to 3×3 and allows resizing down to 3×2. It uses the tile’s actual width and height rather than assuming each grid cell is the same size on every device. Small tiles show the essential readings; wider tiles put solar and battery side by side. Text sizes increase within bounds as space grows. Resizing an existing tile is still done with the launcher’s resize controls.

Tap the tile, then **chart settings**. Choose **off**, **solar**, **consumption**, or **battery level**, and **24 hours**, **week** (7 days), or **month** (30 days). Selections persist locally. New installations start with the chart off.

When enabled, the chart grows into spare tile height. On short tiles it is hidden to keep the key readings legible, but is available in the full-screen view. Solar production and consumption use bars in kWh per hour (24-hour and week views), or kWh per day (month view). Battery charge uses a line of average percentages, on a 0–100% axis. Missing intervals are left blank, not invented or filled with zeros.

Charts use VRM’s live_feed historical series (total_solar_yield, total_consumption and bs), refreshed every 15 minutes. The plot ends at the latest quarter-hour boundary. Availability and completeness depend on the installation’s uploaded history and VRM energy counters. Historical solar totals follow VRM’s total_solar_yield series and can differ from the DC-only instantaneous solar reading. Battery history uses interval averages, so short fluctuations can be smoothed. The chart is not an on-device recording and can show history from before widget installation.

## Sharing and publishing

This folder contains no personal installation ID or token. For the widget store, submit widget.owl, preview.png and this README under widgets/<github-username>/victron/. The widget declares MIT licensing and store metadata.

For a local-only install, removing a widget moves it to the launcher's .removed folder; move it back to restore it.

## Screenshot

![Victron solar dashboard](preview.png)

# Daybook calendar

An office booking calendar: bookings with start and end times, a red warning when two bookings overlap,
a clients list (with the agency each client bills to), Jewish holidays and Hebrew dates in the grid,
monthly hours per client and agency with print / save as PDF, and upload of client lists from Excel, Word or PDF.

- `index.html` / `page.html`: the whole front end (one file, no build step). `index.html` is the same file, served by GitHub Pages.
- `worker.js`: the API, a Cloudflare Worker with a D1 (SQLite) database.
- `deploy.sh`: deploys the worker to Cloudflare and pushes this repository (which updates the GitHub Pages copy).
- `gen-holidays.mjs`: makes the holiday table baked into the page (uses @hebcal/core).

The app opens only with its private access link; the access key and the data are not in this repository.

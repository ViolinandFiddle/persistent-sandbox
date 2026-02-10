# Zero-Failure Reference Fetcher (Package)

This package consolidates the robust, "Zero-Failure" reference acquisition logic into a reusable tool for Antigravity.

## Features
- **True Headless Chrome**: Leverages `google-chrome-stable` with `--headless` and `--print-to-pdf` to bypass bot detection and rendering paywalls (authentication permitting).
- **Universal PDF**: Converts all targets to PDF. If a direct PDF link isn't available, capturing the HTML landing page as a PDF is the fallback.
- **Local Recovery**: Scans a designated "old" directory to recover existing files before attempting download.
- **Smart Retries**: `urllib` -> `Headless Chrome` -> `Failure Logging`.

## Usage

1.  Place your target references in `input/references.json`.
2.  Run `python src/main.py`.
3.  Check `logs/acquisition_status.md` and `output/`.

## Dependencies
- `google-chrome-stable` (Must be in $PATH)
- Python 3+ (Standard Lib only: `urllib`, `subprocess`, `json`, etc.)

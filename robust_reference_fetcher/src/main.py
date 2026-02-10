import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request

# Add local src to path if needed, though usually run as python src/main.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import chrome_lib
import recov_lib
import summary_lib

# Configuration
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
ssl_context = ssl._create_unverified_context()


def clean_filename(name):
    clean = "".join(
        [c for c in name if c.isalpha() or c.isdigit() or c in " -_"]
    ).strip()
    return clean.replace(" ", "_") + ".pdf"


def log(msg, log_file):
    ts = time.strftime("%H:%M:%S")
    entry = f"[{ts}] {msg}"
    print(entry)
    with open(log_file, "a") as f:
        f.write(entry + "\n")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Robust Reference Fetcher")
    parser.add_argument("--input", help="Path to input JSON file")
    args = parser.parse_args()

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_file = (
        args.input if args.input else os.path.join(base_dir, "input", "references.json")
    )
    output_dir = os.path.join(base_dir, "output")
    log_file = os.path.join(base_dir, "logs", "acquisition_status.md")
    summary_log = os.path.join(base_dir, "logs", "references-summaries.md")
    # Optional: recovery dir. Defaulting to user's specified path in prior task
    recovery_dir = "/workspaces/water-modeling/Brine_References_old"

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if not os.path.exists(os.path.dirname(log_file)):
        os.makedirs(os.path.dirname(log_file))

    # Load References
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    with open(input_file, "r") as f:
        data = json.load(f)

    references = data.get("references", {})
    recovery_map = data.get("recovery_map", {})
    overrides = data.get("overrides", {})

    log("--- STARTING ROBUST FETCH ---", log_file)

    # Initialize summary log headers if new
    if not os.path.exists(summary_log):
        with open(summary_log, "w") as f:
            f.write(
                "# PhD-Level Reference Summaries\n\n| Reference | Summary | Key Findings |\n| :--- | :--- | :--- |\n"
            )

    for name, doi_or_url in references.items():
        filename = clean_filename(name)
        dest = os.path.join(output_dir, filename)

        # 1. Recovery
        recovered, source_file = recov_lib.attempt_recovery(
            name, recovery_dir, dest, recovery_map
        )
        if recovered:
            log(f"🟢 RECOVERED: {name} (from {source_file})", log_file)
            continue

        # 2. Resolve URL
        if name in overrides:
            url = overrides[name]
        elif doi_or_url.startswith("http"):
            url = doi_or_url
        else:
            url = "https://doi.org/" + doi_or_url

        log(f"Fetching: {name} -> {url}", log_file)

        # 3. Try urllib (Standard)
        urllib_success = False
        # If it gives HTML, we switch to Chrome to print that HTML to PDF.
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, context=ssl_context, timeout=15) as resp:
                ctype = resp.info().get_content_type()
                if "pdf" in ctype or resp.geturl().endswith(".pdf"):
                    with open(dest, "wb") as f:
                        f.write(resp.read())
                    log(f"🟢 DOWNLOADED (urllib PDF): {name}", log_file)
                    urllib_success = True
                    continue
                else:
                    log(
                        f"  -> urllib returned HTML ({ctype}). Forced switch to Chrome PDF...",
                        log_file,
                    )
        except Exception as e:
            log(f"  -> urllib failed ({e}). Switching to Chrome...", log_file)

        # 4. Chrome Fallback (The "True Headless" Hammer)
        if not urllib_success:
            if chrome_lib.fetch_pdf_via_chrome(url, dest):
                log(f"🟢 DOWNLOADED (Chrome PDF): {name}", log_file)
            else:
                log(f"🔴 FAILED: {name}", log_file)

        # 5. Summarization
        if os.path.exists(dest):
            log("  -> Extracting text for summary...", log_file)
            raw_text = summary_lib.extract_text(dest)
            # Add entry to summary log
            with open(summary_log, "a") as f:
                f.write(f"| **{name}** | `SUMMARIZE_ME` | [PDF](file://{dest}) |\n")
            log(f"🟢 READY FOR SUMMARY: {name}", log_file)
        else:
            log(f"🔴 FAILED: {name}", log_file)

        time.sleep(1)


if __name__ == "__main__":
    main()

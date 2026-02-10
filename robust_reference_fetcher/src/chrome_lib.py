import os
import subprocess


def fetch_pdf_via_chrome(url, output_path, chrome_binary="google-chrome", timeout=30):
    """
    Uses Headless Chrome to print a URL to PDF.
    Returns True if successful and file exists > 1KB.
    """
    cmd = [
        chrome_binary,
        "--headless",
        "--disable-gpu",
        "--no-sandbox",
        f"--print-to-pdf={output_path}",
        "--virtual-time-budget=10000",  # Allow 10s for JS loading
        url,
    ]

    try:
        # Check binary existence (optional, or rely on FileNotFoundError)
        # subprocess.run([chrome_binary, "--version"], check=True, stdout=subprocess.DEVNULL)

        # Execute
        subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=True,
        )

        if os.path.exists(output_path) and os.path.getsize(output_path) > 1000:
            return True
        return False

    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
        subprocess.TimeoutExpired,
    ):
        # Caller handles logging
        return False

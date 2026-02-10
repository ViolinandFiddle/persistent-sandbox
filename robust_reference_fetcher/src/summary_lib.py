try:
    from pypdf import PdfReader
except ImportError:
    PdfReader = None


def extract_text(pdf_path, max_pages=5):
    """
    Extracts text from the first few pages of a PDF.
    """
    if not PdfReader:
        return "ERROR: pypdf not installed."

    try:
        reader = PdfReader(pdf_path)
        text = ""
        # Get first few pages for context (PhD level summary usually needs Intro/Abstract/Methods)
        for i in range(min(max_pages, len(reader.pages))):
            text += reader.pages[i].extract_text() + "\n"
        return text[:10000]  # Limit to 10k chars for token efficiency
    except Exception as e:
        return f"ERROR: Could not extract text -> {e}"


def generate_phd_summary(text, name):
    """
    This function acts as a placeholder for a "Self-Call" or
    it simply formats the text for the AGENT to process.
    Because the agent generates the summary, this function triggers the
    'Summary Needed' flag in the log.
    """
    # In a real automated pipeline, we'd call an LLM API here.
    # Within Antigravity, the Agent (Me) will fulfill these summaries manually
    # for the first batch, or I'll implement a 'summary_needed' tag.
    return f"PENDING_SUMMARY_FOR_{name}"

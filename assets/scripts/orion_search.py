#!/usr/bin/env python3
import argparse
import html
import re
import sys
import urllib.parse
import urllib.request

RESULT_RE = re.compile(
    r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>', re.S
)
SNIPPET_RE = re.compile(r'class="result__snippet"[^>]*>(.*?)</a>', re.S)
TAG_RE = re.compile(r"<[^>]+>")
# DuckDuckGo answers a bare client with its "anomaly" bot page, so the request has to look
# like a browser.
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "identity",
    "Connection": "close",
}


def real_url(href):
    """DuckDuckGo links results through /l/?uddg=<target>; hand the model the target."""
    href = html.unescape(href)
    if "uddg=" in href:
        target = urllib.parse.parse_qs(urllib.parse.urlparse(href).query).get("uddg")
        if target:
            return target[0]
    if href.startswith("//"):
        return "https:" + href
    return href


def search_web(query, page_num):
    # Plain HTTP: launching a whole headless Firefox to read one HTML page costs a second and
    # ~300 MB per search. The browser is only needed for read_webpage, which runs JavaScript.
    url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote_plus(query)
    request = urllib.request.Request(url, headers=HEADERS)

    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            body = response.read().decode("utf-8", "replace")
    except Exception as e:
        return f"Error during web search: {str(e)}"

    titles = RESULT_RE.findall(body)
    snippets = [TAG_RE.sub("", s) for s in SNIPPET_RE.findall(body)]

    start_idx = (page_num - 1) * 5
    end_idx = start_idx + 5

    results = []
    for i, (href, title) in enumerate(titles[start_idx:end_idx]):
        snippet = (
            html.unescape(snippets[start_idx + i]).strip()
            if start_idx + i < len(snippets)
            else ""
        )
        title = html.unescape(TAG_RE.sub("", title)).strip()
        if title:
            results.append(f"Title: {title}\nURL: {real_url(href)}\nSnippet: {snippet}")

    if not results:
        return "No useful results found for this page."

    return "\n\n".join(results)


def read_webpage(url):
    # Only the web. Without this a page (or the model) could point this at file:///home/... and
    # the text would be sent to the provider as a tool result.
    parsed = urllib.parse.urlparse(url)
    host = (parsed.hostname or "").lower()
    if parsed.scheme not in ("http", "https"):
        return f"Cannot read {url}: only http and https URLs are allowed."
    if (
        host in ("localhost", "::1")
        or host.startswith("127.")
        or host.endswith(".local")
    ):
        return f"Cannot read {url}: local addresses are not allowed."

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        try:
            browser = p.firefox.launch(headless=True)
            page = browser.new_page()
            page.goto(url, timeout=15000)

            # Extract main text body, strip scripts and styles
            text = page.evaluate("""() => {
                const elementsToRemove = document.querySelectorAll('script, style, nav, footer, header, aside');
                elementsToRemove.forEach(el => el.remove());
                return document.body.innerText;
            }""")

            browser.close()

            # Truncate text to avoid blowing up the context window
            text = text.strip()
            if len(text) > 10000:
                text = text[:10000] + "\n\n[Content truncated due to length]"

            return text if text else "Could not extract text from this page."

        except Exception as e:
            return f"Error reading webpage: {str(e)}"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["search", "read"], required=True)
    parser.add_argument("--query", type=str, help="Search query")
    parser.add_argument("--page", type=int, default=1, help="Page number (1-indexed)")
    parser.add_argument("--url", type=str, help="URL to read")

    args = parser.parse_args()

    if args.mode == "search":
        if not args.query:
            print("Error: --query is required for search mode")
            sys.exit(1)
        print(search_web(args.query, args.page))
    elif args.mode == "read":
        if not args.url:
            print("Error: --url is required for read mode")
            sys.exit(1)
        print(read_webpage(args.url))

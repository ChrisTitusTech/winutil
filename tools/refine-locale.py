#!/usr/bin/env python3
"""Refine machine-translated locale files using Gemini API.

Sends batches of (English original + machine translation) pairs to Gemini
for semantic refinement, preserving software names and technical terms.

Usage:
    python tools/refine-locale.py --lang zh-TW --api-key YOUR_KEY
"""

import json
import re
import sys
import time
import argparse
import urllib.request
import urllib.error
from pathlib import Path

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

SYSTEM_PROMPT = """You are a professional translator specializing in Windows system utilities and software tools.
Your task: refine machine-translated zh-TW (Traditional Chinese, Taiwan) translations for a Windows utility app called WinUtil.

Rules:
1. NEVER translate software names: Edge, Brave, OneDrive, Copilot, Xbox, PowerShell, Winget, Chocolatey, Hyper-V, WSL, DirectPlay, WMP, NFS, Teredo, IPv4, IPv6, FOSS, BSoD, OBS, VLC, Git, Docker, etc.
2. NEVER translate brand names: Microsoft, Adobe, Google, Mozilla, etc.
3. Use Taiwan-style Traditional Chinese (台灣繁體中文), not Hong Kong or Mainland style.
4. Use standard Windows Traditional Chinese terminology (e.g., 檔案總管 not 資源管理器, 登錄 not 註冊表).
5. Keep translations concise - this is UI text, not documentation.
6. For Content fields (button/checkbox labels), keep them SHORT (under 30 chars if possible).
7. For Description fields, be clear and informative but not verbose.
8. Return ONLY valid JSON - no markdown, no explanation, no code fences.

Input format: JSON object with entries like:
{
  "id": { "en": "English original", "mt": "machine translation" }
}

Output format: JSON object with ONLY the refined translations:
{
  "id": "refined translation"
}

If the machine translation is already good, return it unchanged."""


def call_gemini(api_key: str, prompt: str, max_retries: int = 3) -> str:
    """Call Gemini API and return the text response."""
    url = f"{GEMINI_URL}?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 8192,
            "responseMimeType": "application/json",
        },
        "systemInstruction": {"parts": [{"text": SYSTEM_PROMPT}]},
    }

    data = json.dumps(payload).encode("utf-8")

    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(
                url,
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=60) as resp:
                result = json.loads(resp.read().decode("utf-8"))

            text = result["candidates"][0]["content"]["parts"][0]["text"]
            return text

        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            if e.code == 429:
                wait = (attempt + 1) * 10
                print(f"    Rate limited, waiting {wait}s...", file=sys.stderr)
                time.sleep(wait)
                continue
            print(f"    HTTP {e.code}: {body[:200]}", file=sys.stderr)
            if attempt < max_retries - 1:
                time.sleep(3)
                continue
            raise
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"    Error: {e}, retrying...", file=sys.stderr)
                time.sleep(3)
                continue
            raise

    return ""


def load_json(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r",\s*([}\]])", r"\1", content)
    return json.loads(content, strict=False)


def build_refinement_pairs(
    locale: dict, configs: dict
) -> dict[str, dict[str, str]]:
    """Build {id: {en: ..., mt: ...}} pairs for refinement."""
    pairs = {}

    # Categories
    for orig, mt in locale.get("categories", {}).items():
        pairs[f"cat|{orig}"] = {"en": orig, "mt": mt}

    # Tweaks
    for key, fields in locale.get("tweaks", {}).items():
        en_entry = configs.get("tweaks", {}).get(key, {})
        for field in ["Content", "Description"]:
            if field in fields and isinstance(en_entry, dict):
                en_val = en_entry.get(field, "")
                if en_val:
                    pairs[f"tweak|{key}|{field}"] = {
                        "en": en_val,
                        "mt": fields[field],
                    }

    # Applications (description only)
    for key, fields in locale.get("applications", {}).items():
        en_entry = configs.get("applications", {}).get(key, {})
        if "description" in fields and isinstance(en_entry, dict):
            en_val = en_entry.get("description", "")
            if en_val:
                pairs[f"app|{key}|description"] = {
                    "en": en_val,
                    "mt": fields["description"],
                }

    # Feature
    for key, fields in locale.get("feature", {}).items():
        en_entry = configs.get("feature", {}).get(key, {})
        for field in ["Content", "Description"]:
            if field in fields and isinstance(en_entry, dict):
                en_val = en_entry.get(field, "")
                if en_val:
                    pairs[f"feat|{key}|{field}"] = {
                        "en": en_val,
                        "mt": fields[field],
                    }

    # Appnavigation
    for key, fields in locale.get("appnavigation", {}).items():
        en_entry = configs.get("appnavigation", {}).get(key, {})
        for field in ["Content", "Description"]:
            if field in fields and isinstance(en_entry, dict):
                en_val = en_entry.get(field, "")
                if en_val:
                    pairs[f"nav|{key}|{field}"] = {
                        "en": en_val,
                        "mt": fields[field],
                    }

    return pairs


def apply_refinements(locale: dict, refinements: dict[str, str]) -> int:
    """Apply refined translations back to locale dict. Returns count."""
    applied = 0
    for rid, refined in refinements.items():
        parts = rid.split("|")
        section = parts[0]

        if section == "cat":
            orig = parts[1]
            if orig in locale.get("categories", {}):
                locale["categories"][orig] = refined
                applied += 1
        elif section == "tweak":
            key, field = parts[1], parts[2]
            if key in locale.get("tweaks", {}) and field in locale["tweaks"][key]:
                locale["tweaks"][key][field] = refined
                applied += 1
        elif section == "app":
            key, field = parts[1], parts[2]
            if key in locale.get("applications", {}) and field in locale["applications"][key]:
                locale["applications"][key][field] = refined
                applied += 1
        elif section == "feat":
            key, field = parts[1], parts[2]
            if key in locale.get("feature", {}) and field in locale["feature"][key]:
                locale["feature"][key][field] = refined
                applied += 1
        elif section == "nav":
            key, field = parts[1], parts[2]
            if key in locale.get("appnavigation", {}) and field in locale["appnavigation"][key]:
                locale["appnavigation"][key][field] = refined
                applied += 1

    return applied


def main():
    parser = argparse.ArgumentParser(
        description="Refine locale translations using Gemini API"
    )
    parser.add_argument("--lang", required=True, help="Locale code (e.g., zh-TW)")
    parser.add_argument("--api-key", required=True, help="Gemini API key")
    parser.add_argument(
        "--batch-size",
        type=int,
        default=30,
        help="Entries per Gemini request (default: 30)",
    )
    parser.add_argument(
        "--config-dir", default=None, help="Config directory path"
    )
    parser.add_argument("--dry-run", action="store_true", help="Show pairs without calling API")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    config_dir = Path(args.config_dir) if args.config_dir else project_root / "config"
    locale_path = config_dir / "locales" / f"{args.lang}.json"

    if not locale_path.exists():
        print(f"Error: {locale_path} not found", file=sys.stderr)
        sys.exit(1)

    # Load locale and original configs
    print(f"Loading locale: {locale_path}")
    locale = load_json(locale_path)

    configs = {}
    for name in ["tweaks", "applications", "feature", "appnavigation"]:
        path = config_dir / f"{name}.json"
        if path.exists():
            configs[name] = load_json(path)

    # Build pairs
    pairs = build_refinement_pairs(locale, configs)
    print(f"Built {len(pairs)} refinement pairs")

    if args.dry_run:
        for rid, pair in list(pairs.items())[:10]:
            print(f"  {rid}:")
            print(f"    EN: {pair['en'][:80]}")
            print(f"    MT: {pair['mt'][:80]}")
        return

    # Process in batches
    pair_ids = list(pairs.keys())
    total_batches = (len(pair_ids) - 1) // args.batch_size + 1
    all_refinements = {}
    failed_batches = 0

    for i in range(0, len(pair_ids), args.batch_size):
        batch_ids = pair_ids[i : i + args.batch_size]
        batch_num = i // args.batch_size + 1
        batch_data = {rid: pairs[rid] for rid in batch_ids}

        print(f"[{batch_num}/{total_batches}] Refining {len(batch_ids)} entries...")

        prompt = (
            f"Refine these {args.lang} translations. "
            f"Input:\n{json.dumps(batch_data, ensure_ascii=False, indent=2)}"
        )

        try:
            response_text = call_gemini(args.api_key, prompt)
            # Parse JSON response - strip markdown fences if present
            clean = response_text.strip()
            clean = re.sub(r"^```(?:json)?\s*", "", clean)
            clean = re.sub(r"\s*```$", "", clean)
            refined = json.loads(clean)
            all_refinements.update(refined)
            print(f"  Got {len(refined)} refinements")
        except Exception as e:
            print(f"  Batch {batch_num} failed: {e}", file=sys.stderr)
            failed_batches += 1

        # Rate limiting
        if i + args.batch_size < len(pair_ids):
            time.sleep(2)

    # Apply refinements
    print(f"\nApplying {len(all_refinements)} refinements...")
    applied = apply_refinements(locale, all_refinements)

    # Update meta
    locale["_meta"]["refined"] = time.strftime("%Y-%m-%d")
    locale["_meta"]["refiner"] = "Gemini 2.0 Flash"

    # Write back
    with open(locale_path, "w", encoding="utf-8") as f:
        json.dump(locale, f, ensure_ascii=False, indent=4)

    print(f"Done! Applied {applied} refinements to {locale_path}")
    if failed_batches:
        print(f"Warning: {failed_batches} batches failed")


if __name__ == "__main__":
    main()

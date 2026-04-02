#!/usr/bin/env python3
"""Generate locale files for WinUtil i18n.

Extracts translatable strings from config JSONs and translates them
using Google Translate via deep-translator.

Usage:
    pip install deep-translator
    python tools/generate-locale.py --lang zh-TW
    python tools/generate-locale.py --lang ja
    python tools/generate-locale.py --lang zh-CN
"""

import json
import sys
import time
import argparse
from pathlib import Path


# Google Translate language code mapping
LANG_MAP = {
    "zh-TW": "zh-TW",
    "zh-CN": "zh-CN",
    "ja": "ja",
    "ko": "ko",
    "de": "de",
    "fr": "fr",
    "es": "es",
    "pt-BR": "pt",
    "ru": "ru",
    "ar": "ar",
    "vi": "vi",
    "th": "th",
}

# Locale display names
LANG_NAMES = {
    "zh-TW": "繁體中文",
    "zh-CN": "简体中文",
    "ja": "日本語",
    "ko": "한국어",
    "de": "Deutsch",
    "fr": "Français",
    "es": "Español",
    "pt-BR": "Português (Brasil)",
    "ru": "Русский",
    "ar": "العربية",
    "vi": "Tiếng Việt",
    "th": "ไทย",
}


def load_json(path: Path) -> dict:
    import re

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    # Strip trailing commas before } or ] (lenient JSON)
    content = re.sub(r",\s*([}\]])", r"\1", content)
    # strict=False allows control characters embedded in PowerShell scripts
    return json.loads(content, strict=False)


def extract_translatable_strings(configs: dict) -> dict[str, str]:
    """Extract all translatable strings from config files.

    Returns a dict of string_id -> english_text.
    String IDs encode the path: "section.key.field"
    """
    strings = {}

    # tweaks: Content + Description
    for key, entry in configs["tweaks"].items():
        if isinstance(entry, dict):
            if entry.get("Content"):
                strings[f"tweaks|{key}|Content"] = entry["Content"]
            if entry.get("Description"):
                strings[f"tweaks|{key}|Description"] = entry["Description"]

    # applications: description only (content is software name, don't translate)
    for key, entry in configs["applications"].items():
        if isinstance(entry, dict):
            if entry.get("description"):
                strings[f"applications|{key}|description"] = entry["description"]

    # feature: Content + Description
    for key, entry in configs["feature"].items():
        if isinstance(entry, dict):
            if entry.get("Content"):
                strings[f"feature|{key}|Content"] = entry["Content"]
            if entry.get("Description"):
                strings[f"feature|{key}|Description"] = entry["Description"]

    # appnavigation: Content + Description
    for key, entry in configs["appnavigation"].items():
        if isinstance(entry, dict):
            if entry.get("Content"):
                strings[f"appnavigation|{key}|Content"] = entry["Content"]
            if entry.get("Description"):
                strings[f"appnavigation|{key}|Description"] = entry["Description"]

    # categories (deduplicated)
    categories = set()
    for section in ["tweaks", "feature", "appnavigation"]:
        for entry in configs[section].values():
            if isinstance(entry, dict) and entry.get("category"):
                cat = entry["category"]
                # Strip sort prefix (e.g., "z__Advanced..." -> "Advanced...")
                display = cat.split("__")[-1] if "__" in cat else cat
                categories.add(display)
    for entry in configs["applications"].values():
        if isinstance(entry, dict) and entry.get("category"):
            categories.add(entry["category"])

    for cat in sorted(categories):
        strings[f"categories|{cat}"] = cat

    return strings


def translate_strings(
    strings: dict[str, str], target_lang: str, batch_size: int = 45
) -> dict[str, str]:
    """Translate all strings using Google Translate."""
    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Error: deep-translator not installed.", file=sys.stderr)
        print("Run: pip install deep-translator", file=sys.stderr)
        sys.exit(1)

    gt_lang = LANG_MAP.get(target_lang, target_lang)
    translator = GoogleTranslator(source="en", target=gt_lang)

    ids = list(strings.keys())
    texts = list(strings.values())
    translated = []
    total_batches = (len(texts) - 1) // batch_size + 1
    failed = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        batch_num = i // batch_size + 1
        print(f"  [{batch_num}/{total_batches}] Translating {len(batch)} strings...")

        try:
            result = translator.translate_batch(batch)
            translated.extend(result)
        except Exception as e:
            print(f"  Batch {batch_num} failed: {e}", file=sys.stderr)
            print("  Falling back to individual translation...", file=sys.stderr)
            for j, text in enumerate(batch):
                try:
                    t = translator.translate(text)
                    translated.append(t)
                except Exception as e2:
                    print(
                        f"    Failed to translate '{text[:50]}...': {e2}",
                        file=sys.stderr,
                    )
                    translated.append(text)  # Keep original on failure
                    failed.append(ids[i + j])
                time.sleep(0.3)

        # Rate limiting between batches
        if i + batch_size < len(texts):
            time.sleep(1.5)

    if failed:
        print(f"\nWarning: {len(failed)} strings failed to translate:", file=sys.stderr)
        for fid in failed[:10]:
            print(f"  - {fid}", file=sys.stderr)

    return dict(zip(ids, translated))


def build_locale_json(translations: dict[str, str], target_lang: str) -> dict:
    """Build structured locale JSON from flat translations."""
    locale = {
        "_meta": {
            "locale": target_lang,
            "name": LANG_NAMES.get(target_lang, target_lang),
            "generated": time.strftime("%Y-%m-%d"),
            "generator": "generate-locale.py (Google Translate)",
            "total_strings": len(translations),
        },
        "categories": {},
        "tweaks": {},
        "applications": {},
        "feature": {},
        "appnavigation": {},
    }

    for string_id, translated_text in translations.items():
        parts = string_id.split("|")
        section = parts[0]

        if section == "categories":
            original = parts[1]
            locale["categories"][original] = translated_text
        elif section in ("tweaks", "feature", "appnavigation"):
            key, field = parts[1], parts[2]
            if key not in locale[section]:
                locale[section][key] = {}
            locale[section][key][field] = translated_text
        elif section == "applications":
            key, field = parts[1], parts[2]
            if key not in locale[section]:
                locale[section][key] = {}
            locale[section][key][field] = translated_text

    return locale


def main():
    parser = argparse.ArgumentParser(
        description="Generate locale files for WinUtil i18n"
    )
    parser.add_argument(
        "--lang",
        required=True,
        help="Target language code (zh-TW, zh-CN, ja, ko, etc.)",
    )
    parser.add_argument(
        "--config-dir",
        default=None,
        help="Path to config directory (auto-detected if omitted)",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Output directory (default: config/locales)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=45,
        help="Translation batch size (default: 45)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Extract strings only, no translation",
    )
    args = parser.parse_args()

    # Auto-detect project root
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    config_dir = Path(args.config_dir) if args.config_dir else project_root / "config"
    output_dir = (
        Path(args.output_dir) if args.output_dir else project_root / "config" / "locales"
    )

    if args.lang not in LANG_MAP:
        print(f"Warning: '{args.lang}' not in known language map, using as-is")

    # Load configs
    configs = {}
    for name in ["tweaks", "applications", "feature", "appnavigation"]:
        path = config_dir / f"{name}.json"
        if not path.exists():
            print(f"Error: {path} not found", file=sys.stderr)
            sys.exit(1)
        print(f"Loading {path.name}...")
        configs[name] = load_json(path)

    # Extract strings
    print("Extracting translatable strings...")
    strings = extract_translatable_strings(configs)
    print(f"Found {len(strings)} translatable strings:")
    print(f"  - tweaks: {sum(1 for k in strings if k.startswith('tweaks|'))}")
    print(
        f"  - applications: {sum(1 for k in strings if k.startswith('applications|'))}"
    )
    print(f"  - feature: {sum(1 for k in strings if k.startswith('feature|'))}")
    print(
        f"  - appnavigation: {sum(1 for k in strings if k.startswith('appnavigation|'))}"
    )
    print(f"  - categories: {sum(1 for k in strings if k.startswith('categories|'))}")

    if args.dry_run:
        # Output extracted strings for review
        dry_path = output_dir / f"{args.lang}.strings.json"
        output_dir.mkdir(parents=True, exist_ok=True)
        with open(dry_path, "w", encoding="utf-8") as f:
            json.dump(strings, f, ensure_ascii=False, indent=2)
        print(f"\nDry run: extracted strings written to {dry_path}")
        return

    # Translate
    print(f"\nTranslating to {args.lang} ({LANG_NAMES.get(args.lang, '?')})...")
    translations = translate_strings(strings, args.lang, args.batch_size)

    # Build locale JSON
    locale = build_locale_json(translations, args.lang)

    # Write output
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{args.lang}.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(locale, f, ensure_ascii=False, indent=4)

    print(f"\nDone! Locale file: {output_path}")
    print(f"Total strings: {locale['_meta']['total_strings']}")


if __name__ == "__main__":
    main()

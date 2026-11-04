"""Сборка сайта «Финтакса»:

1. Готовит веб-версии картинок из ../images в assets/img (WebP + favicon).
2. Собирает artifact.html — версию главной страницы для публикации артефактом
   (без <!doctype>, <html>, <head> и <body>: их добавляет площадка).

Запуск:  python site/build.py
"""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image

SITE = Path(__file__).resolve().parent
IMAGES = SITE.parent / "images"
OUT = SITE / "assets" / "img"


def export_webp(source: Path, name: str, max_size: tuple[int, int], quality: int = 84) -> None:
    """Сохраняет уменьшенную копию картинки в WebP."""
    image = Image.open(source).convert("RGB")
    image.thumbnail(max_size, Image.Resampling.LANCZOS)
    destination = OUT / name
    image.save(destination, "WEBP", quality=quality, method=6)
    print(f"  {name:<22} {image.width}x{image.height}  {destination.stat().st_size / 1024:5.0f} KB")


def export_favicon(source: Path) -> None:
    image = Image.open(source).convert("RGB")
    image.thumbnail((64, 64), Image.Resampling.LANCZOS)
    destination = OUT / "favicon.png"
    image.save(destination, "PNG", optimize=True)
    print(f"  {'favicon.png':<22} {image.width}x{image.height}  {destination.stat().st_size / 1024:5.0f} KB")


def build_artifact() -> None:
    """Убирает оболочку документа — артефакт добавляет её сам."""
    html = (SITE / "index.html").read_text(encoding="utf-8")

    for pattern in (
        r"(?is)^\s*<!doctype[^>]*>",
        r"(?is)<html[^>]*>",
        r"(?is)</html>",
        r"(?is)<head[^>]*>",
        r"(?is)</head>",
        r"(?is)<body[^>]*>",
        r"(?is)</body>",
    ):
        html = re.sub(pattern, "", html)

    (SITE / "artifact.html").write_text(html.strip() + "\n", encoding="utf-8")
    print("  artifact.html — готов")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    print("Картинки:")
    export_webp(IMAGES / "Аватар ФинТакса.png", "avatar.webp", (720, 720), 88)
    export_webp(
        IMAGES / "Такса помогает бухгалтеру с отчётом.png",
        "story-1.webp",
        (1400, 1400),
        82,
    )
    export_webp(
        IMAGES / "Такса помогает бухгалтеру с отчётом.png",
        "story-1-card.webp",
        (800, 800),
        80,
    )
    export_webp(
        IMAGES / "Налоги с FinTaxa_ всё понятно.png",
        "story-2.webp",
        (1400, 1400),
        82,
    )
    export_webp(
        IMAGES / "Налоги с FinTaxa_ всё понятно.png",
        "story-2-card.webp",
        (800, 800),
        80,
    )
    export_webp(
        IMAGES / "Прогрессивная шкала НДФЛ с ФинТаксой.png",
        "story-3.webp",
        (1400, 1400),
        82,
    )
    export_webp(
        IMAGES / "Прогрессивная шкала НДФЛ с ФинТаксой.png",
        "story-3-card.webp",
        (800, 800),
        80,
    )
    export_webp(
        IMAGES / "Такса объясняет налоговые вычеты.png",
        "story-4.webp",
        (1400, 1400),
        82,
    )
    export_webp(
        IMAGES / "Такса объясняет налоговые вычеты.png",
        "story-4-card.webp",
        (800, 800),
        80,
    )
    export_webp(
        IMAGES / "ФинТакса объясняет жилищные вычеты.png",
        "story-5.webp",
        (1400, 1400),
        82,
    )
    export_webp(
        IMAGES / "ФинТакса объясняет жилищные вычеты.png",
        "story-5-card.webp",
        (800, 800),
        80,
    )
    export_favicon(IMAGES / "Аватар ФинТакса.png")

    print("Артефакт:")
    build_artifact()


if __name__ == "__main__":
    main()

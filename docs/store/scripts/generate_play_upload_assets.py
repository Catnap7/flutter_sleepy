from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "docs" / "store" / "raw_sources" / "play_current"
OUT = ROOT / "docs" / "store" / "play_upload_2026_05"
ICON = ROOT / "assets" / "icon" / "icon.png"

CANVAS = (1080, 1920)
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, typeface: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), candidate, font=typeface)[2] <= max_width:
            current = candidate
            continue
        if current:
            lines.append(current)
        current = word
    if current:
        lines.append(current)
    return lines


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    lines: Iterable[str],
    y: int,
    typeface: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    line_gap: int = 8,
) -> int:
    for line in lines:
        left, top, right, bottom = draw.textbbox((0, 0), line, font=typeface)
        x = (CANVAS[0] - (right - left)) // 2
        draw.text((x, y), line, font=typeface, fill=fill)
        y += bottom - top + line_gap
    return y


def gradient_background(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", CANVAS, top)
    pixels = image.load()
    for y in range(CANVAS[1]):
        ratio = y / (CANVAS[1] - 1)
        color = tuple(int(top[i] * (1 - ratio) + bottom[i] * ratio) for i in range(3))
        for x in range(CANVAS[0]):
            pixels[x, y] = color
    return image


def make_cover() -> None:
    image = gradient_background((7, 15, 31), (19, 78, 110))
    draw = ImageDraw.Draw(image)

    for radius, alpha in [(390, 46), (270, 54), (150, 62)]:
        overlay = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        odraw = ImageDraw.Draw(overlay)
        odraw.ellipse((620 - radius, 260 - radius, 620 + radius, 260 + radius), outline=(56, 189, 248, alpha), width=6)
        image.paste(Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB"))

    app_icon = Image.open(ICON).convert("RGBA").resize((260, 260), Image.Resampling.LANCZOS)
    icon_box = Image.new("RGBA", (330, 330), (255, 255, 255, 24))
    mask = Image.new("L", icon_box.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 330, 330), radius=62, fill=255)
    image.paste(icon_box, (375, 210), mask)
    image.paste(app_icon, (410, 245), app_icon)

    draw = ImageDraw.Draw(image)
    draw_centered_text(draw, ["Sleepy"], 620, font(112, True), (248, 250, 252), 10)
    draw_centered_text(
        draw,
        ["Offline sleep sounds", "with a fade-out timer"],
        765,
        font(50),
        (203, 242, 255),
        8,
    )

    chips = ["Rain", "White Noise", "Brown Noise"]
    x = 105
    for chip in chips:
        chip_font = font(36)
        left, top, right, bottom = draw.textbbox((0, 0), chip, font=chip_font)
        width = right - left + 56
        draw.rounded_rectangle((x, 930, x + width, 1000), radius=28, fill=(30, 80, 105), outline=(125, 211, 252))
        draw.text((x + 28, 948), chip, font=chip_font, fill=(241, 245, 249))
        x += width + 24

    draw.rounded_rectangle((90, 1180, 990, 1610), radius=52, fill=(18, 72, 94), outline=(148, 210, 230), width=2)
    bullets = [
        "No account required",
        "Works without streaming",
        "Built for quiet nights",
    ]
    y = 1265
    for bullet in bullets:
        draw.ellipse((150, y + 10, 188, y + 48), fill=(56, 189, 248))
        draw.text((225, y), bullet, font=font(46), fill=(241, 245, 249))
        y += 102

    draw.text((285, 1785), "Android  •  Offline playback", font=font(34), fill=(203, 213, 225))
    image.save(OUT / "01_offline_sleep_sounds.png", quality=95)


def normalize_slide(
    source_name: str,
    output_name: str,
    headline: str,
    subtitle: str,
    fill: tuple[int, int, int],
    text_fill: tuple[int, int, int] = (255, 255, 255),
    top_height: int = 360,
) -> None:
    source = Image.open(RAW / source_name).convert("RGB")
    canvas = Image.new("RGB", CANVAS, fill)
    x = (CANVAS[0] - source.width) // 2
    canvas.paste(source, (x, 0))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, CANVAS[0], top_height), fill=fill)

    title_font = font(68, True)
    subtitle_font = font(38)
    y = 82
    title_lines = wrap_text(draw, headline, title_font, 910)
    y = draw_centered_text(draw, title_lines, y, title_font, text_fill, 4)
    y += 14
    subtitle_lines = wrap_text(draw, subtitle, subtitle_font, 900)
    draw_centered_text(draw, subtitle_lines, y, subtitle_font, text_fill, 4)

    canvas.save(OUT / output_name, quality=95)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_cover()
    normalize_slide(
        "03_current_play.png",
        "02_fade_out_timer.png",
        "Fade-out sleep timer",
        "Auto-stop from 15 minutes to 2 hours",
        (56, 169, 185),
    )
    normalize_slide(
        "04_current_play.png",
        "03_background_audio.png",
        "Keeps playing with screen off",
        "Background audio for bedtime",
        (183, 31, 232),
    )
    normalize_slide(
        "05_current_play.png",
        "04_bedtime_controls.png",
        "One-tap bedtime controls",
        "Large buttons for tired eyes",
        (164, 63, 219),
    )
    normalize_slide(
        "02_current_play.png",
        "05_breathing.png",
        "4-7-8 breathing",
        "Wind down before sleep",
        (106, 217, 170),
        text_fill=(4, 18, 31),
        top_height=430,
    )
    normalize_slide(
        "03_current_play.png",
        "06_no_account.png",
        "No account required",
        "A quiet app for quiet nights",
        (56, 169, 185),
    )


if __name__ == "__main__":
    main()

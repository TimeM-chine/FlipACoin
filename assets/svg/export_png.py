#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def _get_attr(text: str, name: str) -> str | None:
	needle = f'{name}="'
	i = text.find(needle)
	if i == -1:
		return None
	i += len(needle)
	j = text.find('"', i)
	if j == -1:
		return None
	return text[i:j]


def _sanitize_drop_shadow(svg_text: str) -> str:
	"""
	Some exporters (notably CairoSVG/librsvg) don't fully support <feDropShadow>.
	When unsupported, the whole element with filter="url(#shadow)" may disappear.

	We replace the shadow filter with a widely-supported blur+offset shadow.
	"""
	if "feDropShadow" not in svg_text:
		return svg_text

	start = svg_text.find('<filter id="shadow"')
	if start == -1:
		return svg_text

	end = svg_text.find("</filter>", start)
	if end == -1:
		return svg_text
	end += len("</filter>")

	block = svg_text[start:end]
	open_end = block.find(">")
	if open_end == -1:
		return svg_text

	open_tag = block[: open_end + 1]

	# Try to preserve the original shadow parameters from the feDropShadow line.
	drop_i = block.find("<feDropShadow")
	drop_j = block.find("/>", drop_i) if drop_i != -1 else -1
	drop_line = block[drop_i : drop_j + 2] if (drop_i != -1 and drop_j != -1) else ""

	def _f(name: str, default: float) -> float:
		val = _get_attr(drop_line, name)
		if val is None:
			return default
		try:
			return float(val)
		except ValueError:
			return default

	dx = _f("dx", 0.0)
	dy = _f("dy", 18.0)
	std = _f("stdDeviation", 14.0)
	opacity = _f("flood-opacity", 0.35)
	opacity = max(0.0, min(1.0, opacity))

	# RGB forced to 0 (black), alpha scaled by opacity.
	matrix = f"0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 {opacity:.4f} 0"

	replacement = (
		f"{open_tag}\n"
		f'\t\t\t<feGaussianBlur in="SourceAlpha" stdDeviation="{std}" result="blur"/>\n'
		f'\t\t\t<feOffset in="blur" dx="{dx}" dy="{dy}" result="offsetBlur"/>\n'
		f'\t\t\t<feColorMatrix in="offsetBlur" type="matrix" values="{matrix}" result="shadow"/>\n'
		"\t\t\t<feMerge>\n"
		'\t\t\t\t<feMergeNode in="shadow"/>\n'
		"\t\t\t\t<feMergeNode in=\"SourceGraphic\"/>\n"
		"\t\t\t</feMerge>\n"
		"\t\t</filter>"
	)

	return svg_text[:start] + replacement + svg_text[end:]


def _export_with_cairosvg(svg_path: Path, out_path: Path, size: int) -> None:
	import cairosvg  # type: ignore

	svg_text = svg_path.read_text(encoding="utf-8", errors="replace")
	svg_text = _sanitize_drop_shadow(svg_text)

	# CairoSVG keeps transparency by default when writing PNG.
	cairosvg.svg2png(
		bytestring=svg_text.encode("utf-8"),
		write_to=str(out_path),
		output_width=size,
		output_height=size,
	)


def _export_with_inkscape(svg_path: Path, out_path: Path, size: int, inkscape_bin: str) -> None:
	# Inkscape 1.x
	cmd = [
		inkscape_bin,
		str(svg_path),
		"--export-type=png",
		f"--export-filename={out_path}",
		"-w",
		str(size),
		"-h",
		str(size),
	]
	subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def _export_with_rsvg(svg_path: Path, out_path: Path, size: int, rsvg_bin: str) -> None:
	cmd = [
		rsvg_bin,
		"-w",
		str(size),
		"-h",
		str(size),
		"-f",
		"png",
		"-o",
		str(out_path),
		str(svg_path),
	]
	subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def export_one(svg_path: Path, out_path: Path, size: int) -> None:
	out_path.parent.mkdir(parents=True, exist_ok=True)

	inkscape_bin = shutil.which("inkscape")
	if inkscape_bin:
		# Inkscape supports more SVG features, but we still sanitize to be safe.
		svg_text = svg_path.read_text(encoding="utf-8", errors="replace")
		svg_text = _sanitize_drop_shadow(svg_text)
		with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as f:
			tmp_svg = Path(f.name)
			f.write(svg_text)
		try:
			_export_with_inkscape(tmp_svg, out_path, size, inkscape_bin)
		finally:
			try:
				tmp_svg.unlink()
			except OSError:
				pass
		return

	# Prefer pure-python conversion when available
	try:
		_export_with_cairosvg(svg_path, out_path, size)
		return
	except Exception:
		pass

	rsvg_bin = shutil.which("rsvg-convert")
	if rsvg_bin:
		svg_text = svg_path.read_text(encoding="utf-8", errors="replace")
		svg_text = _sanitize_drop_shadow(svg_text)
		with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as f:
			tmp_svg = Path(f.name)
			f.write(svg_text)
		try:
			_export_with_rsvg(tmp_svg, out_path, size, rsvg_bin)
		finally:
			try:
				tmp_svg.unlink()
			except OSError:
				pass
		return

	is_macos = sys.platform == "darwin"

	raise RuntimeError(
		"没有找到可用的 SVG->PNG 导出器。\n"
		"请安装其一：\n"
		"- Python 方案（可能需要系统依赖）：python3 -m pip install --user cairosvg\n"
		+ ("- macOS 推荐：brew install --cask inkscape\n" if is_macos else "")
		+ ("- macOS 备选：brew install librsvg\n" if is_macos else "")
		+ "- 或安装 Inkscape（确保命令行 inkscape 可用）\n"
		+ "- 或安装 librsvg（确保 rsvg-convert 可用）\n"
	)


def main(argv: list[str]) -> int:
	parser = argparse.ArgumentParser(
		description="Export all badge SVGs to 256x256 PNG (transparent outside circle)."
	)
	parser.add_argument(
		"--size",
		type=int,
		default=256,
		help="Output PNG size (width=height). Default: 256",
	)
	parser.add_argument(
		"--out",
		type=str,
		default="png",
		help="Output directory (relative to this script). Default: png",
	)
	args = parser.parse_args(argv)

	script_dir = Path(__file__).resolve().parent
	out_dir = (script_dir / args.out).resolve()
	size = int(args.size)

	svgs = sorted(script_dir.glob("*.svg"))
	if not svgs:
		print("未找到任何 .svg 文件。请把徽章 SVG 放在本脚本同目录下。", file=sys.stderr)
		return 1

	ok = 0
	for svg_path in svgs:
		out_path = out_dir / f"{svg_path.stem}.png"
		try:
			export_one(svg_path, out_path, size)
			ok += 1
		except subprocess.CalledProcessError as e:
			print(f"[FAIL] {svg_path.name}\n{e.stderr}", file=sys.stderr)
		except Exception as e:
			print(f"[FAIL] {svg_path.name}\n{e}", file=sys.stderr)

	print(f"导出完成：{ok}/{len(svgs)} -> {out_dir}")
	return 0 if ok == len(svgs) else 2


if __name__ == "__main__":
	raise SystemExit(main(sys.argv[1:]))


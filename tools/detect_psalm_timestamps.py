#!/usr/bin/env python3
"""
Auto-detect Amharic psalm chapter start times from one continuous recording
by finding the pauses between chapters, then write them into
lib/services/psalm_audio_timestamps.dart.

WHY: a narrated psalter pauses between chapters. We detect every silence,
keep the (chapters - 1) LONGEST ones (those are the chapter breaks), and use
the moment speech resumes after each as the next chapter's start time.

USAGE (run on your own machine where ffmpeg lives):
    python3 tools/detect_psalm_timestamps.py path/to/psalms.m4a --chapters 150

  First run WITHOUT --write to inspect the result, then add --write to patch
  the Dart file:
    python3 tools/detect_psalm_timestamps.py psalms.m4a --chapters 150 --write

NEEDS ffmpeg. Either:
  - have `ffmpeg` on your PATH, or
  - `pip install imageio-ffmpeg` (the script will find it automatically), or
  - pass --ffmpeg /full/path/to/ffmpeg
"""
import argparse
import os
import re
import shutil
import subprocess
import sys


def find_ffmpeg(explicit):
    if explicit:
        return explicit
    on_path = shutil.which("ffmpeg")
    if on_path:
        return on_path
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        pass
    sys.exit("ffmpeg not found. Install it, run `pip install imageio-ffmpeg`, "
             "or pass --ffmpeg /path/to/ffmpeg")


def detect_silences(ffmpeg, audio, noise_db, min_silence):
    """Return a list of (silence_end_seconds, silence_duration_seconds)."""
    cmd = [ffmpeg, "-hide_banner", "-nostats", "-i", audio,
           "-af", f"silencedetect=noise={noise_db}dB:d={min_silence}",
           "-f", "null", "-"]
    proc = subprocess.run(cmd, stderr=subprocess.PIPE, text=True)
    log = proc.stderr
    ends = [float(m) for m in re.findall(r"silence_end:\s*([0-9.]+)", log)]
    durs = [float(m) for m in re.findall(r"silence_duration:\s*([0-9.]+)", log)]
    n = min(len(ends), len(durs))
    return list(zip(ends[:n], durs[:n]))


def get_duration(ffmpeg, audio):
    cmd = [ffmpeg, "-hide_banner", "-i", audio, "-f", "null", "-"]
    log = subprocess.run(cmd, stderr=subprocess.PIPE, text=True).stderr
    m = re.search(r"Duration:\s*(\d+):(\d+):([0-9.]+)", log)
    if not m:
        return None
    h, mn, s = m.groups()
    return int(h) * 3600 + int(mn) * 60 + float(s)


def fmt(seconds):
    seconds = max(0, int(round(seconds)))
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("audio", help="path to the continuous recording")
    ap.add_argument("--chapters", type=int, default=150)
    ap.add_argument("--noise-db", type=float, default=-30.0,
                    help="silence threshold in dB (default -30; -35/-40 = stricter quiet)")
    ap.add_argument("--min-silence", type=float, default=0.6,
                    help="minimum silence length in seconds to count (default 0.6)")
    ap.add_argument("--lead", type=float, default=0.25,
                    help="start each chapter this many seconds before speech resumes")
    ap.add_argument("--ffmpeg", default=None)
    ap.add_argument("--write", action="store_true",
                    help="patch lib/services/psalm_audio_timestamps.dart in place")
    args = ap.parse_args()

    ffmpeg = find_ffmpeg(args.ffmpeg)
    if not os.path.exists(args.audio):
        sys.exit(f"file not found: {args.audio}")

    print(f"Analyzing {args.audio} ...")
    total = get_duration(ffmpeg, args.audio)
    if total:
        print(f"Total duration: {fmt(total)}")

    sil = detect_silences(ffmpeg, args.audio, args.noise_db, args.min_silence)
    print(f"Detected {len(sil)} silences (>= {args.min_silence}s at {args.noise_db}dB).")

    need = args.chapters - 1
    if len(sil) < need:
        print(f"\n! Only {len(sil)} silences found but need {need} chapter breaks.")
        print("  Try lowering --min-silence (e.g. 0.4) or raising --noise-db toward 0 "
              "(e.g. -25), then re-run.")
        sys.exit(1)

    # Keep the longest silences -> chapter breaks. Then order them by time.
    breaks = sorted(sil, key=lambda x: x[1], reverse=True)[:need]
    breaks = sorted(e for e, _ in breaks)

    starts = {1: 0.0}
    for i, end in enumerate(breaks, start=2):
        starts[i] = max(0.0, end - args.lead)

    # Sanity report: list each chapter length so wrong splits are obvious.
    print("\nChapter | start     | length")
    bounds = [starts[c] for c in range(1, args.chapters + 1)] + [total or starts[args.chapters]]
    short = []
    for c in range(1, args.chapters + 1):
        length = bounds[c] - bounds[c - 1]
        flag = "  <-- very short, check" if length < 8 else ""
        if length < 8:
            short.append(c)
        print(f"{c:>7} | {fmt(starts[c]):>8} | {fmt(length):>6}{flag}")
    if short:
        print(f"\n! {len(short)} chapter(s) look suspiciously short: {short}")
        print("  These are likely false splits (a pause mid-chapter). Adjust "
              "--min-silence / --noise-db and re-run, or fix those few by hand.")

    # Build the Dart map block.
    lines = "\n".join(f"    {c}: '{fmt(starts[c])}'," for c in range(1, args.chapters + 1))
    block = "  static const Map<int, String> _startStrings = {\n" + lines + "\n  };"

    if not args.write:
        print("\n--- Dart map (re-run with --write to apply) ---\n")
        print(block)
        return

    dart = os.path.join(os.path.dirname(__file__), "..", "lib", "services",
                        "psalm_audio_timestamps.dart")
    dart = os.path.normpath(dart)
    text = open(dart, encoding="utf-8").read()
    new = re.sub(
        r"  static const Map<int, String> _startStrings = \{.*?\n  \};",
        block.replace("\\", "\\\\"),
        text, count=1, flags=re.DOTALL)
    if new == text:
        sys.exit("Could not find the _startStrings block to replace in " + dart)
    open(dart, "w", encoding="utf-8").write(new)
    print(f"\nWrote {args.chapters} timestamps into {dart}")


if __name__ == "__main__":
    main()

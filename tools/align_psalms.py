"""Stage B: anchored sequential forced alignment.

For each psalm we align only its first ~K words, inside a moving window that
starts at the previous psalm's anchor. Leading/trailing <star> tokens absorb
the surrounding audio, so the K words snap to where that psalm actually begins.
Each psalm re-anchors by content, so errors don't accumulate.

Run after gen_emissions.py:
    python3 tools/align_psalms.py            # dry run, prints table
    python3 tools/align_psalms.py --write    # patch the Dart timestamps file
"""
import os, json, argparse, numpy as np
from ctc_forced_aligner import (
    get_alignments, get_spans, postprocess_results, preprocess_text, Tokenizer,
)

WORK = os.path.join(os.path.dirname(__file__), "align_work")
EMIS = os.path.join(WORK, "emissions.npy")
PSALMS = os.path.join(os.path.dirname(__file__), "psalms_am.json")
DART = os.path.normpath(os.path.join(
    os.path.dirname(__file__), "..", "lib", "services", "psalm_audio_timestamps.dart"))

FPS = 50            # 20ms stride
STRIDE_MS = 20
K = 25              # words to anchor on
LEAD = 7.0         # start each chapter this many seconds before its first word
SECS_PER_WORD = 0.9


def fmt(seconds):
    seconds = max(0, int(round(seconds)))
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    emissions = np.load(EMIS).astype(np.float32)
    T = emissions.shape[0]
    total_sec = T / FPS
    print(f"emissions {emissions.shape}, duration {fmt(total_sec)}")

    psalms = json.load(open(PSALMS, encoding="utf-8"))
    tok = Tokenizer()

    anchors = {}      # chapter -> first verse word start (sec)
    wordcount = {}
    cursor = 0.0      # search start (sec) = previous psalm anchor
    prev_words = K

    for c in range(1, 151):
        words = psalms[str(c)].split()
        wordcount[c] = len(words)
        head = " ".join(words[:K])
        # Window must span the rest of the PREVIOUS psalm + this psalm's head.
        win_sec = min(3300.0, max(300.0, prev_words * SECS_PER_WORD * 1.8 + 240))
        c0 = int(cursor * FPS)
        c1 = min(T, c0 + int(win_sec * FPS))
        win = emissions[c0:c1]

        tokens_starred, text_starred = preprocess_text(
            head, romanize=True, language="amh", star_frequency="edges")
        segments, scores, blank = get_alignments(win, tokens_starred, tok)
        spans = get_spans(tokens_starred, segments, blank)
        res = postprocess_results(text_starred, spans, STRIDE_MS, scores)

        a = cursor + res[0]["start"]
        anchors[c] = a
        cursor = a                       # next search starts at this anchor
        prev_words = len(words)

    # Save anchors for inspection / reuse.
    json.dump({"anchors": anchors, "wordcount": wordcount, "total_sec": total_sec},
              open(os.path.join(WORK, "anchors.json"), "w"))

    # duration[c] = time allotted to psalm c = anchor[c+1] - anchor[c]
    # A psalm of W words needs at least ~0.30s/word; flag if it got far less.
    MIN_SPW = 0.30
    starts = {1: 0.0}
    suspicious = []
    for c in range(2, 151):
        starts[c] = max(starts[c - 1] + 5.0, anchors[c] - LEAD)
    for c in range(1, 151):
        end = anchors[c + 1] if c < 150 else total_sec
        dur = end - anchors[c]
        need = max(8.0, wordcount[c] * MIN_SPW)
        if dur < need:
            suspicious.append(c)

    print("\nChapter | start    | first-word | dur  | words")
    for c in range(1, 151):
        end = anchors[c + 1] if c < 150 else total_sec
        dur = end - anchors[c]
        flag = "  <-- TOO SHORT for word count" if c in suspicious else ""
        print(f"{c:>7} | {fmt(starts[c]):>8} | {fmt(anchors[c]):>9} | {fmt(dur):>5} | {wordcount[c]:>4}{flag}")

    if suspicious:
        print(f"\n! {len(suspicious)} suspect anchor(s): {suspicious}")
        print("  (psalm got far less time than its length implies -> mis-anchored)")
    else:
        print("\nAll anchors look plausible.")

    block_lines = "\n".join(f"    {c}: '{fmt(starts[c])}'," for c in range(1, 151))
    block = "  static const Map<int, String> _startStrings = {\n" + block_lines + "\n  };"

    if not args.write:
        print("\n(dry run) re-run with --write to patch the Dart file.")
        return

    import re
    text = open(DART, encoding="utf-8").read()
    new = re.sub(r"  static const Map<int, String> _startStrings = \{.*?\n  \};",
                 block.replace("\\", "\\\\"), text, count=1, flags=re.DOTALL)
    if new == text:
        raise SystemExit("Could not find _startStrings block in " + DART)
    open(DART, "w", encoding="utf-8").write(new)
    print(f"\nWrote 150 timestamps into {DART}")


if __name__ == "__main__":
    main()

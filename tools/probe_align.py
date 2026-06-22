"""Validate the CTC forced-alignment pipeline on a short clip before the full run."""
import os, json, numpy as np, soundfile as sf, onnxruntime
from ctc_forced_aligner import (
    generate_emissions, get_alignments, get_spans, postprocess_results,
    preprocess_text, ensure_onnx_model, Tokenizer, MODEL_URL,
)

WORK = os.path.join(os.path.dirname(__file__), "align_work")
WAV = os.path.join(WORK, "psalms_16k.wav")
MODEL = os.path.join(WORK, "model.onnx")

print("Ensuring model...")
ensure_onnx_model(MODEL, MODEL_URL)
print("model size MB:", round(os.path.getsize(MODEL) / 1e6, 1))

sess = onnxruntime.InferenceSession(MODEL, providers=["CPUExecutionProvider"])
tok = Tokenizer()

# Read first 120 seconds only.
clip, sr = sf.read(WAV, frames=120 * 16000, dtype="float32")
print("clip samples:", clip.shape, "sr:", sr)

emissions, stride = generate_emissions(sess, clip, batch_size=4)
print("emissions:", emissions.shape, "stride(ms):", stride)

psalms = json.load(open(os.path.join(WORK, "..", "psalms_am.json"), encoding="utf-8"))
text = " ".join(psalms["1"].split()[:25])
print("text:", text)

tokens_starred, text_starred = preprocess_text(
    text, romanize=True, language="amh", star_frequency="edges")
segments, scores, blank = get_alignments(emissions, tokens_starred, tok)
spans = get_spans(tokens_starred, segments, blank)
words = postprocess_results(text_starred, spans, stride, scores)
print("aligned words:", len(words))
for w in words[:8]:
    print(f"  {w['start']:.2f}-{w['end']:.2f}  {w['text']}")
print("FIRST WORD START (sec):", round(words[0]["start"], 2))
print("LAST WORD END (sec):", round(words[-1]["end"], 2))

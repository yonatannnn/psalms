"""Stage A: generate CTC emissions for the full recording, in memory-bounded
chunks, and save to disk. Frame stride is a constant 20 ms (50 fps)."""
import os, time, numpy as np, soundfile as sf, onnxruntime
from ctc_forced_aligner import generate_emissions, ensure_onnx_model, MODEL_URL

WORK = os.path.join(os.path.dirname(__file__), "align_work")
WAV = os.path.join(WORK, "psalms_16k.wav")
MODEL = os.path.join(WORK, "model.onnx")
OUT = os.path.join(WORK, "emissions.npy")

SR = 16000
CHUNK = 300 * SR  # 5 min, multiple of 320 (=20ms) so frames concatenate cleanly

ensure_onnx_model(MODEL, MODEL_URL)
# Lean session config to fit limited RAM.
so = onnxruntime.SessionOptions()
so.enable_cpu_mem_arena = False
so.enable_mem_pattern = False
so.intra_op_num_threads = 8
sess = onnxruntime.InferenceSession(MODEL, sess_options=so,
                                    providers=["CPUExecutionProvider"])

info = sf.info(WAV)
total = info.frames
print(f"audio: {total} samples = {total/SR/60:.1f} min")

parts = []
t0 = time.time()
start = 0
idx = 0
while start < total:
    stop = min(start + CHUNK, total)
    wave, _ = sf.read(WAV, start=start, stop=stop, dtype="float32")
    em, stride = generate_emissions(sess, wave, batch_size=1)
    parts.append(em.astype(np.float32))
    idx += 1
    print(f"  chunk {idx}: samples[{start}:{stop}] -> {em.shape} frames, "
          f"stride={stride}ms, elapsed={time.time()-t0:.0f}s", flush=True)
    start = stop

emissions = np.concatenate(parts, axis=0)
np.save(OUT, emissions)
print(f"DONE emissions {emissions.shape} saved to {OUT} in {time.time()-t0:.0f}s")
print(f"implied duration: {emissions.shape[0]*0.02/60:.1f} min (frame*0.02s)")

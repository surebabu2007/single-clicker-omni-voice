# OmniVoice — One-Click Windows Installer

> Zero-shot voice cloning on your local machine. Double-click and go.

Built on [k2-fsa/OmniVoice](https://huggingface.co/k2-fsa/OmniVoice) — clone any voice from a short audio sample with no training required.

---

## What it does

- Installs everything automatically (Python venv, PyTorch, OmniVoice)
- Auto-detects your GPU and picks the right build
- Downloads the model weights (~3–4 GB, once)
- Launches a Gradio web UI at `http://127.0.0.1:7860`

---

## Requirements

| Requirement | Details |
|---|---|
| OS | Windows 10 / 11 |
| Python | 3.10 or higher — [download here](https://www.python.org/downloads/) |
| Disk space | ~5 GB free (model + venv) |
| Internet | Required on first run to download model |

> **During Python install:** make sure to check **"Add Python to PATH"**

---

## Quick Start

```
1. Clone or download this repo
2. Double-click  setup.bat          ← first time only
3. Wait for setup to finish (~10-30 min depending on internet)
4. Double-click  run.bat            ← every time after that
5. Browser opens automatically at http://127.0.0.1:7860
```

---

## Files

| File | Purpose |
|---|---|
| `setup.bat` | First-time setup — installs everything and downloads the model |
| `run.bat` | Launcher — start OmniVoice after setup is done |
| `_check_gpu.py` | Diagnostic — check which GPU mode is active |

---

## GPU Support

The installer automatically detects your hardware and installs the best build:

| Hardware | Backend | Notes |
|---|---|---|
| NVIDIA (driver ≥ 570) | CUDA 12.8 | Fastest — recommended |
| AMD / Intel GPU | torch-directml (DirectX 12) | Good performance |
| No GPU / older NVIDIA | CPU | Slower but works |

To check which mode was selected after install, run:
```
.venv\Scripts\python.exe _check_gpu.py
```

---

## How it works

```
setup.bat  (run once)
 ├── [1/8] Check Python 3.10+
 ├── [2/8] Create .venv
 ├── [3/8] Upgrade pip
 ├── [4/8] Detect GPU (NVIDIA → DirectX 12 → CPU)
 ├── [5/8] Install PyTorch (correct build for your GPU)
 ├── [6/8] Install OmniVoice
 ├── [7/8] Download model weights (~3–4 GB, resumable)
 └── [8/8] Write .installed marker

run.bat  (run every time)
 ├── Verify setup is complete
 ├── Find available port (7860–7869)
 └── Launch Gradio UI on localhost
```

**To force a clean reinstall:** delete the `.installed` file and re-run `setup.bat`.

---

## If something goes wrong

**Model download failed / slow?**
Downloads are resumable — just re-run `setup.bat`. If HuggingFace is blocked in your region, run this before launching:
```
set HF_ENDPOINT=https://hf-mirror.com
```

**Check `install_log.txt`** in the same folder for detailed error output.

**Common issues:**
- `Python not found` — install Python 3.10+ and check "Add to PATH"
- `PyTorch install failed` — check your internet connection, then re-run `setup.bat`
- `Ports 7860–7869 all in use` — close other apps using those ports
- `OmniVoice is not installed yet` — run `setup.bat` before `run.bat`

---

## Security

Gradio is always bound to `127.0.0.1` (localhost only). It is **never** exposed to your local network or the internet.

---

## Also available for macOS

- [OmniVoice One-Click Installer for macOS (Apple Silicon)](https://github.com/surebabu2007/omnivoice-oneclick-installer-mac)

---

## Credits

- Model: [k2-fsa/OmniVoice](https://huggingface.co/k2-fsa/OmniVoice) by the k2-fsa team
- Installer: [sureshpydikondala](https://github.com/sureshpydikondala) / [surebabu2007](https://github.com/surebabu2007)

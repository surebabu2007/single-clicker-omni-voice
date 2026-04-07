#!/usr/bin/env python3
"""
Diagnostic tool: reports which GPU tier OmniVoice is using on this machine.

Run manually after installation to verify your GPU setup:
  .venv\Scripts\python.exe _check_gpu.py
"""
import sys


def check_nvidia():
    try:
        import torch
        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            cuda_version = torch.version.cuda
            total_mem = torch.cuda.get_device_properties(0).total_memory
            total_mem_gb = total_mem / (1024 ** 3)
            print(f"[NVIDIA CUDA]")
            print(f"  GPU       : {device_name}")
            print(f"  CUDA      : {cuda_version}")
            print(f"  VRAM      : {total_mem_gb:.1f} GB")
            print(f"  PyTorch   : {torch.__version__}")
            return True
    except ImportError:
        pass
    return False


def check_directml():
    try:
        import torch_directml
        device = torch_directml.device()
        print(f"[DirectX 12 / torch-directml]")
        print(f"  Device    : {device}")
        try:
            import torch
            print(f"  PyTorch   : {torch.__version__}")
        except ImportError:
            pass
        return True
    except ImportError:
        pass
    return False


def check_cpu():
    try:
        import torch
        print(f"[CPU mode]")
        print(f"  PyTorch   : {torch.__version__}")
        import os
        cpu_count = os.cpu_count()
        print(f"  CPU cores : {cpu_count}")
        return True
    except ImportError:
        print("[ERROR] PyTorch is not installed.")
        print("        Run install_and_run.bat first.")
        return False


def main():
    print("OmniVoice GPU Diagnostic")
    print("=" * 30)
    print()

    if check_nvidia():
        print()
        print("Status: NVIDIA CUDA acceleration active.")
    elif check_directml():
        print()
        print("Status: DirectX 12 GPU acceleration active.")
    else:
        check_cpu()
        print()
        print("Status: CPU-only mode (no GPU acceleration).")

    print()
    print("To update GPU drivers and re-detect:")
    print("  1. Delete .installed in this folder")
    print("  2. Re-run install_and_run.bat")


if __name__ == "__main__":
    main()

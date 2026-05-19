"""
parse_qtm_poses.py
------------------
Parse QTM 6DOF pose files (position XYZ + rotation matrix 3x3)
and export to .mat (MATLAB) or .csv for trajectory plotting.

Usage:
    python parse_qtm_poses.py                          # parse all .txt in current dir
    python parse_qtm_poses.py file1.txt file2.txt      # parse specific files
    python parse_qtm_poses.py --output csv             # export as CSV instead of .mat

Output (for each input file):
    - <filename>.mat  (or .csv)  with fields: frame, x, y, z, R (3x3xN rotation matrices)
    - all_poses.mat              combining all files (useful for multi-knob comparison)
"""

import re
import os
import sys
import argparse
import numpy as np

# ── Regex patterns ────────────────────────────────────────────────────────────
RE_FRAME = re.compile(r"Framenumber:\s*(\d+)")
RE_POS   = re.compile(
    r"Pos:.*?x=([-\d.]+),\s*y=([-\d.]+),\s*z=([-\d.]+)"
)
RE_ROT   = re.compile(
    r"Rot:.*?matrix=\(([-\d.e+,\s]+)\)"
)

def parse_file(filepath: str) -> dict:
    """
    Parse a single QTM txt file.
    Returns a dict with numpy arrays:
        frames  : (N,)      int
        xyz     : (N, 3)    float  [mm]
        R       : (N, 3, 3) float  rotation matrices
    """
    frames, xyz_list, rot_list = [], [], []

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Split on frame boundaries
    # Each block starts with "Framenumber:"
    blocks = re.split(r"(?=Framenumber:)", content)

    for block in blocks:
        m_frame = RE_FRAME.search(block)
        m_pos   = RE_POS.search(block)
        m_rot   = RE_ROT.search(block)

        if not (m_frame and m_pos and m_rot):
            continue  # skip header lines or incomplete blocks

        frame_no = int(m_frame.group(1))
        x, y, z  = float(m_pos.group(1)), float(m_pos.group(2)), float(m_pos.group(3))

        # Rotation matrix: 9 values row-major
        rot_vals = [float(v) for v in m_rot.group(1).split(",")]
        R = np.array(rot_vals).reshape(3, 3)

        frames.append(frame_no)
        xyz_list.append([x, y, z])
        rot_list.append(R)

    return {
        "frames": np.array(frames, dtype=np.int32),
        "xyz":    np.array(xyz_list, dtype=np.float64),   # (N, 3) in mm
        "R":      np.array(rot_list, dtype=np.float64),   # (N, 3, 3)
        "label":  os.path.splitext(os.path.basename(filepath))[0],
    }


def export_mat(data: dict, out_path: str):
    """Export parsed data to a .mat file (MATLAB v5)."""
    try:
        import scipy.io as sio
    except ImportError:
        print("  [!] scipy not found. Install with: pip install scipy")
        return

    mat_dict = {
        "frames": data["frames"],
        "x":      data["xyz"][:, 0],
        "y":      data["xyz"][:, 1],
        "z":      data["xyz"][:, 2],
        "xyz":    data["xyz"],
        "R":      data["R"],           # shape (N, 3, 3) — in MATLAB: R(:,:,i)
        "label":  data["label"],
    }
    sio.savemat(out_path, mat_dict)
    print(f"  → Saved {out_path}  ({len(data['frames'])} frames)")


def export_csv(data: dict, out_path: str):
    """Export parsed data to CSV (position only + flattened rotation)."""
    header = "frame,x,y,z,R11,R12,R13,R21,R22,R23,R31,R32,R33"
    rows = []
    for i, fr in enumerate(data["frames"]):
        r = data["R"][i].flatten()
        rows.append(f"{fr},{data['xyz'][i,0]},{data['xyz'][i,1]},{data['xyz'][i,2]},"
                    + ",".join(f"{v:.8f}" for v in r))

    with open(out_path, "w") as f:
        f.write(header + "\n")
        f.write("\n".join(rows) + "\n")
    print(f"  → Saved {out_path}  ({len(data['frames'])} frames)")


def export_combined_mat(all_data: list, out_path: str):
    """
    Export all parsed files into one .mat as a struct array.
    In MATLAB: poses(1).xyz, poses(1).R, poses(1).label, etc.
    """
    try:
        import scipy.io as sio
    except ImportError:
        return

    combined = {}
    for d in all_data:
        lbl = d["label"].replace(" ", "_").replace("-", "_")
        combined[lbl + "_xyz"]    = d["xyz"]
        combined[lbl + "_R"]      = d["R"]
        combined[lbl + "_frames"] = d["frames"]

    sio.savemat(out_path, combined)
    print(f"\n  → Combined file: {out_path}")


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Parse QTM 6DOF pose files")
    parser.add_argument("files", nargs="*", help="Input .txt files (default: all *.txt in current dir)")
    parser.add_argument("--output", choices=["mat", "csv"], default="mat",
                        help="Output format (default: mat)")
    parser.add_argument("--combined", default="all_poses.mat",
                        help="Name for the combined .mat file (default: all_poses.mat)")
    args = parser.parse_args()

    # Gather input files
    if args.files:
        input_files = args.files
    else:
        input_files = sorted(f for f in os.listdir(".") if f.endswith(".txt"))

    if not input_files:
        print("No .txt files found.")
        sys.exit(1)

    print(f"Parsing {len(input_files)} file(s) → format: {args.output}\n")

    all_data = []
    for fpath in input_files:
        print(f"  Parsing: {fpath}")
        data = parse_file(fpath)

        if len(data["frames"]) == 0:
            print(f"  [!] No valid frames found in {fpath}")
            continue

        base = os.path.splitext(fpath)[0]
        if args.output == "mat":
            export_mat(data, base + ".mat")
        else:
            export_csv(data, base + ".csv")

        all_data.append(data)

    # Combined .mat (all knobs together, useful for comparison)
    if args.output == "mat" and len(all_data) > 1:
        export_combined_mat(all_data, args.combined)

    print("\nDone.")


if __name__ == "__main__":
    main()

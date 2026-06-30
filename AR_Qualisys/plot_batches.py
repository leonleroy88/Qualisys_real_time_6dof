"""
Visualisation des batches QTM — Position TIP vs Framenumber
Charge tous les batch_XXX.txt et les trace en couleurs distinctes
"""

import re
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from pathlib import Path

# ─── PARAMÈTRES ───────────────────────────────────────────────────────────────
BATCHES_DIR = "batches"        # Dossier contenant les batch_XXX.txt
OUTPUT_PNG  = "plot_batches.png"
FPS         = 120              # Fréquence d'acquisition (pour axe temps optionnel)
# ──────────────────────────────────────────────────────────────────────────────

def parse_batch_file(filepath: Path) -> list[dict]:
    pattern_frame = re.compile(r"Framenumber:\s*(\d+)")
    pattern_pos   = re.compile(
        r"Pos:\s*RT6DBodyPosition\(x=([\d.\-]+),\s*y=([\d.\-]+),\s*z=([\d.\-]+)\)"
    )
    frames = []
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    blocks = re.split(r"(?=Framenumber:)", content)
    for block in blocks:
        fm = pattern_frame.search(block)
        pm = pattern_pos.search(block)
        if fm and pm:
            frames.append({
                "frame": int(fm.group(1)),
                "x": float(pm.group(1)),
                "y": float(pm.group(2)),
                "z": float(pm.group(3)),
            })
    return frames


def main():
    batches_dir = Path(BATCHES_DIR)
    batch_files = sorted(batches_dir.glob("batch_*.txt"))

    if not batch_files:
        print(f"Aucun fichier batch trouvé dans '{BATCHES_DIR}/'")
        return

    print(f"{len(batch_files)} batches trouvés")

    # Charger tous les batches
    all_batches = []
    for bf in batch_files:
        frames = parse_batch_file(bf)
        if frames:
            all_batches.append({"file": bf.name, "frames": frames})
            print(f"  {bf.name}: {len(frames)} frames  "
                  f"({frames[0]['frame']} → {frames[-1]['frame']})")

    # Déterminer l'axe principal sur l'ensemble des données
    all_positions = np.array([[f["x"], f["y"], f["z"]]
                               for b in all_batches for f in b["frames"]])
    ranges = all_positions.max(axis=0) - all_positions.min(axis=0)
    main_axis = int(np.argmax(ranges))
    axis_name = "XYZ"[main_axis]
    print(f"\nAxe principal : {axis_name}  (amplitude={ranges[main_axis]:.2f}mm)")

    # ── Figure ────────────────────────────────────────────────────────────────
    colors = cm.tab20(np.linspace(0, 1, len(all_batches)))

    fig, axes = plt.subplots(2, 1, figsize=(16, 10), sharex=False)
    ax1, ax2 = axes

    # ── Plot 1 : position TIP vs framenumber (tous batches côte à côte) ──────
    for i, batch in enumerate(all_batches):
        frames_arr = np.array([[f["frame"], f["x"], f["y"], f["z"]]
                                for f in batch["frames"]])
        fn   = frames_arr[:, 0]
        pos  = frames_arr[:, main_axis + 1]
        color = colors[i]

        ax1.plot(fn, pos, color=color, linewidth=1.2, label=f"Batch {i+1}")
        ax1.axvspan(fn[0], fn[-1], alpha=0.08, color=color)
        # Étiquette au centre du batch
        ax1.text((fn[0] + fn[-1]) / 2, pos.mean(),
                 f"B{i+1}", fontsize=7, ha="center", va="bottom",
                 color=color, fontweight="bold")

    ax1.set_xlabel("Framenumber")
    ax1.set_ylabel(f"Position TIP — axe {axis_name} (mm)")
    ax1.set_title("Position TIP par batch (framenumber réel)")
    ax1.legend(loc="upper right", fontsize=7, ncol=4)
    ax1.grid(True, alpha=0.3)

    # ── Plot 2 : batches remis à zéro (frame locale 0..N) ────────────────────
    # Utile pour comparer la forme des cycles entre eux
    offset = 0
    tick_positions = []
    tick_labels    = []

    for i, batch in enumerate(all_batches):
        frames_arr = np.array([[f["frame"], f["x"], f["y"], f["z"]]
                                for f in batch["frames"]])
        pos   = frames_arr[:, main_axis + 1]
        local = np.arange(len(pos))
        color = colors[i]

        ax2.plot(local + offset, pos, color=color, linewidth=1.2)
        ax2.axvspan(offset, offset + len(pos), alpha=0.08, color=color)
        ax2.text(offset + len(pos) / 2, pos.mean(),
                 f"B{i+1}", fontsize=7, ha="center", va="bottom",
                 color=color, fontweight="bold")

        tick_positions.append(offset + len(pos) / 2)
        tick_labels.append(f"B{i+1}\n({len(pos)}f)")

        # Ligne de séparation entre batches
        if i < len(all_batches) - 1:
            ax2.axvline(offset + len(pos), color="gray", linestyle="--",
                        linewidth=0.7, alpha=0.5)
        offset += len(pos)

    ax2.set_xticks(tick_positions)
    ax2.set_xticklabels(tick_labels, fontsize=7)
    ax2.set_ylabel(f"Position TIP — axe {axis_name} (mm)")
    ax2.set_title("Batches mis bout à bout (frames locales) — forme des cycles")
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(OUTPUT_PNG, dpi=150, bbox_inches="tight")
    print(f"\n✓ Graphique sauvegardé : {OUTPUT_PNG}")
    plt.show()


if __name__ == "__main__":
    main()

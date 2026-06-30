"""
Script de découpage des données QTM en batches
Détecte et supprime les plateaux aux positions extrêmes (attente interface)
"""

import re
import numpy as np
from pathlib import Path
import json
import matplotlib.pyplot as plt
import numpy as np
# ─── PARAMÈTRES ───────────────────────────────────────────────────────────────
INPUT_FILE = "poses_qtm_20260527_154353_grande_decrevrai.txt"       # Fichier de données QTM brut
OUTPUT_DIR = "batches"            # Dossier de sortie
PLATEAU_THRESHOLD = 0.15          # mm — déplacement max pour considérer "immobile"
PLATEAU_MIN_FRAMES = 100           # Nombre min de frames immobiles pour détecter un plateau
# ──────────────────────────────────────────────────────────────────────────────


def parse_qtm_file(filepath: str) -> list[dict]:
    """Parse le fichier QTM et retourne une liste de frames."""
    frames = []
    pattern_frame = re.compile(r"Framenumber:\s*(\d+)")
    pattern_pos   = re.compile(
        r"Pos:\s*RT6DBodyPosition\(x=([\d.\-]+),\s*y=([\d.\-]+),\s*z=([\d.\-]+)\)"
    )
    pattern_rot   = re.compile(
        r"Rot:\s*RT6DBodyRotation\(matrix=\(([^)]+)\)\)"
    )

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Découper par frame
    blocks = re.split(r"(?=Framenumber:)", content)
    for block in blocks:
        fm = pattern_frame.search(block)
        pm = pattern_pos.search(block)
        rm = pattern_rot.search(block)
        if fm and pm and rm:
            rot_values = [float(v.strip()) for v in rm.group(1).split(",")]
            frames.append({
                "frame": int(fm.group(1)),
                "x": float(pm.group(1)),
                "y": float(pm.group(2)),
                "z": float(pm.group(3)),
                "rot": rot_values,
            })

    print(f"  → {len(frames)} frames parsées")
    return frames


def detect_plateaux(frames: list[dict], threshold: float, min_frames: int) -> list[tuple[int,int]]:
    """Détecte les plateaux d'immobilité, peu importe leur position sur l'axe."""
    positions = np.array([[f["x"], f["y"], f["z"]] for f in frames])

    # Déplacement frame-à-frame
    deltas = np.linalg.norm(np.diff(positions, axis=0), axis=1)
    immobile = deltas < threshold

    plateaux = []
    i = 0
    while i < len(immobile):
        if immobile[i]:
            j = i
            while j < len(immobile) and immobile[j]:
                j += 1
            length = j - i + 1
            
            # Si le temps de pause est suffisant, on le considère comme un cut valide
            if length >= min_frames:
                plateaux.append((i, i + length))
                
            i = j
        else:
            i += 1

    return plateaux


def split_into_batches(frames: list[dict], plateaux: list[tuple[int,int]]) -> list[list[dict]]:
    """Découpe la liste de frames en excluant les plateaux, sans générer de batches fantômes."""
    if not plateaux:
        return [frames]

    batches = []
    prev_end = 0

    for (p_start, p_end) in plateaux:
        segment = frames[prev_end:p_start]
        # On ne garde le segment que s'il représente un vrai mouvement (> 1 frame)
        if len(segment) > 1:
            batches.append(segment)
        prev_end = p_end

    # Traitement du tout dernier segment après le dernier plateau
    last_segment = frames[prev_end:]
    if len(last_segment) > 1:
        batches.append(last_segment)

    return batches


def frame_to_line(f: dict) -> str:
    rot_str = ", ".join(f"{v}" for v in f["rot"])
    return (
        f"Framenumber: {f['frame']} - Body count: 1\n"
        f"Pos: RT6DBodyPosition(x={f['x']}, y={f['y']}, z={f['z']}) - "
        f"Rot: RT6DBodyRotation(matrix=({rot_str}))\n"
    )


def save_batches(batches: list[list[dict]], output_dir: str):
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    summary = []
    for i, batch in enumerate(batches):
        filename = out / f"batch_{i+1:03d}.txt"
        with open(filename, "w", encoding="utf-8") as f:
            f.write(f"# Batch {i+1} — {len(batch)} frames\n")
            f.write(f"# Frame début: {batch[0]['frame']}  |  Frame fin: {batch[-1]['frame']}\n\n")
            for frame in batch:
                f.write(frame_to_line(frame))

        summary.append({
            "batch": i + 1,
            "frames": len(batch),
            "frame_start": batch[0]["frame"],
            "frame_end": batch[-1]["frame"],
            "filename": str(filename),
        })
        print(f"  Batch {i+1:3d}: frames {batch[0]['frame']}–{batch[-1]['frame']}  ({len(batch)} frames)")

    # Résumé JSON
    with open(out / "summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    print(f"\n  ✓ {len(batches)} batches sauvegardés dans '{output_dir}/'")
    print(f"  ✓ Résumé: {output_dir}/summary.json")


# ─── DEMO : génération de données synthétiques ────────────────────────────────
def generate_demo_data(n_cycles=3, n_move=200, n_plateau=300) -> list[dict]:
    """Génère des données synthétiques avec plateaux pour tester le script."""
    import math
    frames = []
    fn = 87000
    x, y, z = 55.0, 205.0, 379.0

    rot_base = [
        -0.848, 0.399, -0.348,
        -0.401, -0.913, -0.070,
        -0.346, 0.080, 0.935,
    ]

    for cycle in range(n_cycles):
        # Phase mouvement (aller)
        for i in range(n_move):
            t = i / n_move
            x += math.sin(t * math.pi) * 0.15
            y += 0.01
            z += 0.005
            frames.append({"frame": fn, "x": x, "y": y, "z": z, "rot": rot_base[:]})
            fn += 1

        # Plateau (position extrême)
        for _ in range(n_plateau):
            frames.append({"frame": fn, "x": x + np.random.normal(0, 0.01),
                           "y": y + np.random.normal(0, 0.01),
                           "z": z + np.random.normal(0, 0.01), "rot": rot_base[:]})
            fn += 1

        # Phase mouvement (retour)
        for i in range(n_move):
            t = i / n_move
            x -= math.sin(t * math.pi) * 0.15
            y -= 0.01
            z -= 0.005
            frames.append({"frame": fn, "x": x, "y": y, "z": z, "rot": rot_base[:]})
            fn += 1

        # Plateau (position neutre)
        for _ in range(n_plateau // 2):
            frames.append({"frame": fn, "x": x + np.random.normal(0, 0.01),
                           "y": y + np.random.normal(0, 0.01),
                           "z": z + np.random.normal(0, 0.01), "rot": rot_base[:]})
            fn += 1

    return frames

def plot_sequences_concatenees(batches):
    """
    Trace les batches les uns après les autres en reconstruisant 
    l'axe des angles molette.
    """
    # Ta séquence exacte : 0 -> 120 -> -80 -> 100 -> -50 -> 50 -> 0
    # Cela correspond à 6 segments (6 batches)
    angles_cibles = [0, 120, -80, 100, -50, 50, 0]

    if len(batches) != 6:
        print(f"⚠️ Attention : Tu as {len(batches)} batches mais ta séquence d'angles en prévoit 6.")
        print("Ajuste 'PLATEAU_MIN_FRAMES' à 60 ou 80 pour fusionner les faux batches.")
        if len(batches) < 6: return

    plt.figure(figsize=(12, 6))
    
    # Pour tracer "bout à bout" comme sur ton image, on va accumuler les données
    all_angles = []
    all_pos = []
    separateurs = [0] # Pour dessiner les lignes verticales entre batches

    for i in range(len(angles_cibles) - 1):
        if i >= len(batches): break
        
        batch = batches[i]
        angle_start = angles_cibles[i]
        angle_end = angles_cibles[i+1]
        
        # Création de l'axe X pour ce batch (interpolation)
        angles_batch = np.linspace(angle_start, angle_end, len(batch))
        
        # Extraction de la position TIP (on prend 'x' par défaut)
        pos_batch = [f["x"] for f in batch]
        
        # Affichage individuel pour avoir des couleurs différentes
        plt.plot(np.arange(len(all_pos), len(all_pos) + len(batch)), 
                 pos_batch, label=f"B{i+1}: {angle_start}° ➔ {angle_end}°")
        
        all_pos.extend(pos_batch)
        separateurs.append(len(all_pos))

    # Esthétique du graphique
    for s in separateurs:
        plt.axvline(x=s, color='gray', linestyle='--', alpha=0.3)

    plt.title("Position TIP par Batch (Mise bout à bout)", fontsize=12, fontweight='bold')
    plt.ylabel("Position TIP (mm)")
    plt.xlabel("Points de mesure (Frames cumulées)")
    plt.legend(loc='upper right', fontsize='small', ncol=2)
    plt.grid(True, alpha=0.2)
    plt.show()

    # --- DEUXIÈME GRAPHIQUE : L'HYSTÉRÉSIS (XY) ---
    plt.figure(figsize=(8, 6))
    for i in range(len(angles_cibles) - 1):
        if i >= len(batches): break
        angles_batch = np.linspace(angles_cibles[i], angles_cibles[i+1], len(batches[i]))
        plt.plot(angles_batch, [f["x"] for f in batches[i]], linewidth=2)

    plt.title("Courbe d'Hystérésis (Position vs Angle)")
    plt.xlabel("Angle Molette théorique (°)")
    plt.ylabel("Position TIP (mm)")
    plt.grid(True)
    plt.show()
# ─── MAIN ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  QTM Batch Splitter — Suppression des plateaux")
    print("=" * 60)

    input_path = Path(INPUT_FILE)

    if input_path.exists():
        print(f"\n[1/4] Lecture de '{INPUT_FILE}'...")
        frames = parse_qtm_file(INPUT_FILE)
    else:
        print(f"\n[INFO] '{INPUT_FILE}' non trouvé → génération de données de démonstration")
        frames = generate_demo_data(n_cycles=5, n_move=200, n_plateau=400)
        print(f"  → {len(frames)} frames générées (5 cycles avec plateaux de ~400 frames)")

    print(f"\n[2/4] Détection des plateaux (seuil={PLATEAU_THRESHOLD}mm, min={PLATEAU_MIN_FRAMES} frames)...")
    plateaux = detect_plateaux(frames, PLATEAU_THRESHOLD, PLATEAU_MIN_FRAMES)
    print(f"  → {len(plateaux)} plateau(x) détecté(s)")
    for i, (s, e) in enumerate(plateaux):
        print(f"     Plateau {i+1}: frames idx {s}–{e}  ({e-s} frames, ~{(e-s)/120:.1f}s à 120Hz)")

    frames_avant  = len(frames)
    frames_plateau = sum(e - s for s, e in plateaux)
    print(f"  → {frames_plateau} frames supprimées ({frames_plateau/frames_avant*100:.1f}% du total)")

    print(f"\n[3/4] Découpage en batches...")
    batches = split_into_batches(frames, plateaux)
    print(f"  → {len(batches)} batch(es) créé(s)")

    print(f"\n[4/4] Sauvegarde dans '{OUTPUT_DIR}/'...")
    save_batches(batches, OUTPUT_DIR)
    plot_sequences_concatenees(batches)
    # ── Vérification intégrité première/dernière frame ──
    first_in  = frames[0]["frame"]
    last_in   = frames[-1]["frame"]
    first_out = batches[0][0]["frame"]
    last_out  = batches[-1][-1]["frame"]

    print("\n" + "=" * 60)
    print("  Terminé !")
    print(f"  Total frames conservées : {sum(len(b) for b in batches)} / {frames_avant}")
    print(f"\n  Vérification intégrité :")
    ok1 = "✓" if first_out == first_in else "✗ ERREUR"
    ok2 = "✓" if last_out  == last_in  else "✗ ERREUR"
    print(f"    {ok1}  Première frame : input={first_in}  →  batch_001[0]={first_out}")
    print(f"    {ok2}  Dernière frame  : input={last_in}  →  batch_last[-1]={last_out}")
    print("=" * 60)

# ── patch intégrité appliqué en post-traitement ──



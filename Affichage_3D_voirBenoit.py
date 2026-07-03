import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import os

def charger_donnees(filepath):
    cibles, X, Y, Z, R_matrices = [], [], [], [], []
    if not os.path.exists(filepath):
        print(f"Erreur: Le fichier {filepath} est introuvable.")
        return None, None, None, None, None
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if '|' not in line or "CIBLE" in line or "===" in line: continue
            parts = [p.strip() for p in line.split('|')]
            try:
                cibles.append(float(parts[0]))
                X.append(float(parts[4])); Y.append(float(parts[5])); Z.append(float(parts[6]))
                mat = np.array([float(p) for p in parts[7:16]]).reshape(3, 3)
                R_matrices.append(mat)
            except (ValueError, IndexError): continue
    return np.array(cibles), np.array(X), np.array(Y), np.array(Z), np.array(R_matrices)

# --- CONFIGURATION ---
FILE_PATH = "synchro_moteur_qtm_20260630_154922petite_matrice.txt"
OUTPUT_PATH = "synchro_moteur_qtm_20260630_154922_Rpp.txt"

cibles, X, Y, Z, R_matrices = charger_donnees(FILE_PATH)

if X is not None:
    # 1. CALCUL DU PLAN
    A = np.c_[X, Y, np.ones(X.shape[0])]
    C, _, _, _ = np.linalg.lstsq(A, Z, rcond=None)
    a, b, c = C
    centroid = np.array([np.mean(X), np.mean(Y), np.mean(Z)])

    # 2. REPÈRE LOCAL (U, V, Normale)
    normal = np.array([a, b, -1.0]); normal /= np.linalg.norm(normal)
    v_tmp = np.array([0, 1, 0]) if np.abs(normal[0]) > 0.9 else np.array([1, 0, 0])
    vec_U = np.cross(v_tmp, normal); vec_U /= np.linalg.norm(vec_U)
    vec_V = np.cross(normal, vec_U)
    Rn = np.column_stack((vec_U, vec_V, normal))

    # --- CALCUL Rpp ---
    Rpp_list = [np.dot(Rn.T, R) for R in R_matrices]

    # --- EXTRACTION DE LA ROTATION DANS LE PLAN (FLEXION PURE) ---
    Rpp_ref = Rpp_list[0]
    angles_flexion = []
    
    for Rpp in Rpp_list:
        R_rel_plane = np.dot(Rpp, Rpp_ref.T)
        angle_z = np.degrees(np.arctan2(R_rel_plane[1, 0], R_rel_plane[0, 0]))
        angles_flexion.append(angle_z)
        
    angles_flexion = np.unwrap(np.radians(angles_flexion))
    angles_flexion = np.degrees(angles_flexion)

    # 3. AFFICHAGE EN GRILLE PERSONNALISÉE
    U_coords = np.dot(np.c_[X, Y, Z] - centroid, vec_U)
    V_coords = np.dot(np.c_[X, Y, Z] - centroid, vec_V)
    idx_reb = np.where(cibles == -50.0)[0][0]

    fig = plt.figure(figsize=(16, 12))
    fig.suptitle("Analyse de la Trajectoire - Repère Local et Hystérésis Planaire", fontsize=16, fontweight='bold')

    # Utilisation de GridSpec pour gérer les proportions (ligne du haut plus grande)
    gs = gridspec.GridSpec(2, 2, height_ratios=[1.8, 1])

    # Panneau 1 : Trajectoire 3D (Haut Gauche)
    ax1 = fig.add_subplot(gs[0, 0], projection='3d')
    ax1.plot(X, Y, Z, 'k.-', alpha=0.3, label='Trajectoire')
    ax1.plot(X[:idx_reb+1], Y[:idx_reb+1], Z[:idx_reb+1], 'b.-', label='Aller')
    ax1.plot(X[idx_reb:], Y[idx_reb:], Z[idx_reb:], 'r.-', label='Retour')
    ax1.set_title("1. Trajectoire 3D")
    ax1.legend()

    # Panneau 2 : Plan, Normale, et vecteurs U/V (Haut Droite)
    ax2 = fig.add_subplot(gs[0, 1], projection='3d')
    xx, yy = np.meshgrid(np.linspace(min(X), max(X), 5), np.linspace(min(Y), max(Y), 5))
    zz = a * xx + b * yy + c
    ax2.plot_surface(xx, yy, zz, color='gray', alpha=0.2)
    ax2.plot(X[:idx_reb+1], Y[:idx_reb+1], Z[:idx_reb+1], 'b.-', alpha=0.6, label='Aller')
    ax2.plot(X[idx_reb:], Y[idx_reb:], Z[idx_reb:], 'r.-', alpha=0.6, label='Retour')

    arrow_len = 15
    ax2.quiver(centroid[0], centroid[1], centroid[2], normal[0]*arrow_len, normal[1]*arrow_len, normal[2]*arrow_len, color='green', linewidth=4, label='Normale (n)')
    ax2.quiver(centroid[0], centroid[1], centroid[2], vec_U[0]*arrow_len, vec_U[1]*arrow_len, vec_U[2]*arrow_len, color='orange', linewidth=3, label='Vecteur U')
    ax2.quiver(centroid[0], centroid[1], centroid[2], vec_V[0]*arrow_len, vec_V[1]*arrow_len, vec_V[2]*arrow_len, color='purple', linewidth=3, label='Vecteur V')
    ax2.set_title("2. Plan et Repère Local (n, U, V)")
    ax2.legend()
    
    max_range = np.array([X.max()-X.min(), Y.max()-Y.min(), Z.max()-Z.min()]).max() / 2.0
    mid_x, mid_y, mid_z = (X.max()+X.min())/2, (Y.max()+Y.min())/2, (Z.max()+Z.min())/2
    ax2.set_xlim(mid_x - max_range, mid_x + max_range); ax2.set_ylim(mid_y - max_range, mid_y + max_range); ax2.set_zlim(mid_z - max_range, mid_z + max_range)
    ax2.set_box_aspect([1, 1, 1])

    # Panneau 3 : Projection 2D (Bas Gauche)
    ax3 = fig.add_subplot(gs[1, 0])
    ax3.plot(U_coords[:idx_reb+1], V_coords[:idx_reb+1], 'b.-', label='Aller')
    ax3.plot(U_coords[idx_reb:], V_coords[idx_reb:], 'r.-', label='Retour')
    ax3.set_aspect('equal')
    ax3.set_title("3. Projection 2D (U, V)")
    ax3.grid(True, linestyle=':')
    ax3.legend()

    # Panneau 4 : Hystérésis VRAIE (Bas Droite)
    ax4 = fig.add_subplot(gs[1, 1])
    ax4.plot(cibles[:idx_reb+1], angles_flexion[:idx_reb+1], 'b.-', label='Aller')
    ax4.plot(cibles[idx_reb:], angles_flexion[idx_reb:], 'r.-', label='Retour')
    ax4.set_xlabel("Angle Molette Demandé (°)")
    ax4.set_ylabel("Flexion Vraie dans le plan (°)")
    ax4.set_title("4. Hystérésis (Rotation autour de n)")
    ax4.grid(True, linestyle=':')
    ax4.legend()

    # Ajustement des marges
    plt.tight_layout(rect=[0, 0.03, 1, 0.95], h_pad=4.0, w_pad=4.0)
    plt.savefig("analyse_trajectoire.png", dpi=150)
    plt.show()

    # --- 4. EXPORT DU FICHIER TXT ---
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        header = (
            "CIBLE (°)  | FLEX_PLAN | RPP00    | RPP01    | RPP02    | RPP10    | RPP11    | "
            "RPP12    | RPP20    | RPP21    | RPP22   \n"
        )
        sep = "=" * (len(header) - 1) + "\n"
        f.write(sep); f.write(header); f.write(sep)
        for cible, ang, Rpp in zip(cibles, angles_flexion, Rpp_list):
            vals = Rpp.flatten()
            line = f"{cible:<10.1f} | {ang:<9.3f} | " + " | ".join(f"{v:<8.4f}" for v in vals) + " \n"
            f.write(line)

    print(f"Fichier exporté : {OUTPUT_PATH}")
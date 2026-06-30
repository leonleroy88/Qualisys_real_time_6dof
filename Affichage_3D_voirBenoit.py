import matplotlib.pyplot as plt
import numpy as np
import os

def charger_donnees(filepath):
    cibles, X, Y, Z = [], [], [], []
    
    if not os.path.exists(filepath):
        print(f"Erreur: Le fichier {filepath} est introuvable.")
        return None, None, None, None
        
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if '|' not in line or "CIBLE" in line or "===" in line:
                continue
            
            parts = [p.strip() for p in line.split('|')]
            try:
                cibles.append(float(parts[0]))
                X.append(float(parts[4]))
                Y.append(float(parts[5]))
                Z.append(float(parts[6]))
            except (ValueError, IndexError):
                continue
    return np.array(cibles), np.array(X), np.array(Y), np.array(Z)

# --- CONFIGURATION ---
FILE_PATH = "synchro_moteur_qtm_20260630_154922petite_matrice.txt"
cibles, X, Y, Z = charger_donnees(FILE_PATH)

if X is not None:
    # 1. CALCUL DU PLAN
    A = np.c_[X, Y, np.ones(X.shape[0])]
    C, _, _, _ = np.linalg.lstsq(A, Z, rcond=None)
    a, b, c = C
    centroid = np.array([np.mean(X), np.mean(Y), np.mean(Z)])

    # 2. REPÈRE LOCAL 2D
    normal = np.array([a, b, -1.0])
    normal = normal / np.linalg.norm(normal)
    v_tmp = np.array([1, 0, 0])
    if np.abs(np.dot(normal, v_tmp)) > 0.9: v_tmp = np.array([0, 1, 0])
    vec_U = np.cross(v_tmp, normal); vec_U /= np.linalg.norm(vec_U)
    vec_V = np.cross(normal, vec_U)

    points_3d_centres = np.c_[X, Y, Z] - centroid
    U_coords = np.dot(points_3d_centres, vec_U)
    V_coords = np.dot(points_3d_centres, vec_V)

    index_rebroussement = np.where(cibles == -50.0)[0][0]

    # --- AFFICHAGE EN 3 PANNEAUX ---
    fig = plt.figure(figsize=(24, 7))

    # Panneau 1 : Trajectoire 3D Brute avec marqueurs
    ax1 = fig.add_subplot(131, projection='3d')
    ax1.plot(X[:index_rebroussement+1], Y[:index_rebroussement+1], Z[:index_rebroussement+1], 'b-o', markersize=4, label='Aller')
    ax1.plot(X[index_rebroussement:], Y[index_rebroussement:], Z[index_rebroussement:], 'r-o', markersize=4, label='Retour')
    ax1.set_title("1. Trajectoire 3D")
    ax1.legend()

    # Panneau 2 : Ajustement Plan (3D) - Échelle 1:1
    ax2 = fig.add_subplot(132, projection='3d')
    ax2.plot(X[:index_rebroussement+1], Y[:index_rebroussement+1], Z[:index_rebroussement+1], 'b-o', markersize=4)
    ax2.plot(X[index_rebroussement:], Y[index_rebroussement:], Z[index_rebroussement:], 'r-o', markersize=4)
    
    grid_x, grid_y = np.meshgrid(np.linspace(min(X), max(X), 10), np.linspace(min(Y), max(Y), 10))
    grid_z = a * grid_x + b * grid_y + c
    ax2.plot_surface(grid_x, grid_y, grid_z, color='gray', alpha=0.3)
    ax2.set_title("2. Ajustement Plan (Echelle 1:1)")
    
    # Forcer l'échelle 1:1
    max_range = np.array([max(X)-min(X), max(Y)-min(Y), max(Z)-min(Z)]).max() / 2.0
    ax2.set_xlim(centroid[0] - max_range, centroid[0] + max_range)
    ax2.set_ylim(centroid[1] - max_range, centroid[1] + max_range)
    ax2.set_zlim(centroid[2] - max_range, centroid[2] + max_range)

    # Panneau 3 : Projection 2D avec marqueurs
    ax3 = fig.add_subplot(133)
    ax3.plot(U_coords[:index_rebroussement+1], V_coords[:index_rebroussement+1], 'b-o', markersize=5, label='Aller')
    ax3.plot(U_coords[index_rebroussement:], V_coords[index_rebroussement:], 'r-o', markersize=5, label='Retour')
    ax3.set_aspect('equal')
    ax3.set_title("3. Projection 2D sur le plan")
    ax3.grid(True)
    ax3.legend()

    plt.tight_layout()
    plt.show()
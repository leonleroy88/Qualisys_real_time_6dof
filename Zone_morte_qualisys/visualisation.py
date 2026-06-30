import re
import numpy as np
import matplotlib.pyplot as plt
from scipy.spatial.transform import Rotation as R
from scipy.signal import find_peaks
from mpl_toolkits.mplot3d.art3d import Line3DCollection

# 1. PARSING DES DONNÉES
def load_qtm_data(file_path):
    positions = []
    
    # Regex pour capter x, y, z
    pattern = re.compile(r"x=([-.\d]+),\s*y=([-.\d]+),\s*z=([-.\d]+)")
    
    with open(file_path, 'r') as f:
        for line in f:
            if "Pos: RT6DBodyPosition" in line:
                match = pattern.search(line)
                if match:
                    x, y, z = float(match.group(1)), float(match.group(2)), float(match.group(3))
                    positions.append([x, y, z])
                    
    return np.array(positions)

# 2. DÉTECTION DES DEMI-TOURS (Pour placer des repères)
def get_turnarounds(positions):
    centered = positions - np.mean(positions, axis=0)
    U, S, Vt = np.linalg.svd(centered, full_matrices=False)
    projection = np.dot(centered, Vt[0])
    
    prominence = np.ptp(projection) * 0.20
    peaks, _ = find_peaks(projection, prominence=prominence)
    valleys, _ = find_peaks(-projection, prominence=prominence)
    
    # On retourne uniquement les index des pics et vallées (les inversions)
    return np.sort(np.concatenate((peaks, valleys)))

# 3. VISUALISATION 3D AVEC GRADIENT TEMP0REL
def plot_trajectory_time_gradient(positions, turnarounds):
    fig = plt.figure(figsize=(10, 8), facecolor='w')
    ax = fig.add_subplot(111, projection='3d')
    
    x = positions[:, 0]
    y = positions[:, 1]
    z = positions[:, 2]
    time = np.arange(len(positions)) # L'axe du temps (index des frames)
    
    # Création des segments pour appliquer le gradient
    points = np.array([x, y, z]).T.reshape(-1, 1, 3)
    segments = np.concatenate([points[:-1], points[1:]], axis=1)
    
    # Configuration du gradient de couleur (colormap 'plasma' : Bleu -> Violet -> Rouge -> Jaune)
    cmap = plt.get_cmap('plasma')
    norm = plt.Normalize(time.min(), time.max())
    
    # Application aux lignes
    lc = Line3DCollection(segments, cmap=cmap, norm=norm, linewidth=2.5)
    lc.set_array(time)
    ax.add_collection3d(lc)
    
    # Fixer les limites des axes manuellement (requis avec Line3DCollection)
    ax.set_xlim(x.min(), x.max())
    ax.set_ylim(y.min(), y.max())
    ax.set_zlim(z.min(), z.max())
    
    # Marquer les points d'inversion (demi-tours)
    for i, idx in enumerate(turnarounds):
        label = 'Inversion (demi-tour)' if i == 0 else "" # Pour éviter les doublons dans la légende
        ax.plot([x[idx]], [y[idx]], [z[idx]], marker='*', color='black', 
                markersize=12, linestyle='None', label=label, zorder=5)

    # Position initiale (Rond vert) et finale (Carré rouge)
    ax.plot([x[0]], [y[0]], [z[0]], marker='o', color='green', markersize=8, linestyle='None', label='Position Initiale', zorder=5)
    ax.plot([x[-1]], [y[-1]], [z[-1]], marker='s', color='red', markersize=8, linestyle='None', label='Position Finale', zorder=5)

    # Ajout de la barre de couleur (Légende du gradient)
    cbar = fig.colorbar(lc, ax=ax, shrink=0.5, pad=0.1)
    cbar.set_label('Évolution temporelle (Frames)', rotation=270, labelpad=15)

    # Configuration esthétique
    ax.set_title('Grande molette - Trajectoire temporelle', fontweight='bold', pad=20)
    ax.set_xlabel('X (mm)', labelpad=10)
    ax.set_ylabel('Y (mm)', labelpad=10)
    ax.set_zlabel('Z (mm)', labelpad=10)
    
    ax.grid(True)
    ax.view_init(elev=25, azim=-45)
    ax.legend(loc='upper right', bbox_to_anchor=(1.1, 1.05))
    
    plt.tight_layout()
    plt.show()

# --- EXÉCUTION ---
if __name__ == "__main__":
    fichier_txt = r"C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_LEONqtm_20260520_144603.txt"
    
    try:
        # 1. Extraction
        positions = load_qtm_data(fichier_txt)
        
        # 2. Trouver les index des demi-tours
        turnarounds = get_turnarounds(positions)
        print(f"✓ {len(turnarounds)} demi-tours détectés aux frames : {turnarounds}")
        
        # 3. Affichage graphique
        plot_trajectory_time_gradient(positions, turnarounds)
        
    except FileNotFoundError:
        print(f"Fichier introuvable. Vérifiez le nom : {fichier_txt}")
#!/usr/bin/env python3
"""
Affichage 3D simple de la trajectoire spatiale de la pointe de la sonde.
"""

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Tes données brutes copiées/collées
data_raw = """
60.0       | 222.19     | 88.12      | 31753    | 146.28     | 127.92     | 259.81     | 13.35      | 33.61      | -161.57   
50.0       | 208.12     | 88.75      | 31836    | 146.30     | 127.99     | 259.74     | 13.38      | 33.70      | -161.56   
40.0       | 193.18     | 88.79      | 31919    | 146.31     | 127.90     | 260.02     | 13.36      | 33.53      | -161.62   
30.0       | 178.33     | 88.89      | 32003    | 146.53     | 127.84     | 261.11     | 13.24      | 32.61      | -161.97   
20.0       | 163.39     | 88.93      | 32086    | 147.38     | 127.88     | 264.06     | 13.17      | 29.85      | -162.76   
10.0       | 148.54     | 89.02      | 32169    | 149.24     | 127.96     | 269.00     | 13.23      | 24.52      | -163.91   
0.0        | 133.77     | 89.18      | 32252    | 152.74     | 128.13     | 274.67     | 12.95      | 17.23      | -165.63   
-10.0      | 118.83     | 89.22      | 32335    | 156.86     | 128.24     | 279.72     | 12.74      | 9.86       | -167.38   
-20.0      | 103.97     | 89.32      | 32418    | 161.13     | 128.44     | 284.08     | 12.82      | 3.03       | -168.94   
-30.0      | 89.21      | 89.47      | 32502    | 164.40     | 128.67     | 286.95     | 13.02      | -1.77      | -170.02   
-40.0      | 74.53      | 89.69      | 32585    | 168.62     | 128.98     | 290.17     | 13.48      | -7.61      | -171.40   
-50.0      | 59.77      | 89.84      | 32668    | 172.82     | 129.27     | 292.87     | 14.03      | -13.09     | -172.80   
-40.0      | 73.39      | 88.93      | 32751    | 172.82     | 129.30     | 292.83     | 14.02      | -13.08     | -172.81   
-30.0      | 88.33      | 88.89      | 32834    | 172.39     | 129.17     | 292.41     | 13.95      | -12.53     | -172.73   
-20.0      | 103.10     | 88.73      | 32918    | 171.02     | 129.00     | 291.24     | 13.73      | -10.85     | -172.34   
-10.0      | 118.04     | 88.69      | 33001    | 166.73     | 128.59     | 287.67     | 13.02      | -5.20      | -170.92   
0.0        | 132.98     | 88.65      | 33084    | 161.45     | 128.25     | 283.07     | 12.61      | 2.54       | -169.19   
10.0       | 147.83     | 88.55      | 33167    | 157.38     | 128.04     | 279.05     | 12.55      | 9.10       | -167.75   
20.0       | 162.69     | 88.46      | 33249    | 153.50     | 127.89     | 274.32     | 12.67      | 16.05      | -166.14   
30.0       | 177.63     | 88.42      | 33334    | 151.10     | 127.80     | 270.78     | 12.85      | 20.83      | -165.02   
40.0       | 192.39     | 88.26      | 33416    | 149.34     | 127.79     | 267.52     | 13.02      | 24.72      | -164.00   
50.0       | 207.25     | 88.16      | 33500    | 147.80     | 127.87     | 263.69     | 13.09      | 29.28      | -162.97   
60.0       | 222.19     | 88.12      | 33583    | 146.33     | 127.86     | 259.72     | 13.47      | 33.68      | -161.76   
"""

# Listes pour stocker les coordonnées
X, Y, Z = [], [], []
cibles = []

# Extraction des données
for line in data_raw.strip().split('\n'):
    parts = [p.strip() for p in line.split('|')]
    if len(parts) >= 7:
        cibles.append(float(parts[0]))
        X.append(float(parts[4]))
        Y.append(float(parts[5]))
        Z.append(float(parts[6]))

# Séparation Aller / Retour pour les couleurs (le point de rebroussement est à -50)
index_rebroussement = cibles.index(-50.0)

X_aller, Y_aller, Z_aller = X[:index_rebroussement+1], Y[:index_rebroussement+1], Z[:index_rebroussement+1]
X_retour, Y_retour, Z_retour = X[index_rebroussement:], Y[index_rebroussement:], Z[index_rebroussement:]

# --- Création du graphique 3D ---
fig = plt.figure(figsize=(10, 8))
ax = fig.add_subplot(111, projection='3d')

# Tracé de la ligne Aller (Descente) en bleu
ax.plot(X_aller, Y_aller, Z_aller, color='#3182CE', marker='o', label='Aller (Descente)', linewidth=2)

# Tracé de la ligne Retour (Montée) en rouge
ax.plot(X_retour, Y_retour, Z_retour, color='#E53E3E', marker='o', label='Retour (Montée)', linewidth=2)

# Ajout du point de départ et d'arrivée
ax.scatter(X[0], Y[0], Z[0], color='green', s=100, label='Départ (+60°)', zorder=5)
ax.scatter(X[index_rebroussement], Y[index_rebroussement], Z[index_rebroussement], color='purple', s=100, label='Rebroussement (-50°)', zorder=5)

# Configuration de l'affichage
ax.set_title('Trajectoire 3D du bout de la sonde (Hystérésis Spatiale)', fontweight='bold')
ax.set_xlabel('Position X (mm)')
ax.set_ylabel('Position Y (mm)')
ax.set_zlabel('Position Z (mm)')

ax.legend()
plt.show()
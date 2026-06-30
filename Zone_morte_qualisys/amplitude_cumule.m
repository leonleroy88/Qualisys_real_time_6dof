clear; clc; close all;

%% 1. PARAMÈTRES
fichier_petite = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_petite_molette_v2.txt';
fichier_grande = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_grande_molette_v2.txt';

%% 2. CHARGEMENT DES POSITIONS
% Plus de découpage, on charge les deux cycles complets
pos_petite = load_qtm_data(fichier_petite);
pos_grande = load_qtm_data(fichier_grande);

%% 3. CALCUL DU DÉPLACEMENT CUMULÉ DU TIP
disp_petite = [0; sqrt(sum(diff(pos_petite).^2, 2))];
disp_grande = [0; sqrt(sum(diff(pos_grande).^2, 2))];

cumul_petite = cumsum(disp_petite);
cumul_grande = cumsum(disp_grande);

%% 4. CRÉATION D'UN AXE TEMPOREL EN %
x_petite = linspace(0, 100, length(cumul_petite));
x_grande = linspace(0, 100, length(cumul_grande));

%% 5. AFFICHAGE DU GRAPHIQUE AVEC DOUBLE AXE
figure('Name', 'Comparaison Petite vs Grande Molette', 'Color', 'w', 'Position', [100, 100, 950, 550]);
grid on; hold on;

% --- AXE GAUCHE : Déplacement cumulé ---
yyaxis left;
ax = gca;
ax.YColor = 'k'; 

% Tracé des déplacements
plot(x_petite, cumul_petite, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Petite Molette (Déplacement)');
plot(x_grande, cumul_grande, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Grande Molette (Déplacement)');

ylabel('Déplacement cumulé du TIP (mm)', 'Color', 'k', 'FontWeight', 'bold');
ylim([0, max([cumul_petite(end), cumul_grande(end)]) * 1.1]);

% --- AXE DROIT : Profil d'angle théorique ---
yyaxis right;
ax.YColor = [0.4 0.4 0.4];

% Pourcentages clés du mouvement
pourcentages_cles = [0, 25, 50, 75, 100];

% Création du profil d'angle Petite Molette (0 -> +60 -> 0 -> -70 -> 0)
angles_petite   = [0, 60, 0, -70, 0];
angle_th_petite = interp1(pourcentages_cles, angles_petite, x_petite, 'linear');

% Création du profil d'angle Grande Molette (0 -> +120 -> 0 -> -90 -> 0)
angles_grande   = [0, 120, 0, -90, 0];
angle_th_grande = interp1(pourcentages_cles, angles_grande, x_grande, 'linear');

% Tracé des angles (en pointillés avec la même couleur que leur courbe associée)
plot(x_petite, angle_th_petite, 'b--', 'LineWidth', 1.2, 'DisplayName', 'Angle th. Petite');
plot(x_grande, angle_th_grande, 'r--', 'LineWidth', 1.2, 'DisplayName', 'Angle th. Grande');

ylabel('Angle de la molette (°)', 'Color', [0.4 0.4 0.4], 'FontWeight', 'bold');
ylim([-100, 130]); % On élargit l'axe pour accueillir de -90 à +120
yticks(-90:30:120); % Graduations tous les 30 degrés pour plus de lisibilité

% --- LIGNES INDICATIVES ET DÉCORATION ---
% Changement des labels car l'angle max n'est plus le même pour les deux
xline(25, 'k:', 'Aller Droite (Max)', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
xline(50, 'k:', 'Retour 0°', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
xline(75, 'k:', 'Aller Gauche (Max)', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');

xlabel('Progression du mouvement (%)', 'FontWeight', 'bold');
title('Comparaison d''amplitude : Petite vs Grande Molette');
legend('Location', 'northwest', 'FontSize', 10);
set(gca, 'FontSize', 10);

%% ===============================================================
%  FONCTION DE LECTURE 
%  ===============================================================
function positions = load_qtm_data(file_path)
    fid = fopen(file_path,'r');
    if fid == -1, error('Fichier introuvable : %s', file_path); end
    positions = [];
    pat = 'x=([-+]?[\d.]+)[,\s)]+y=([-+]?[\d.]+)[,\s)]+z=([-+]?[\d.]+)';
    while ~feof(fid)
        ligne = fgetl(fid);
        if ischar(ligne) && contains(ligne,'RT6DBodyPosition')
            tok = regexp(ligne, pat,'tokens');
            if ~isempty(tok)
                vals = cellfun(@str2double, tok{1});
                positions(end+1,:) = vals; %#ok<AGROW>
            end
        end
    end
    fclose(fid);
    if isempty(positions)
        error('Aucune donnée trouvée dans %s', file_path);
    end
end
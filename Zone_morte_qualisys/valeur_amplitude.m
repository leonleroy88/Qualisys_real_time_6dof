clear; clc; close all;

%% 1. PARAMÈTRES
fichier_petite = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_petite_molette_v2.txt';
fichier_grande = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_grande_molette_v2.txt';

%% 2. CHARGEMENT DES POSITIONS
pos_petite = load_qtm_data(fichier_petite);
pos_grande = load_qtm_data(fichier_grande);

%% 3. CALCUL DU DÉBATTEMENT (Distance depuis l'origine)
% On considère que la première frame de l'enregistrement est le point 0° (neutre)
neutre_petite = pos_petite(1, :);
neutre_grande = pos_grande(1, :);

% Distance euclidienne directe de chaque point par rapport au point neutre
dist_petite = sqrt(sum((pos_petite - neutre_petite).^2, 2));
dist_grande = sqrt(sum((pos_grande - neutre_grande).^2, 2));

%% 4. CRÉATION D'UN AXE TEMPOREL EN %
x_petite = linspace(0, 100, length(dist_petite));
x_grande = linspace(0, 100, length(dist_grande));

%% 5. EXTRACTION DES DÉBATTEMENTS MAXIMAUX
% Le débattement max correspond au point le plus éloigné du centre
debat_max_petite = max(dist_petite);
debat_max_grande = max(dist_grande);

fprintf('=== DÉBATTEMENT MAXIMAL DU TIP (Depuis 0°) ===\n');
fprintf('Petite molette : %.1f mm\n', debat_max_petite);
fprintf('Grande molette : %.1f mm\n', debat_max_grande);

%% 6. AFFICHAGE DU GRAPHIQUE
figure('Name', 'Débattement du TIP en mm', 'Color', 'w', 'Position', [100, 100, 900, 500]);
hold on; grid on;

% Tracés
plot(x_petite, dist_petite, 'b-', 'LineWidth', 2.5, 'DisplayName', sprintf('Petite Molette (Max: %.1f mm)', debat_max_petite));
plot(x_grande, dist_grande, 'r-', 'LineWidth', 2.5, 'DisplayName', sprintf('Grande Molette (Max: %.1f mm)', debat_max_grande));

% Décoration
xlabel('Progression du cycle (%)', 'FontWeight', 'bold');
ylabel('Éloignement du TIP par rapport à 0° (mm)', 'FontWeight', 'bold');
title('Débattement du TIP : Éloignement réel depuis le centre');
legend('Location', 'north', 'FontSize', 11);

% Lignes indicatives pour guider la lecture
% xline(25, 'k:', 'Aller (1er côté)', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
% xline(50, 'k:', 'Retour au centre', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
% xline(75, 'k:', 'Aller (2ème côté)', 'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');

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
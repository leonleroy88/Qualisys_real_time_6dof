%% ================================================================
%  DIAGNOSTIC — Visualisation de la détection des pics
%  Aide à diagnostiquer pourquoi findpeaks échoue
%% ================================================================
clear; clc; close all;

%% Paramètres
fichier_grande = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_LEONqtm_20260520_144603.txt';
GRANDE_DROIT  = 130;
GRANDE_GAUCHE =  85;
POURCENTAGE_COUPE = 55;

%% Chargement
fprintf('Chargement et traitement...\n');
positions = load_qtm_data(fichier_grande);
n_full = size(positions, 1);

% Coupe au premier cycle
idx_cut = round(n_full * POURCENTAGE_COUPE / 100);
pos = positions(1:idx_cut, :);
n = size(pos, 1);

% PCA
centree = pos - mean(pos, 1);
[~,~,V] = svd(centree, 'econ');
proj = centree * V(:,1);
proj_smooth = movmean(proj, 15);

% Convention
if mean(proj_smooth(1:max(1,round(n*0.10)))) > mean(proj_smooth(round(n*0.30):round(n*0.40)))
    proj_smooth = -proj_smooth;
end

%% Figure diagnostic
fig = figure('Position', [50 50 1400 900]);

%% ---- Panel 1 : Signal brut vs lissé ----
ax1 = subplot(3, 2, 1);
hold(ax1, 'on');
plot(ax1, proj, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'DisplayName', 'Signal brut');
plot(ax1, proj_smooth, 'Color', [0.85 0.25 0.15], 'LineWidth', 2, 'DisplayName', 'Signal lissé');
grid(ax1, 'on');
xlabel(ax1, 'Frame');
ylabel(ax1, 'Projection PCA');
title(ax1, 'Signal : brut vs lissé');
legend(ax1);

%% ---- Panel 2 : Amplitude et seuils ----
ax2 = subplot(3, 2, 2);
hold(ax2, 'on');
amplitude = range(proj_smooth);
plot(ax2, proj_smooth, 'Color', [0.85 0.25 0.15], 'LineWidth', 2);

% Affiche les seuils essayés
seuils_pct = [15, 10, 5];
colors_seuil = {'r', 'orange', 'g'};
for i = 1:length(seuils_pct)
    seuil_val = (seuils_pct(i)/100) * amplitude;
    yline(ax2, max(proj_smooth) - seuil_val, '--', 'Color', colors_seuil{i}, ...
        'LineWidth', 1.5, 'DisplayName', sprintf('Seuil %d%%', seuils_pct(i)));
end

grid(ax2, 'on');
xlabel(ax2, 'Frame');
ylabel(ax2, 'Projection');
title(ax2, sprintf('Seuils de détection (amplitude = %.2f)', amplitude));
legend(ax2);

%% ---- Panel 3 : Détection des pics avec chaque seuil ----
for seuil_idx = 1:3
    ax = subplot(3, 2, 2 + seuil_idx);
    hold(ax, 'on');
    
    seuil_pct = seuils_pct(seuil_idx);
    seuil = (seuil_pct/100) * amplitude;
    min_dist = max(5, round(n/10));
    
    [pks_max, locs_max] = findpeaks(proj_smooth, ...
        'MinPeakProminence', seuil, 'MinPeakDistance', min_dist, 'SortStr', 'descend');
    [pks_min, locs_min] = findpeaks(-proj_smooth, ...
        'MinPeakProminence', seuil, 'MinPeakDistance', min_dist, 'SortStr', 'descend');
    
    % Graphe
    plot(ax, proj_smooth, 'Color', [0.85 0.25 0.15], 'LineWidth', 1.5, 'DisplayName', 'Signal');
    
    % Pics trouvés
    if ~isempty(locs_max)
        scatter(ax, locs_max, proj_smooth(locs_max), 100, 'g', '^', 'filled', ...
            'DisplayName', sprintf('Pics max (%d)', length(locs_max)));
    else
        text(ax, n/2, max(proj_smooth)*0.9, '❌ Aucun pic max', ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    if ~isempty(locs_min)
        scatter(ax, locs_min, proj_smooth(locs_min), 100, 'b', 'v', 'filled', ...
            'DisplayName', sprintf('Pics min (%d)', length(locs_min)));
    else
        text(ax, n/2, min(proj_smooth)*0.9, '❌ Aucun pic min', ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    grid(ax, 'on');
    xlabel(ax, 'Frame');
    ylabel(ax, 'Projection');
    title(ax, sprintf('Seuil = %d%% × amplitude (MinPeakProminence = %.2f)', seuil_pct, seuil));
    legend(ax, 'Location', 'best');
end

sgtitle('DIAGNOSTIC — Détection des pics pour la grande molette', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ---- Stats numériques ----
fprintf('\n════════════════════════════════════════════════════════════\n');
fprintf('DIAGNOSTIC — Grande molette\n');
fprintf('════════════════════════════════════════════════════════════\n\n');

fprintf('Données chargées :\n');
fprintf('  Frames totales : %d\n', n_full);
fprintf('  Frames après coupe (%.0f%%) : %d\n', POURCENTAGE_COUPE, n);

fprintf('\nSignal après PCA + lissage :\n');
fprintf('  Min : %.2f | Max : %.2f\n', min(proj_smooth), max(proj_smooth));
fprintf('  Amplitude : %.2f\n', amplitude);
fprintf('  Range : %.2f\n', range(proj_smooth));

fprintf('\nSeuils essayés :\n');
for seuil_pct = [15, 10, 5]
    seuil = (seuil_pct/100) * amplitude;
    min_dist = max(5, round(n/10));
    
    [~, locs_max] = findpeaks(proj_smooth, 'MinPeakProminence', seuil, 'MinPeakDistance', min_dist);
    [~, locs_min] = findpeaks(-proj_smooth, 'MinPeakProminence', seuil, 'MinPeakDistance', min_dist);
    
    status_max = '✓';
    status_min = '✓';
    if isempty(locs_max), status_max = '✗'; end
    if isempty(locs_min), status_min = '✗'; end
    
    fprintf('  %d%% : Prominence = %.2f → Max %s (%d found) | Min %s (%d found)\n', ...
        seuil_pct, seuil, status_max, length(locs_max), status_min, length(locs_min));
end

fprintf('\n════════════════════════════════════════════════════════════\n');
fprintf('RECOMMANDATIONS :\n');
fprintf('════════════════════════════════════════════════════════════\n\n');

fprintf('1. Si aucun seuil ne fonctionne :\n');
fprintf('   → Augmentez POURCENTAGE_COUPE (ex: 60, 65, 70)\n');
fprintf('   → Vérifiez que les données contiennent au moins 1 cycle complet\n\n');

fprintf('2. Si le code affiche "Pics détectés" mais pas les bons :\n');
fprintf('   → Ajustez GRANDE_DROIT et GRANDE_GAUCHE\n');
fprintf('   → Vérifiez que les angles correspondent au vrai enregistrement\n\n');

fprintf('3. Passez le seuil qui fonctionne au code hysteresis_CORRIGE.m\n');
fprintf('   (modifier les lignes seuils_a_essayer)\n\n');

%% Fonction de chargement QTM
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

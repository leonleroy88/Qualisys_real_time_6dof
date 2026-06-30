%% ============================================================
%  ANALYSE HYSTÉRÉSIS — MÉTHODE CLASSIQUE (DISTANCE ABSOLUE)
%  Léon - 2026 — VERSION AVANT PCA
%
%  X = Angle de commande de la molette (Reconstruit via séquence)
%  Y = Distance Euclidienne Absolue du TIP (mm)
% ============================================================
clear; clc; close all;

%% ---------------------------------------------------------------
%  PARAMÈTRES ET SÉQUENCES
%  ---------------------------------------------------------------
fichier_petite = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_20260527_154128_petite_vraidecre.txt';
fichier_grande = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_20260527_154353_grande_decrevrai.txt';

% Les séquences exactes de commande de la molette
SEQ_PETITE = [50, -60, 30, -30, 10];
SEQ_GRANDE = [120, -80, 100, -50, 50];

%% ---------------------------------------------------------------
%  CHARGEMENT DES POSITIONS UNIQUEMENT
%  ---------------------------------------------------------------
fprintf('Chargement petite molette...\n');
pos_p = load_qtm_positions(fichier_petite);

fprintf('Chargement grande molette...\n');
pos_g = load_qtm_positions(fichier_grande);

%% ---------------------------------------------------------------
%  MÉTHODE CLASSIQUE : DISTANCE EUCLIDIENNE ABSOLUE
%  ---------------------------------------------------------------
% Formule : D = sqrt( (x - x0)^2 + (y - y0)^2 + (z - z0)^2 )
dist_p_abs = sqrt(sum((pos_p - pos_p(1,:)).^2, 2));
dist_p_abs = movmean(dist_p_abs, 10); % Léger lissage

dist_g_abs = sqrt(sum((pos_g - pos_g(1,:)).^2, 2));
dist_g_abs = movmean(dist_g_abs, 10); % Léger lissage

%% ---------------------------------------------------------------
%  RECONSTRUCTION DE LA COMMANDE MOLETTE (L'AXE X)
%  ---------------------------------------------------------------
fprintf('\nReconstruction Axe X Petite Molette...\n');
[angle_p, frames_pics_p, frames_zeros_p] = reconstruire_commande_absolue(dist_p_abs, SEQ_PETITE);

fprintf('Reconstruction Axe X Grande Molette...\n');
[angle_g, frames_pics_g, frames_zeros_g] = reconstruire_commande_absolue(dist_g_abs, SEQ_GRANDE);

%% ---------------------------------------------------------------
%  FIGURE — TRACÉ DES HYSTÉRÉSIS (EN "V")
%  ---------------------------------------------------------------
fig = figure('Name','Hystérésis Méthode Classique : Distance Absolue', ...
    'Color','w', 'Position',[50 50 1400 900]); 

%% ---- LIGNE 1 : Évolution Temporelle ------
for g = 1:2
    ax1 = subplot(2,2,g);
    hold(ax1,'on'); grid(ax1,'on'); set(ax1,'Color','w');
    
    if g == 1
        angle = angle_p; dist = dist_p_abs; couleur = [0.20 0.53 0.96]; nom = 'Petite molette';
    else
        angle = angle_g; dist = dist_g_abs; couleur = [0.85 0.25 0.15]; nom = 'Grande molette';
    end
    t = 1:length(angle);
    
    yyaxis left
    plot(ax1, t, angle, 'Color', couleur, 'LineWidth', 2);
    ylabel(ax1, 'Commande Molette (°)', 'FontSize', 10, 'Color', couleur);
    set(ax1, 'YColor', couleur);
    
    yyaxis right
    plot(ax1, t, dist, '--', 'Color', [0.2 0.8 0.2], 'LineWidth', 1.5);
    ylabel(ax1, 'Distance Absolue TIP (mm)', 'FontSize', 10, 'Color', [0.2 0.8 0.2]);
    set(ax1, 'YColor', [0.2 0.8 0.2]);
    
    xlabel(ax1, 'Frame', 'FontSize', 10);
    title(ax1, [nom ' — Évolution Temporelle'], 'FontSize', 11, 'FontWeight', 'bold');
end

%% ---- LIGNE 2 : Hystérésis Multicycles (Gradient) ------
for g = 1:2
    ax = subplot(2,2,g+2);
    hold(ax,'on'); grid(ax,'on'); set(ax,'Color','w');
    
    if g == 1
        angle = angle_p; dist = dist_p_abs; nom = 'Petite molette';
        frames_z = frames_zeros_p;
        color_start = [0.60 0.85 1.00]; color_end = [0.00 0.15 0.60];
    else
        angle = angle_g; dist = dist_g_abs; nom = 'Grande molette';
        frames_z = frames_zeros_g;
        color_start = [1.00 0.80 0.20]; color_end = [0.60 0.00 0.00];
    end
    
    num_cycles = length(frames_z) - 1;
    
    r_grad = linspace(color_start(1), color_end(1), num_cycles);
    g_grad = linspace(color_start(2), color_end(2), num_cycles);
    b_grad = linspace(color_start(3), color_end(3), num_cycles);
    
    for c = 1:num_cycles
        idx_seg = frames_z(c):frames_z(c+1);
        col = [r_grad(c), g_grad(c), b_grad(c)];
        nom_cycle = sprintf('Cycle %d', c);
        
        plot(ax, angle(idx_seg), dist(idx_seg), '-', 'Color', col, 'LineWidth', 2, 'DisplayName', nom_cycle);
    end
    
    plot(ax, angle(1), dist(1), 'o', 'Color', 'k', 'MarkerFaceColor', [0.1 0.8 0.2], 'MarkerSize', 10, 'DisplayName', 'Début', 'LineWidth', 1.5);
    plot(ax, angle(end), dist(end), 's', 'Color', 'k', 'MarkerFaceColor', [0.9 0.2 0.2], 'MarkerSize', 10, 'DisplayName', 'Fin', 'LineWidth', 1.5);
    
    xline(ax, 0, 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off'); 
    yline(ax, 0, 'k:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    
    legend(ax, 'FontSize', 9, 'Location', 'north', 'Box', 'on');
    xlabel(ax, 'Commande Molette (°)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel(ax, 'Distance Absolue TIP (mm)', 'FontSize', 11, 'FontWeight', 'bold');
    title(ax, [nom ' — Hystérésis (Repliement en V)'], 'FontSize', 12, 'FontWeight', 'bold');
end

sgtitle('Méthode Classique : Commande Moteur vs Distance Absolue (Norme Euclidienne)', 'FontSize', 14, 'FontWeight', 'bold');

%% ===============================================================
%  FONCTIONS UTILITAIRES
%  ===============================================================

function positions = load_qtm_positions(file_path)
    % Ne charge QUE les positions (ignore la matrice de rotation)
    fid = fopen(file_path, 'r');
    if fid == -1, error('Fichier introuvable : %s', file_path); end
    
    positions = [];
    pat_pos = 'x=([-+]?[\d.]+)[,\s]+y=([-+]?[\d.]+)[,\s]+z=([-+]?[\d.]+)';
    
    while ~feof(fid)
        ligne = fgetl(fid);
        if ischar(ligne)
            tok_pos = regexp(ligne, pat_pos, 'tokens');
            if ~isempty(tok_pos)
                xyz = cellfun(@str2double, tok_pos{1});
                positions(end+1, :) = xyz;
            end
        end
    end
    fclose(fid);
    if isempty(positions), error('ERREUR : Aucune donnée trouvée. %s', file_path); end
end

function [angle_cmd, frames_pics, frames_zeros] = reconstruire_commande_absolue(dist_abs, sequence)
    % Analyse des pics pour un signal strictement positif (Distance absolue)
    n = length(dist_abs);
    
    % 1. Trouver TOUS les pics (ils sont tous vers le haut car distance absolue)
    amp_min = range(dist_abs) * 0.15; 
    [~, frames_pics] = findpeaks(dist_abs, 'MinPeakProminence', amp_min, 'MinPeakDistance', 20);
    
    % Sécurité : ne garder que le nombre de pics correspondant à la séquence
    if length(frames_pics) > length(sequence)
        frames_pics = frames_pics(1:length(sequence));
    elseif length(frames_pics) < length(sequence)
        warning('Moins de pics détectés que dans la séquence !');
        sequence = sequence(1:length(frames_pics));
    end
    
    % 2. Trouver les passages par zéro (les creux entre les pics)
    frames_zeros = 1; % Commence à la frame 1
    for i = 1:length(frames_pics)-1
        range_search = frames_pics(i):frames_pics(i+1);
        [~, min_idx] = min(dist_abs(range_search));
        frames_zeros(end+1) = range_search(min_idx);
    end
    
    % Retour à ~0 à la fin
    [~, min_idx_fin] = min(dist_abs(frames_pics(end):end));
    frames_zeros(end+1) = frames_pics(end) + min_idx_fin - 1;
    if frames_zeros(end) < n - 10
        frames_zeros(end+1) = n;
    end
    
    % 3. Construction de l'axe X par interpolation
    X_ref = []; Y_ref = [];
    
    % Assigner 0° aux frames de retour au neutre (les creux)
    for i = 1:length(frames_zeros)
        X_ref(end+1) = frames_zeros(i); Y_ref(end+1) = 0;
    end
    
    % Assigner les angles de la séquence aux frames de pics
    for i = 1:length(frames_pics)
        X_ref(end+1) = frames_pics(i); Y_ref(end+1) = sequence(i);
    end
    
    % Trier pour l'interpolation
    [X_ref, idx_unique] = unique(X_ref);
    Y_ref = Y_ref(idx_unique);
    
    % Interpolation linéaire de toute la commande
    angle_cmd = interp1(X_ref, Y_ref, 1:n, 'linear', 'extrap')';
end
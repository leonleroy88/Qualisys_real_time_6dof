%% ============================================================
%  ANALYSE HYSTÉRÉSIS — RECONSTRUCTION PAR FLUX DE SIGNAL
%  Léon - 2026 — FIXED VERSION
%
%  Les angles sont reconstruits en suivant le flux réel du signal,
%  pas par interpolation linéaire naïve.
% ============================================================
clear; clc; close all;

%% ---------------------------------------------------------------
%  PARAMÈTRES ET SÉQUENCES
%  ---------------------------------------------------------------
% IMPORTANT : Adapter ces chemins à votre système
fichier_petite = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_20260527_154128_petite_vraidecre.txt';
fichier_grande = 'C:\Users\LEROY\Documents\Python_qualisys\Zone_morte_qualisys\poses_qtm_20260527_154353_grande_decrevrai.txt';

% Les séquences exactes
SEQ_PETITE = [50, -60, 30, -30, 10];
SEQ_GRANDE = [120, -80, 100, -50, 50];

%% ---------------------------------------------------------------
%  CHARGEMENT
%  ---------------------------------------------------------------
fprintf('Chargement petite molette...\n');
pos_p_full = load_qtm_data(fichier_petite);

fprintf('Chargement grande molette...\n');
pos_g_full = load_qtm_data(fichier_grande);

%% ---------------------------------------------------------------
%  RECONSTRUCTION DE L'AXE ANGLE (FLUX DE SIGNAL)
%  ---------------------------------------------------------------
fprintf('\nReconstruction séquence Petite Molette...\n');
[theta_p, stats_p] = reconstruire_sequence_flux(pos_p_full, SEQ_PETITE);

fprintf('Reconstruction séquence Grande Molette...\n');
[theta_g, stats_g] = reconstruire_sequence_flux(pos_g_full, SEQ_GRANDE);

% Calcul des distances (axe Y) sur tout le fichier
dist_p_full = sqrt(sum((pos_p_full - pos_p_full(1,:)).^2, 2));
dist_g_full = sqrt(sum((pos_g_full - pos_g_full(1,:)).^2, 2));

%% ---------------------------------------------------------------
%  FIGURE — 6 graphiques
%  ---------------------------------------------------------------
fig = figure('Name','Analyse Hystérésis Molettes - FLUX DE SIGNAL', ...
    'Color','w', 'Position',[50 50 1400 950]); 

%% ---- LIGNE 1 (G1 & G2) : Déplacement vs temps (vue globale) -------------
for g = 1:2
    ax = subplot(3,2,g);
    hold(ax,'on'); grid(ax,'on'); set(ax,'Color','w');
    
    if g == 1
        d_full  = dist_p_full;
        couleur = [0.20 0.53 0.96];
        nom     = 'Petite molette';
        stats   = stats_p;
    else
        d_full  = dist_g_full;
        couleur = [0.85 0.25 0.15];
        nom     = 'Grande molette';
        stats   = stats_g;
    end
    n_full = length(d_full);
    pct    = linspace(0,100,n_full);
    
    plot(ax, pct, d_full, '-', 'Color',couleur, 'LineWidth',1.8);
    
    % Marquer les points clés détectés
    for i = 1:length(stats.indices_pics)
        idx = stats.indices_pics(i);
        pct_val = pct(idx);
        xline(ax, pct_val, 'Color',[0.5 0.5 0.5], 'LineStyle','--', 'LineWidth',1, ...
            'Alpha',0.6);
    end
    
    xlabel(ax,'Progression enregistrement (%)','FontSize',10);
    ylabel(ax,'Distance depuis neutre (mm)','FontSize',10);
    title(ax,[nom ' — vue globale (distance brute)'],'FontSize',11,'FontWeight','bold');
    set(ax,'FontSize',10);
end

%% ---- LIGNE 2 (G3 & G4) : Hystérésis 1er Cycle Détaillé ------
for g = 1:2
    ax = subplot(3,2,g+2);
    hold(ax,'on'); grid(ax,'on'); set(ax,'Color','w');
    
    if g == 1
        theta       = theta_p;
        dist        = dist_p_full;
        stats       = stats_p;
        couleur     = [0.20 0.53 0.96];
        nom         = 'Petite molette';
        color_aller = [0.00 0.40 1.00];   
        color_ret   = [0.60 0.85 1.00]; 
        lim_x       = [-70, 60];
    else
        theta       = theta_g;
        dist        = dist_g_full;
        stats       = stats_g;
        couleur     = [0.85 0.25 0.15];
        nom         = 'Grande molette';
        color_aller = [1.00 0.15 0.15];   
        color_ret   = [1.00 0.70 0.70]; 
        lim_x       = [-90, 130];
    end
    
    % Segmenter le premier cycle complet (du départ au retour à 0 final)
    idx_cycle_end = min(stats.indices_zeros(end), length(theta));
    
    % Points clés
    pic_indices = stats.indices_pics;
    zero_indices = stats.indices_zeros;
    
    % Tracer chaque segment du cycle avec sa couleur
    seg_start = 1;
    for i = 1:min(length(pic_indices), 2)  % Jusqu'au 2e pic max
        pic_idx = pic_indices(i);
        
        % Aller vers le pic
        idx_aller = seg_start:pic_idx;
        if theta(seg_start) * theta(pic_idx) >= 0 || i == 1
            lw = 3.2;
            color = color_aller;
            style = '-';
        else
            lw = 3.2;
            color = color_aller;
            style = '-';
        end
        plot(ax, theta(idx_aller), dist(idx_aller), style, ...
            'Color', color, 'LineWidth', lw);
        
        % Retour vers le zéro suivant
        next_zero = zero_indices(i+1);
        if next_zero > pic_idx && next_zero <= length(theta)
            idx_ret = pic_idx:next_zero;
            plot(ax, theta(idx_ret), dist(idx_ret), '--', ...
                'Color', color_ret, 'LineWidth', 2.2);
            seg_start = next_zero;
        end
    end
    
    % Marqueurs clés
    plot(ax, theta(1), dist(1), 'o','Color','k','MarkerFaceColor',[0.1 0.8 0.2],...
        'MarkerSize',11,'DisplayName','Départ (0°)', 'LineWidth', 1.5);
    
    for i = 1:length(pic_indices)
        if pic_indices(i) <= length(theta)
            plot(ax, theta(pic_indices(i)), dist(pic_indices(i)), '^','Color','k',...
                'MarkerFaceColor',color_aller,'MarkerSize',10, 'LineWidth', 1.5);
        end
    end
    
    for i = 2:min(3, length(zero_indices))
        if zero_indices(i) <= length(theta)
            plot(ax, theta(zero_indices(i)), dist(zero_indices(i)), 's','Color','k',...
                'MarkerFaceColor',[0.9 0.8 0.0],'MarkerSize',10, 'LineWidth', 1.5);
        end
    end
    
    xline(ax, 0,'k-','LineWidth',1.2);
    yline(ax, 0,'k:','LineWidth',1.0);
    xlabel(ax,'Angle molette (°)','FontSize',10);
    ylabel(ax,'Distance (mm)','FontSize',10);
    title(ax,[nom ' — 1er Cycle (Amplitudes Max)'],'FontSize',11,'FontWeight','bold');
    xlim(ax, lim_x);
    set(ax,'FontSize',10);
end

%% ---- LIGNE 3 (G5 & G6) : Hystérésis DATASET COMPLET ------
for g = 1:2
    ax = subplot(3,2,g+4);
    hold(ax,'on'); grid(ax,'on'); set(ax,'Color','w');
    
    if g == 1
        nom   = 'Petite molette';
        theta = theta_p;
        dist  = dist_p_full;
        couleur = [0.20 0.53 0.96]; 
        lim_x = [-70, 60];
    else
        nom   = 'Grande molette';
        theta = theta_g;
        dist  = dist_g_full;
        couleur = [0.85 0.25 0.15]; 
        lim_x = [-90, 130];
    end
    
    % Tracé continu
    plot(ax, theta, dist, '-', 'Color', [couleur 0.7], 'LineWidth', 1.5, ...
        'DisplayName', 'Séquence complète');
    
    % Marqueurs Départ/Fin
    plot(ax, theta(1), dist(1), 'o','Color','k','MarkerFaceColor',[0.1 0.8 0.2],...
        'MarkerSize',9,'DisplayName','Début', 'LineWidth', 1.2);
    plot(ax, theta(end), dist(end), 'o','Color','k','MarkerFaceColor',[0.9 0.2 0.2],...
        'MarkerSize',9,'DisplayName','Fin (RAZ)', 'LineWidth', 1.2);
    
    xline(ax, 0,'k-','LineWidth',1.2);
    yline(ax, 0,'k:','LineWidth',1.0);
    
    legend(ax,'FontSize',9.5,'Location','northeast');
    xlabel(ax,'Angle molette (°)','FontSize',10);
    ylabel(ax,'Distance (mm)','FontSize',10);
    title(ax,[nom ' — Séquence Complète'],'FontSize',11,'FontWeight','bold');
    xlim(ax, lim_x);
    set(ax,'FontSize',10);
end

sgtitle('Analyse d''Hystérésis — Reconstruction par Flux de Signal', ...
    'FontSize',14,'FontWeight','bold');

%% ===============================================================
%  FONCTIONS UTILITAIRES
%  ===============================================================

function [theta_all, stats] = reconstruire_sequence_flux(positions, sequence)
    % Reconstruction par FLUX DE SIGNAL
    % On suit le chemin réel du mouvement, pas une interpolation naïve
    
    n = size(positions,1);
    
    %% 1. Extraire le signal principal via PCA
    centree = positions - mean(positions,1);
    [~,~,V] = svd(centree,'econ');
    signal_brut = centree * V(:,1);
    
    % Lissage
    signal = movmean(signal_brut, 20);
    
    %% 2. Assurer l'orientation correcte
    % Le premier pic doit avoir le même signe que sequence(1)
    if sign(signal(find(abs(signal) == max(abs(signal(1:round(n/2)))))) ) ~= sign(sequence(1))
        signal = -signal;
    end
    
    %% 3. Détecter les pics avec une stratégie robuste
    % On cherche les pics dans le signal en suivant la direction attendue
    pics_pos = [];
    pics_neg = [];
    
    [~, locs_pos] = findpeaks(signal, 'MinPeakDistance', 30);
    [~, locs_neg] = findpeaks(-signal, 'MinPeakDistance', 30);
    
    % Garder les N pics les plus importants (par amplitude)
    if ~isempty(locs_pos)
        [~, idx_sort] = sort(signal(locs_pos), 'descend');
        pics_pos = locs_pos(idx_sort(1:min(sum(sequence>0), length(locs_pos))));
        pics_pos = sort(pics_pos);
    end
    
    if ~isempty(locs_neg)
        [~, idx_sort] = sort(-signal(locs_neg), 'descend');
        pics_neg = locs_neg(idx_sort(1:min(sum(sequence<0), length(locs_neg))));
        pics_neg = sort(pics_neg);
    end
    
    % Fusionner et trier chronologiquement
    indices_pics = sort([pics_pos; pics_neg]);
    
    %% 4. Détecter les passages par zéro (croisements du signal)
    indices_zeros = [1]; % Point de départ
    
    for i = 1:length(indices_pics)
        start_idx = indices_pics(i);
        if i < length(indices_pics)
            end_idx = indices_pics(i+1);
        else
            end_idx = n;
        end
        
        % Chercher le croisement zéro après ce pic
        segment = signal(start_idx:end_idx);
        
        % Trouver l'indice où le signal change de signe OU passe près de zéro
        if i < length(indices_pics)
            % Entre deux pics, il y a forcément un zéro
            zero_idx = start_idx + find_zero_crossing(segment);
        else
            % Après le dernier pic, retour à zéro
            zero_idx = start_idx + find_zero_crossing(segment);
        end
        
        if zero_idx > start_idx && zero_idx <= n
            indices_zeros = [indices_zeros; zero_idx];
        end
    end
    
    % Assurer l'ordre et l'unicité
    indices_zeros = unique(sort(indices_zeros));
    if indices_zeros(end) < n
        indices_zeros = [indices_zeros; n];
    end
    
    %% 5. Construire le vecteur angle par FLUX
    % On va interpoler en suivant la séquence réelle
    theta_all = zeros(n, 1);
    
    % Frame 1 est toujours à angle 0
    theta_all(1) = 0;
    
    % Pour chaque transition (pic vers zéro)
    for i = 1:length(indices_pics)
        pic_idx = indices_pics(i);
        
        % Angle cible de ce pic
        target_angle = sequence(i);
        
        % Zéro avant le pic
        if i == 1
            zero_before = 1;
        else
            zero_before = indices_zeros(i);
        end
        
        % Zéro après le pic
        zero_after = indices_zeros(i+1);
        
        % Segment aller (de zéro à pic)
        idx_aller = zero_before:pic_idx;
        angle_aller = linspace(0, target_angle, length(idx_aller));
        theta_all(idx_aller) = angle_aller';
        
        % Segment retour (de pic à zéro)
        idx_ret = pic_idx:zero_after;
        angle_ret = linspace(target_angle, 0, length(idx_ret));
        theta_all(idx_ret) = angle_ret';
    end
    
    % Smooth final pour éviter les discontinuités
    theta_all = movmean(theta_all, 5);
    
    %% Statistiques
    stats.indices_pics = indices_pics;
    stats.indices_zeros = indices_zeros;
    stats.sequence = sequence;
    
end

function zero_idx = find_zero_crossing(signal)
    % Trouve l'indice du croisement zéro dans un signal
    % Si pas de croisement exact, retourne le point le plus proche de zéro
    
    idx_sign_change = find(diff(sign(signal)) ~= 0);
    
    if ~isempty(idx_sign_change)
        zero_idx = idx_sign_change(1) + 1;
    else
        % Pas de croisement, chercher le minimum
        [~, zero_idx] = min(abs(signal));
    end
    
    if zero_idx < 1
        zero_idx = 1;
    end
end

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
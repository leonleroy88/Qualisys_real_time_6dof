%% figure_extremes.m
% Figure synthétique : trajectoires petite + grande molette
% avec position initiale et positions extrêmes (D et G)

clear; clc; close all;

%% ── Chemin ───────────────────────────────────────────────────────────────────
dossier = 'C:\Users\LEROY\Documents\Python_qualisys\Parse';
%% ── Chargement trajectoires ──────────────────────────────────────────────────
pm1 = load(fullfile(dossier, 'poses_qtm_petite_molette.mat'));
pm2 = load(fullfile(dossier, 'poses_qtm_petite_molette_v2.mat'));
gm1 = load(fullfile(dossier, 'poses_qtm_grande_molette.mat'));
gm2 = load(fullfile(dossier, 'poses_qtm_grande_molette_v2.mat'));  % adapter si v2 existe

%% ── Chargement positions extrêmes ────────────────────────────────────────────
pe_D = load(fullfile(dossier, 'poses_qtm_peite_extreD.mat'));
pe_G = load(fullfile(dossier, 'poses_qtm_petite_extreG.mat'));
ge_D = load(fullfile(dossier, 'poses_qtm_grande_extreD.mat'));
ge_G = load(fullfile(dossier, 'poses_qtm_grande_extreG.mat'));

% Position initiale = première frame de chaque trajectoire principale
pos_init_petite = [pm2.x(1), pm2.y(1), pm2.z(1)];
pos_init_grande = [gm1.x(1), gm1.y(1), gm1.z(1)];


% Position extrême = moyenne des 500 dernières frames (position stable atteinte)
n = 100;
pos_peD = [mean(pe_D.x(end-n+1:end)), mean(pe_D.y(end-n+1:end)), mean(pe_D.z(end-n+1:end))];
pos_peG = [mean(pe_G.x(end-n+1:end)), mean(pe_G.y(end-n+1:end)), mean(pe_G.z(end-n+1:end))];
pos_geD = [mean(ge_D.x(end-n+1:end)), mean(ge_D.y(end-n+1:end)), mean(ge_D.z(end-n+1:end))];
pos_geG = [mean(ge_G.x(end-n+1:end)), mean(ge_G.y(end-n+1:end)), mean(ge_G.z(end-n+1:end))];


fprintf('Positions calculées (moyennes des frames):\n');
fprintf('  Petite init  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_init_petite);
fprintf('  Petite extD  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_peD);
fprintf('  Petite extG  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_peG);
fprintf('  Grande init  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_init_grande);
fprintf('  Grande extD  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_geD);
fprintf('  Grande extG  : X=%.2f  Y=%.2f  Z=%.2f\n', pos_geG);

%% ── FIGURE : Vue 3D ──────────────────────────────────────────────────────────
figure('Name','Trajectoires + positions extrêmes','Color','w','Position',[100 100 1000 750]);
hold on; grid on; axis equal;
view(45, 25);
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
title('Sonde TEE — Trajectoires et positions extrêmes des molettes');

% ── Trajectoires v2 en fond (tracées séparément pour éviter pb dimensions) ────
plot3(pm2.x, pm2.y, pm2.z, '-', 'Color', [0.4 0.6 1 0.4], 'LineWidth', 1, 'HandleVisibility','off');
plot3(gm2.x, gm2.y, gm2.z, '-', 'Color', [1 0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility','off');

% Trajectoires avec légende
plot3(pm1.x, pm1.y, pm1.z, '-', 'Color', [0.2 0.4 0.9], 'LineWidth', 2, ...
      'DisplayName', 'Trajectoire petite molette');
plot3(gm1.x, gm1.y, gm1.z, '-', 'Color', [0.9 0.2 0.2], 'LineWidth', 2, ...
      'DisplayName', 'Trajectoire grande molette');

% ── Position initiale ─────────────────────────────────────────────────────────
plot3(pos_init_petite(1), pos_init_petite(2), pos_init_petite(3), ...
      'diamond', 'MarkerSize', 14, 'MarkerEdgeColor', [0.1 0.3 0.8], ...
      'MarkerFaceColor', 'white', 'LineWidth', 2, ...
      'DisplayName', 'Position initiale (petite)');

plot3(pos_init_grande(1), pos_init_grande(2), pos_init_grande(3), ...
      'diamond', 'MarkerSize', 14, 'MarkerEdgeColor', [0.8 0.1 0.1], ...
      'MarkerFaceColor', 'white', 'LineWidth', 2, ...
      'DisplayName', 'Position initiale (grande)');

% ── Extrêmes petite molette ───────────────────────────────────────────────────
plot3(pos_peD(1), pos_peD(2), pos_peD(3), ...
      '>', 'MarkerSize', 12, 'MarkerEdgeColor', [0.1 0.3 0.8], ...
      'MarkerFaceColor', [0.2 0.4 0.9], 'LineWidth', 2, ...
      'DisplayName', 'Petite molette — extrême D');

plot3(pos_peG(1), pos_peG(2), pos_peG(3), ...
      '<', 'MarkerSize', 12, 'MarkerEdgeColor', [0.1 0.3 0.8], ...
      'MarkerFaceColor', [0.2 0.4 0.9], 'LineWidth', 2, ...
      'DisplayName', 'Petite molette — extrême G');

% ── Extrêmes grande molette ───────────────────────────────────────────────────
plot3(pos_geD(1), pos_geD(2), pos_geD(3), ...
      '>', 'MarkerSize', 12, 'MarkerEdgeColor', [0.8 0.1 0.1], ...
      'MarkerFaceColor', [0.9 0.2 0.2], 'LineWidth', 2, ...
      'DisplayName', 'Grande molette — extrême D');

plot3(pos_geG(1), pos_geG(2), pos_geG(3), ...
      '<', 'MarkerSize', 12, 'MarkerEdgeColor', [0.8 0.1 0.1], ...
      'MarkerFaceColor', [0.9 0.2 0.2], 'LineWidth', 2, ...
      'DisplayName', 'Grande molette — extrême G');

% ── Lignes reliant init → extD → extG (arc de débattement) ───────────────────
plot3([pos_init_petite(1), pos_peD(1), pos_peG(1)], ...
      [pos_init_petite(2), pos_peD(2), pos_peG(2)], ...
      [pos_init_petite(3), pos_peD(3), pos_peG(3)], ...
      '--', 'Color', [0.2 0.4 0.9], 'LineWidth', 1.2, 'HandleVisibility','off');

plot3([pos_init_grande(1), pos_geD(1), pos_geG(1)], ...
      [pos_init_grande(2), pos_geD(2), pos_geG(2)], ...
      [pos_init_grande(3), pos_geD(3), pos_geG(3)], ...
      '--', 'Color', [0.9 0.2 0.2], 'LineWidth', 1.2, 'HandleVisibility','off');

legend('Location','bestoutside','FontSize',10);
hold off;

% %% ── FIGURE : Vue 2D (plan XZ — vue de côté, souvent la plus parlante) ────────
% figure('Name','Vue 2D (plan XZ)','Color','w','Position',[200 200 900 600]);
% hold on; grid on;
% xlabel('X (mm)'); ylabel('Z (mm)');
% title('Vue de côté (plan XZ) — Trajectoires et extrêmes');
% 
% plot(pm1.x, pm1.z, '-', 'Color', [0.2 0.4 0.9], 'LineWidth', 2, 'DisplayName','Petite molette');
% plot(gm1.x, gm1.z, '-', 'Color', [0.9 0.2 0.2], 'LineWidth', 2, 'DisplayName','Grande molette');
% 
% plot(pos_init_petite(1), pos_init_petite(3), 'diamond', 'MarkerSize',14, ...
%      'MarkerEdgeColor',[0.1 0.3 0.8], 'MarkerFaceColor','white', 'LineWidth',2, ...
%      'DisplayName','Initiale petite');
% plot(pos_init_grande(1), pos_init_grande(3), 'diamond', 'MarkerSize',14, ...
%      'MarkerEdgeColor',[0.8 0.1 0.1], 'MarkerFaceColor','white', 'LineWidth',2, ...
%      'DisplayName','Initiale grande');
% 
% plot(pos_peD(1), pos_peD(3), '>', 'MarkerSize',12, 'MarkerEdgeColor',[0.1 0.3 0.8], ...
%      'MarkerFaceColor',[0.2 0.4 0.9], 'LineWidth',2, 'DisplayName','Petite extD');
% plot(pos_peG(1), pos_peG(3), '<', 'MarkerSize',12, 'MarkerEdgeColor',[0.1 0.3 0.8], ...
%      'MarkerFaceColor',[0.2 0.4 0.9], 'LineWidth',2, 'DisplayName','Petite extG');
% plot(pos_geD(1), pos_geD(3), '>', 'MarkerSize',12, 'MarkerEdgeColor',[0.8 0.1 0.1], ...
%      'MarkerFaceColor',[0.9 0.2 0.2], 'LineWidth',2, 'DisplayName','Grande extD');
% plot(pos_geG(1), pos_geG(3), '<', 'MarkerSize',12, 'MarkerEdgeColor',[0.8 0.1 0.1], ...
%      'MarkerFaceColor',[0.9 0.2 0.2], 'LineWidth',2, 'DisplayName','Grande extG');
% 
% legend('Location','bestoutside','FontSize',10);
% hold off;

%% ── Distance entre extrêmes (mm) ─────────────────────────────────────────────
dist_petite = norm(pos_peD - pos_peG);
dist_grande = norm(pos_geD - pos_geG);

fprintf('\n════════════════════════════════════\n');
fprintf('   DÉBATTEMENT SPATIAL (extrême D → G)\n');
fprintf('════════════════════════════════════\n');
fprintf('  Petite molette : %.2f mm entre extD et extG\n', dist_petite);
fprintf('  Grande molette : %.2f mm entre extD et extG\n', dist_grande);

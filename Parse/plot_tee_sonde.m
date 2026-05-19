%% plot_tee_sonde.m
% Visualisation des trajectoires sonde TEE
% Superpose petite molette (v1+v2) et grande molette (v1+v2)
% Calcule le débattement angulaire pour chaque molette

clear; clc; close all;

%% ── Chemin vers vos fichiers .mat ────────────────────────────────────────────
dossier = 'C:\Users\LEROY\Documents\Python_qualisys\Parse';

%% ── Chargement des 4 fichiers ────────────────────────────────────────────────
pm1 = load(fullfile(dossier, 'poses_qtm_petite_molette.mat'));
pm2 = load(fullfile(dossier, 'poses_qtm_petite_molette_v2.mat'));
gm1 = load(fullfile(dossier, 'poses_qtm_grande_molette.mat'));
gm2 = load(fullfile(dossier, 'poses_qtm_grande_molette_v2.mat'));

fprintf('Fichiers chargés avec succès.\n');
fprintf('  Petite molette v1 : %d frames\n', length(pm1.x));
fprintf('  Petite molette v2 : %d frames\n', length(pm2.x));
fprintf('  Grande molette v1 : %d frames\n', length(gm1.x));
fprintf('  Grande molette v2 : %d frames\n', length(gm2.x));

%% ── Fonction : extraire angles d'Euler depuis matrices R ────────────────────
function angles = get_euler_angles(R)
    % R est (N x 3 x 3)
    % Retourne angles (N x 3) en degrés [Rx, Ry, Rz] convention XYZ
    N = size(R, 1);
    angles = zeros(N, 3);
    for i = 1:N
        Ri = squeeze(R(i,:,:));
        angles(i,1) = atan2d( Ri(3,2), Ri(3,3));
        angles(i,2) = atan2d(-Ri(3,1), sqrt(Ri(3,2)^2 + Ri(3,3)^2));
        angles(i,3) = atan2d( Ri(2,1), Ri(1,1));
    end
end

%% ── Calcul des angles ────────────────────────────────────────────────────────
ang_pm1 = get_euler_angles(pm1.R);
ang_pm2 = get_euler_angles(pm2.R);
ang_gm1 = get_euler_angles(gm1.R);
ang_gm2 = get_euler_angles(gm2.R);

%% ── FIGURE 1 : Trajectoires 3D superposées ───────────────────────────────────
figure('Name','Trajectoires 3D sonde TEE','Color','w','Position',[50 50 1100 500]);

% --- Petite molette ---
subplot(1,2,1);
hold on; grid on; axis equal;
plot3(pm1.x, pm1.y, pm1.z, '-b',  'LineWidth', 2, 'DisplayName', 'Petite molette v1');
plot3(pm2.x, pm2.y, pm2.z, '--c', 'LineWidth', 2, 'DisplayName', 'Petite molette v2');
% Points de départ et fin
plot3(pm1.x(1),   pm1.y(1),   pm1.z(1),   'bo', 'MarkerFaceColor','b', 'MarkerSize',8, 'HandleVisibility','off');
plot3(pm1.x(end), pm1.y(end), pm1.z(end), 'bs', 'MarkerFaceColor','b', 'MarkerSize',8, 'HandleVisibility','off');
plot3(pm2.x(1),   pm2.y(1),   pm2.z(1),   'co', 'MarkerFaceColor','c', 'MarkerSize',8, 'HandleVisibility','off');
plot3(pm2.x(end), pm2.y(end), pm2.z(end), 'cs', 'MarkerFaceColor','c', 'MarkerSize',8, 'HandleVisibility','off');
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
title('Petite molette');
legend('Location','best');
view(45,25);

% --- Grande molette ---
subplot(1,2,2);
hold on; grid on; axis equal;
plot3(gm1.x, gm1.y, gm1.z, '-r',  'LineWidth', 2, 'DisplayName', 'Grande molette v1');
plot3(gm2.x, gm2.y, gm2.z, '--m', 'LineWidth', 2, 'DisplayName', 'Grande molette v2');
plot3(gm1.x(1),   gm1.y(1),   gm1.z(1),   'ro', 'MarkerFaceColor','r', 'MarkerSize',8, 'HandleVisibility','off');
plot3(gm1.x(end), gm1.y(end), gm1.z(end), 'rs', 'MarkerFaceColor','r', 'MarkerSize',8, 'HandleVisibility','off');
plot3(gm2.x(1),   gm2.y(1),   gm2.z(1),   'mo', 'MarkerFaceColor','m', 'MarkerSize',8, 'HandleVisibility','off');
plot3(gm2.x(end), gm2.y(end), gm2.z(end), 'ms', 'MarkerFaceColor','m', 'MarkerSize',8, 'HandleVisibility','off');
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
title('Grande molette');
legend('Location','best');
view(45,25);

sgtitle('Trajectoires 3D bout de sonde TEE  (o = départ, ■ = fin)');

% %% ── FIGURE 2 : Angles en fonction du temps ───────────────────────────────────
% angle_noms = {'Rx (°)', 'Ry (°)', 'Rz (°)'};
% 
% figure('Name','Angles petite molette','Color','w','Position',[50 600 1100 500]);
% tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
% for ax = 1:3
%     nexttile;
%     hold on; grid on;
%     plot(ang_pm1(:,ax), '-b',  'LineWidth',1.5, 'DisplayName','Petite molette v1');
%     plot(ang_pm2(:,ax), '--c', 'LineWidth',1.5, 'DisplayName','Petite molette v2');
%     ylabel(angle_noms{ax});
%     if ax == 1, legend('Location','best'); title('Angles — Petite molette'); end
%     if ax == 3, xlabel('Frame'); end
% end
% hold on
% figure('Name','Angles grande molette','Color','w','Position',[600 600 1100 500]);
% tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
% for ax = 1:3
%     nexttile;
%     hold on; grid on;
%     plot(ang_gm1(:,ax), '-r',  'LineWidth',1.5, 'DisplayName','Grande molette v1');
%     plot(ang_gm2(:,ax), '--m', 'LineWidth',1.5, 'DisplayName','Grande molette v2');
%     ylabel(angle_noms{ax});
%     if ax == 1, legend('Location','best'); title('Angles — Grande molette'); end
%     if ax == 3, xlabel('Frame'); end
% end

%% ── FIGURE 3 : Débattement angulaire ────────────────────────────────────────
% Le débattement = différence entre position min et max de chaque enregistrement
% On prend l'angle qui varie le plus (le plus pertinent physiquement)

function affiche_debattement(ang, label)
    debattement = max(ang) - min(ang);  % (1x3) pour Rx, Ry, Rz
    [val_max, idx_max] = max(debattement);
    noms = {'Rx','Ry','Rz'};
    fprintf('\n%s\n', label);
    fprintf('  Rx : min=%.2f°  max=%.2f°  => débattement = %.2f°\n', min(ang(:,1)), max(ang(:,1)), debattement(1));
    fprintf('  Ry : min=%.2f°  max=%.2f°  => débattement = %.2f°\n', min(ang(:,2)), max(ang(:,2)), debattement(2));
    fprintf('  Rz : min=%.2f°  max=%.2f°  => débattement = %.2f°\n', min(ang(:,3)), max(ang(:,3)), debattement(3));
    fprintf('  --> Axe principal : %s avec %.2f° de débattement\n', noms{idx_max}, val_max);
end

fprintf('\n════════════════════════════════════\n');
fprintf('   DÉBATTEMENT ANGULAIRE\n');
fprintf('════════════════════════════════════\n');
affiche_debattement(ang_pm1, 'Petite molette v1');
affiche_debattement(ang_pm2, 'Petite molette v2');
affiche_debattement(ang_gm1, 'Grande molette v1');
affiche_debattement(ang_gm2, 'Grande molette v2');

% Barplot comparatif des débattements
% figure('Name','Débattement angulaire','Color','w','Position',[300 300 700 450]);
% debats = [max(ang_pm1)-min(ang_pm1);
%           max(ang_pm2)-min(ang_pm2);
%           max(ang_gm1)-min(ang_gm1);
%           max(ang_gm2)-min(ang_gm2)];
% 
% b = bar(debats, 'grouped');
% b(1).FaceColor = [0.2 0.4 0.8];
% b(2).FaceColor = [0.4 0.7 0.9];
% b(3).FaceColor = [0.8 0.2 0.2];
% set(gca, 'XTickLabel', {'Petite v1','Petite v2','Grande v1','Grande v2'});
% ylabel('Débattement (°)');
% legend({'Rx','Ry','Rz'}, 'Location','best');
% title('Débattement angulaire par molette et par axe');
% grid on;

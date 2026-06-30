%% ── FIGURE : Débattement angulaire des molettes ──────────────────────────────
figure('Name','Débattement molettes','Color','w','Position',[400 400 800 500]);
hold on; grid on; axis equal;

% ── Paramètres des molettes ───────────────────────────────────────────────────
petite_D  = -58;    % degrés vers la droite
petite_G  =  73;    % degrés vers la gauche
grande_D  = -142;
grande_G  =  87;

% ── Zones mortes ──────────────────────────────────────────────────────────────
% Petite molette : 0° → 14° droite  (0 à -14)
petite_ZM_D_start =   0;
petite_ZM_D_end   = -14;
% Petite molette : 48° → 73° gauche (48 à 73)
petite_ZM_G_start =  48;
petite_ZM_G_end   =  73;
% Grande molette : 0° → 40° gauche  (0 à 40)
grande_ZM_G_start =   0;
grande_ZM_G_end   =  40;

% ── Rayons (visuels) ──────────────────────────────────────────────────────────
r_petite = 1;
r_grande = 1.6;
r_zm_ep  = 0.12;   % épaisseur du secteur zone morte (en unités radiales)

% ── Arcs principaux ───────────────────────────────────────────────────────────
theta_petite = linspace(petite_G, petite_D, 300);
theta_grande = linspace(grande_G, grande_D, 300);

plot(r_petite * cosd(theta_petite + 90), r_petite * sind(theta_petite + 90), ...
     '-', 'Color', [0.2 0.4 0.9], 'LineWidth', 4, 'DisplayName', 'Petite molette');
plot(r_grande * cosd(theta_grande + 90), r_grande * sind(theta_grande + 90), ...
     '-', 'Color', [0.9 0.2 0.2], 'LineWidth', 4, 'DisplayName', 'Grande molette');

% ── Zones mortes (secteurs grisés semi-transparents) ──────────────────────────
function draw_dead_zone(ax, r, r_ep, theta_start, theta_end, color_rgb)
    % Construit un secteur annulaire entre r-r_ep et r+r_ep
    n = 80;
    th = linspace(theta_start, theta_end, n) + 90;  % +90° car 0° = haut
    r_in  = r - r_ep;
    r_out = r + r_ep;
    % Contour du secteur : arc extérieur + arc intérieur (à rebours)
    x = [r_out * cosd(th),  r_in * cosd(fliplr(th)), r_out * cosd(th(1))];
    y = [r_out * sind(th),  r_in * sind(fliplr(th)), r_out * sind(th(1))];
    fill(ax, x, y, color_rgb, 'FaceAlpha', 0.30, 'EdgeColor', color_rgb, ...
         'EdgeAlpha', 0.60, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end

ax = gca;
% Zone morte petite — droite
draw_dead_zone(ax, r_petite, r_zm_ep, petite_ZM_D_end, petite_ZM_D_start, [0.2 0.4 0.9]);
% Zone morte petite — gauche
draw_dead_zone(ax, r_petite, r_zm_ep, petite_ZM_G_start, petite_ZM_G_end, [0.2 0.4 0.9]);
% Zone morte grande — gauche
draw_dead_zone(ax, r_grande, r_zm_ep, grande_ZM_G_start, grande_ZM_G_end, [0.9 0.2 0.2]);

% ── Position initiale (0°) — en haut ─────────────────────────────────────────
plot(0, +r_petite, 'diamond', 'MarkerSize', 12, ...
     'MarkerEdgeColor', [0.1 0.3 0.8], 'MarkerFaceColor', 'white', ...
     'LineWidth', 2, 'HandleVisibility', 'off');
plot(0, +r_grande, 'diamond', 'MarkerSize', 12, ...
     'MarkerEdgeColor', [0.8 0.1 0.1], 'MarkerFaceColor', 'white', ...
     'LineWidth', 2, 'HandleVisibility', 'off');

% ── Marqueurs extrêmes ────────────────────────────────────────────────────────
plot(r_petite * cosd(petite_D + 90), r_petite * sind(petite_D + 90), ...
     '>', 'MarkerSize', 11, 'MarkerEdgeColor', [0.1 0.3 0.8], ...
     'MarkerFaceColor', [0.2 0.4 0.9], 'LineWidth', 2, 'HandleVisibility', 'off');
plot(r_petite * cosd(petite_G + 90), r_petite * sind(petite_G + 90), ...
     '<', 'MarkerSize', 11, 'MarkerEdgeColor', [0.1 0.3 0.8], ...
     'MarkerFaceColor', [0.2 0.4 0.9], 'LineWidth', 2, 'HandleVisibility', 'off');
plot(r_grande * cosd(grande_D + 90), r_grande * sind(grande_D + 90), ...
     '>', 'MarkerSize', 11, 'MarkerEdgeColor', [0.8 0.1 0.1], ...
     'MarkerFaceColor', [0.9 0.2 0.2], 'LineWidth', 2, 'HandleVisibility', 'off');
plot(r_grande * cosd(grande_G + 90), r_grande * sind(grande_G + 90), ...
     '<', 'MarkerSize', 11, 'MarkerEdgeColor', [0.8 0.1 0.1], ...
     'MarkerFaceColor', [0.9 0.2 0.2], 'LineWidth', 2, 'HandleVisibility', 'off');

% ── Lignes radiales ───────────────────────────────────────────────────────────
plot([0, r_petite * cosd(petite_D + 90)], [0, r_petite * sind(petite_D + 90)], ...
     '--', 'Color', [0.2 0.4 0.9 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, r_petite * cosd(petite_G + 90)], [0, r_petite * sind(petite_G + 90)], ...
     '--', 'Color', [0.2 0.4 0.9 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, 0], [0, +r_petite], '--', 'Color', [0.2 0.4 0.9 0.5], ...
     'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, r_grande * cosd(grande_D + 90)], [0, r_grande * sind(grande_D + 90)], ...
     '--', 'Color', [0.9 0.2 0.2 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, r_grande * cosd(grande_G + 90)], [0, r_grande * sind(grande_G + 90)], ...
     '--', 'Color', [0.9 0.2 0.2 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, 0], [0, +r_grande], '--', 'Color', [0.9 0.2 0.2 0.5], ...
     'LineWidth', 1, 'HandleVisibility', 'off');
off = 0.12;
% ── Annotations des angles aux extrêmes ──────────────────────────────────────
text((r_petite+off) * cosd(petite_D + 90) + 0.05, (r_petite+off) * sind(petite_D + 90), ...
     sprintf('%d°', petite_D), 'Color', [0.2 0.4 0.9], 'FontSize', 11, 'FontWeight', 'bold');
text((r_petite+off) * cosd(petite_G + 90) - 0.15, (r_petite+off) * sind(petite_G + 90), ...
     sprintf('%d°', petite_G), 'Color', [0.2 0.4 0.9], 'FontSize', 11, 'FontWeight', 'bold');
text((r_grande+off) * cosd(grande_D + 90) + 0.05, (r_grande+off) * sind(grande_D + 90), ...
     sprintf('%d°', grande_D), 'Color', [0.9 0.2 0.2], 'FontSize', 11, 'FontWeight', 'bold');
text((r_grande+off) * cosd(grande_G + 90) - 0.18, (r_grande+off) * sind(grande_G + 90), ...
     sprintf('%d°', grande_G), 'Color', [0.9 0.2 0.2], 'FontSize', 11, 'FontWeight', 'bold');

% ── Annotations zones mortes ──────────────────────────────────────────────────
% Petite — droite : milieu à -7°
ang_pd = mean([petite_ZM_D_start, petite_ZM_D_end]);
text((r_petite + r_zm_ep + 0.08) * cosd(ang_pd + 90), ...
     (r_petite + r_zm_ep + 0.08) * sind(ang_pd + 90), ...
     'ZM 14°', 'Color', [0.2 0.4 0.9], 'FontSize', 9, 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'center');
% Petite — gauche : milieu à 60.5°
ang_pg = mean([petite_ZM_G_start, petite_ZM_G_end]);
text((r_petite + r_zm_ep + 0.08) * cosd(ang_pg + 90), ...
     (r_petite + r_zm_ep + 0.08) * sind(ang_pg + 90), ...
     'ZM 25°', 'Color', [0.2 0.4 0.9], 'FontSize', 9, 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'center');
% Grande — gauche : milieu à 20°
ang_gg = mean([grande_ZM_G_start, grande_ZM_G_end]);
text((r_grande + r_zm_ep + 0.08) * cosd(ang_gg + 90), ...
     (r_grande + r_zm_ep + 0.08) * sind(ang_gg + 90), ...
     'ZM 40°', 'Color', [0.9 0.2 0.2], 'FontSize', 9, 'FontAngle', 'italic', ...
     'HorizontalAlignment', 'center');

% ── Totaux en bas ─────────────────────────────────────────────────────────────
text(0, -r_petite - 0.15, sprintf('Petite : %d° total', abs(petite_D) + abs(petite_G)), ...
     'Color', [0.2 0.4 0.9], 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(0, -r_grande - 0.15, sprintf('Grande : %d° total', abs(grande_D) + abs(grande_G)), ...
     'Color', [0.9 0.3 0.2], 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% ── Centre ────────────────────────────────────────────────────────────────────
plot(0, 0, 'k+', 'MarkerSize', 12, 'LineWidth', 2, 'HandleVisibility', 'off');

lgd = legend('Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 11);
lgd.Position(2) = lgd.Position(2) - 0.08;
title({'Débattement angulaire des molettes', '◇ = position initiale   ▶ = extrême D   ◀ = extrême G   ▓ = zone morte'});
axis off;
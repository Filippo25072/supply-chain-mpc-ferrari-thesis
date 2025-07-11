% MASTER.m
clear; close all; clc;
if ~exist('Grafici','dir'); mkdir('Grafici'); end

scenari = {'Standard','BacklogRecovery','Shortage','MixVariation'};
kpi_table = [];   % per la tabella finale

for sc = 1:length(scenari)
    scenario = scenari{sc};
    disp(['Simulo scenario: ', scenario]);
    Tsim = 35; mu = 170; sigma = 10;
rng(1);  % per coerenza nei test
d_noise = mu + sigma * randn(Tsim,1);

    [kpi_dmpc, signals_dmpc, t] = SimSupplyChain_DMPC(scenario, d_noise );
    [kpi_cmpc, signals_cmpc, ~] = SimSupplyChain_CMPC(scenario, d_noise);

    % GRAFICI CONFRONTO SPEDIZIONI
    figure('Name',[scenario ' - Spedizioni']);
    plot(t, signals_dmpc.outputs, '--', 'LineWidth', 1.2); hold on; %hold on per tracciare due plot in un grafico
    plot(t, signals_cmpc.outputs, '-', 'LineWidth', 1.5);
    legend({'DMPC Dealer','DMPC Ferrari','DMPC Tier1','DMPC Tier2',...
            'CMPC Dealer','CMPC Ferrari','CMPC Tier1','CMPC Tier2'}, 'Location', 'Best');
    xlabel('Settimana'); ylabel('Spedizioni'); title(['Spedizioni per livello - ', scenario]);
    grid on; saveas(gcf, ['Grafici/' scenario '_Spedizioni.pdf']);

    % GRAFICI TEMPORALI CONFRONTO BACKLOG/STOCK 
    figure; plot(t, sum(signals_dmpc.backlog,2), '--', 'LineWidth',1.2); hold on;
    plot(t, sum(signals_cmpc.backlog,2), '-', 'LineWidth',1.5);
    legend('DMPC','CMPC'); xlabel('Settimana'); ylabel('Totale Backlog');
    title(['Andamento backlog totale - ', scenario]);
    saveas(gcf, ['Grafici/' scenario '_BacklogTempo.pdf']);

    figure; plot(t, sum(signals_dmpc.stock,2), '--', 'LineWidth',1.2); hold on;
    plot(t, sum(signals_cmpc.stock,2), '-', 'LineWidth',1.5);
    legend('DMPC','CMPC'); xlabel('Settimana'); ylabel('Totale Stock - Target');
    title(['Andamento stock totale - ', scenario]);
    saveas(gcf, ['Grafici/' scenario '_StockTempo.pdf']);

    % GRAFICI KPI E SALVATAGGI
    CompareKPI(kpi_dmpc,kpi_cmpc,scenario);

 
  kpi_table = [kpi_table; ...
         {scenario, 'DMPC', kpi_dmpc.backlog_index, kpi_dmpc.stock_index, ...
         };
         {scenario, 'CMPC', kpi_cmpc.backlog_index, kpi_cmpc.stock_index, ...
        }];
end

% per generare tabella excel con i risultati
KPI_tbl = cell2table(kpi_table, ...
    'VariableNames',{'Scenario','Modello','BacklogIndex','StockIndex'});
writetable(KPI_tbl,'Grafici/KPI_Riassuntivo.csv');
disp('Simulazione completa. Tutte le figure e la tabella KPI sono in "Grafici/".');

function CompareKPI(kpi_dmpc, kpi_cmpc, scenario)
%% Confronto grafico dei KPI tra DMPC e CMPC per ogni scenario

if ~exist('Grafici', 'dir')
    mkdir('Grafici');
end

% Nomi dei campi KPI e titoli 
kpi_names = {'backlog_index','stock_index'};
titles = {'Backlog index','Stock index',};

for i = 1:length(kpi_names)
    figure('Name', [scenario ' - ' titles{i}]);

    % Estrazione valore KPI
    val_dmpc = kpi_dmpc.(kpi_names{i});
    val_cmpc = kpi_cmpc.(kpi_names{i});

    if numel(val_dmpc) > 1
        val_dmpc = mean(val_dmpc);
        val_cmpc = mean(val_cmpc);
    end
    
    bar_vals = [val_dmpc, val_cmpc];
    bar(bar_vals);
    set(gca, 'xticklabel', {'DMPC','CMPC'});
    ylabel(titles{i});
    title([titles{i} ' - ' scenario]);

    % Etichette numeriche sulle barre
    text(1:2, bar_vals, string(round(bar_vals,2)), ...
         'HorizontalAlignment','center', ...
         'VerticalAlignment','bottom', ...
         'FontSize', 10);

    % Salva il grafico
    fname = ['Grafici/' scenario '_KPI_' strrep(titles{i},' ','') '.png'];
    saveas(gcf, fname);
end

end

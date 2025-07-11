function [kpi, signals, t] = SimSupplyChain_CMPC(scenario,  d_noise)
% Simulazione Supply Chain CMPC su 4 scenari

N = 4; 

Kp = [0.8 0.8 0.8 0.8];
Ki = [0.4 0.4 0.4 0.4];
Kc = [1.5 1.5 1.5 1.5]; 
alpha_B = 2;
alpha_S = 10;
target = [300 300 300 300];
Tsim = 35;
dt = 1;  % passo temporale

mu = 170; sigma = 10; % domanda media, deviazione std
rng(1);

% INIZIALIZZAZIONE

%d_noise = mu + sigma*randn(Tsim,1);

switch scenario
    case 'Standard'
        % Default

    case 'BacklogRecovery'
        d_noise = mu + 0.3*sigma*randn(Tsim,1); % lieve stocasticità
d_noise(1:3) = d_noise(1:3) + 200; % picco iniziale per creare backlog
    case 'Shortage'
        d_noise = mu + sigma*randn(Tsim,1);
    d_noise(15:20) = d_noise(15:20) - 100; % riduzione drastica della domanda percepita

    case 'MixVariation'
t = (1:Tsim)';
    d_noise = mu + 20 * sin(2 * pi * t / 10) + sigma * randn(Tsim, 1);
end

% INIZIALIZZA VARIABILI DI STATO
outputs = zeros(Tsim,N); 
backlog = zeros(Tsim,N);
backlog_init = zeros(1,N);

if strcmp(scenario, 'BacklogRecovery')
    backlog_init = 150*ones(1,N);
end
backlog(1,:) = backlog_init;
stock = zeros(Tsim,N);
stock(1,:) = target;
t = (0:Tsim-1);

for t_idx = 1:Tsim
    % Consensus
    if t_idx == 1
        prev_stock = target;
        prev_backlog = zeros(1,N);
    else
        prev_stock = stock(t_idx-1,:);
        prev_backlog = backlog(t_idx-1,:);
    end

    consensus = zeros(1,N);
    for i = 1:N
        sum_c = 0;
        for j = 1:N
            if j ~= i
                sum_c = sum_c + alpha_B*prev_backlog(j) + alpha_S*(prev_stock(j)-target(j));
            end
        end
        consensus(i) = sum_c/(N-1);
    end

    % Calcola la spedizione per ogni livello
    for echelon = N:-1:1 
        % Recupera stato e domanda
        if t_idx == 1
            stock_prev = target(echelon);
        else
            stock_prev = stock(t_idx-1,echelon);
            prev_backlog(echelon) = backlog(t_idx-1,echelon);
        end

         if t_idx == 1 %PROF 
            domanda=0; %PROF
        else
            if echelon == N
                domanda = d_noise(t_idx-1);
            else
                domanda = outputs(t_idx-1,echelon+1);
            end
        end

        err = domanda - stock_prev;
        PI_action = Kp(echelon)*err + Ki(echelon)*sum(err)*dt;
        outputs(t_idx,echelon) = PI_action + Kc(echelon)*tanh(consensus(echelon));
        outputs(t_idx,echelon) = max(outputs(t_idx,echelon), 0); % no output negativo

        % Dinamica stock
        stock(t_idx,echelon) = stock_prev + outputs(t_idx,echelon) - domanda; % STOCK
        stock(t_idx,echelon) = max(stock(t_idx,echelon),0);
        stock_bl =  min(stock(t_idx,echelon), prev_backlog(echelon)); 
        stock(t_idx,echelon) = stock(t_idx,echelon) - stock_bl; 


        % Dinamica backlog
        backlog(t_idx,echelon) = prev_backlog(echelon) + domanda - outputs(t_idx,echelon) - stock_bl; 
        backlog(t_idx,echelon) = max(backlog(t_idx,echelon), 0); % per non avere backlog negativo
    end

    % Scenari speciali 
    if strcmp(scenario,'Shortage') && t_idx >= 15 && t_idx <= 20
        outputs(t_idx,1) = 0; % Tier2 fermo
    end
end

% Evita backlog e stock negativi:
backlog = max(backlog, 0);
stock = max(stock, 0);

% CALCOLO KPI 
% Media del backlog in percentuale rispetto al target per ciascun livello
backlog_index = mean(mean(backlog ./ target, 2));
stock_index = mean(mean(stock ./ target, 2));


kpi = struct('backlog_index',backlog_index, ...
             'stock_index',stock_index);

signals = struct('outputs',outputs, ...
                 'backlog',backlog, ...
                 'stock',stock);
end


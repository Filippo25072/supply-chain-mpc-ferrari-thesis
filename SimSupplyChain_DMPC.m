function [kpi, signals, t] = SimSupplyChain_DMPC(scenario, d_noise)
% Simulazione della supply chain con controllo DMPC (Distribuito)

% --- PARAMETRI GENERALI
N = 4;  % livelli: Dealer, Ferrari, Tier1, Tier2
Kp = [0.8 0.8 0.8 0.8];
Ki = [0.25 0.25 0.25 0.25];
target = [300 300 300 300];
Tsim = 35; dt = 1;
mu = 170; sigma = 10;  % domanda media, deviazione std
rng(1);

% INIZIALIZZAZIONE SECONDO SCENARIO
backlog_init = zeros(1,N);
% d_noise = mu + sigma*randn(Tsim,1); % domanda stocastica di default

switch scenario
    case 'Standard'
        % Nessuna modifica

    case 'BacklogRecovery'
        d_noise = mu + 0.3*sigma*randn(Tsim,1); % lieve stocasticità

    case 'Shortage'
        d_noise = mu + sigma*randn(Tsim,1);
    d_noise(15:20) = d_noise(15:20) - 100; % riduzione drastica della domanda percepita

    case 'MixVariation'
        t = (1:Tsim)';
    d_noise = mu + 20 * sin(2 * pi * t / 10) + sigma * randn(Tsim, 1);
end

% INIZIALIZZAZIONE
outputs = zeros(Tsim,N);
backlog = zeros(Tsim,N);
stock = zeros(Tsim,N);
stock(1,:) = target;
backlog(1,:) = backlog_init;
t = linspace(0, (Tsim-1)*dt, Tsim)';

stock(1,:) = target; % lo stock parte uguale al target
backlog_init = zeros(1,N);
if strcmp(scenario, 'BacklogRecovery')
    backlog_init = 150 * ones(1,N);  % backlog solo se richiesto dallo scenario
end
backlog(1,:) = backlog_init;

% LOOP SIMULAZIONE OUTPUT
input_cur = d_noise;
for echelon = N:-1:1
    sys = tf(Kp(echelon) + Ki(echelon)/tf('s'));
    [y, ~] = lsim(sys, input_cur, t);
  y_noisy = y + randn(size(y)) * 10;  % aggiunta di rumore bianco
outputs(:,echelon) = min(max(y_noisy, 0), 2*mu);
   % input_cur = outputs(:,echelon);  % diventa input per livello a monte
input_cur = [outputs(1,echelon); outputs(1:end-1,echelon)]; % Introduzione di un ritardo simulato di 1 time-step, se t > 1
end

% DINAMICA STOCK E BACKLOG
for t_idx = 2:Tsim
    for echelon = 1:N
        if echelon == N
            domanda = d_noise(t_idx);
        else
            domanda = outputs(t_idx, echelon + 1);
        end
        stock(t_idx,echelon) = stock(t_idx-1,echelon) + outputs(t_idx,echelon) - domanda;
        stock(t_idx,echelon) = max(stock(t_idx,echelon),0); 
        stock_bl =  min(stock(t_idx,echelon), backlog(t_idx-1,echelon));
        stock(t_idx,echelon) = stock(t_idx,echelon) - stock_bl; 
        backlog(t_idx,echelon) = backlog(t_idx-1,echelon) + domanda - outputs(t_idx,echelon) - stock_bl; 
    end
end

stock = max(stock, 0);
backlog = max(backlog, 0);

% KPI
% Media del backlog in percentuale rispetto al target per ciascun livello
backlog_index = mean(mean(backlog ./ target, 2));
stock_index = mean(mean(stock ./ target, 2));

kpi.backlog_index = backlog_index;
kpi.stock_index = stock_index;

signals.outputs = outputs;
signals.stock = stock - target;
signals.backlog = backlog;


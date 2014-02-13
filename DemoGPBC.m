% demonstrate usage of classification
%
% Copyright (c) by Carl Edward Rasmussen and Hannes Nickisch 2013-10-16.
clear all 
close all
format compact

seed = 943; randn('seed',seed), rand('seed',seed)

ntr = 50; nte = 1e4;                        % number of training and test points
xtr = 10*sort(rand(ntr,1));                                     % sample dataset
p = @(x) 1./(1+exp(-5*sin(x)));                  % "true" underlying probability
ytr = 2*(p(xtr)>rand(ntr,1))-1;                              % draw labels +1/-1
i = randperm(ntr); nout = 3;                                      % add outliers
ytr(i(1:nout)) = -ytr(i(1:nout)); 
xte = linspace(0,10,1e3)';                    % support, we test our function on
sf = 1; ell = 0.7;                             % setup the GP
hyp0.cov  = log([ell;sf]);                                             
hyp0.mean = [];
Ncg = 50;                                   % number of conjugate gradient steps
sdscale = 0.5;                  % how many sd wide should the error bars become?
col = {'k',[.8,0,0],[0,.5,0],'b',[0,.75,.75],[.7,0,.5]};                % colors
ymu{1} = 2*p(xte)-1; ys2{1} = 0; 
fmu{1} = 0; fs2{1} = 0;
%% Initialise own variables
mean2 = zeros(size(xtr,1),1);                   % m(x) = 0
cov = @covSqExp;                % Covarience kernel
inference = @inferLaplace;      % Inference function
lik = @likLogistic1;            % Likelihood 
piStarMAP = @likLogistic1;      % MAP prediction
piStarAvg = @cdfLogistic;       % Averaged prediction 

%% My implementation
tic
hyp0.lik = [];

% dbstop in inference
% dbstop in predict
% dbstop in optimizeHyp
% dbstop in posteriorMode
% dbstop in brentmin

hyp = optimizeHyp(hyp0, -Ncg, inference, cov, lik, xtr, ytr);   % opt hypers
hyp.cov
alpha = zeros(ntr,1);
% log marginal liklihood and posterior
[post{2},nlZ(2)] = posteriorMode(hyp, alpha, cov,lik,xtr,ytr); % without stored 'alpha'
% Predict
[ymu{2}, ys2{2},fmu{2},fs2{2}] = predict(hyp, post{2}, cov, piStarMAP, xtr, xte);  % predict
[ymu{3}, ys2{3},fmu{3},fs2{3}] = predict(hyp, post{2}, cov, piStarAvg, xtr, xte);  % predict
toc

%% Plot results
figure, hold on
for i=1:3
  plot(xte,ymu{i},'Color',col{i},'LineWidth',2)
  if i==1
    leg = {'function'};
  else if i==2
    leg{end+1} = sprintf('MAP ymu');
  else if i==3
    leg{end+1} = sprintf('Avg ymu');                          
      end
      end
  end
end
plot(xte,fmu{2},'Color',col{6},'LineWidth',2)
leg{end+1} = sprintf('fmu (latent)');
ysd = sdscale*sqrt(fs2{2});
fill([xte;flipud(xte)],[fmu{i}+ysd;flipud(fmu{i}-ysd)],...
     col{2},'EdgeColor',col{6},'FaceAlpha',0.1,'EdgeAlpha',0.3);

for i=1:3
  ysd = sdscale*sqrt(ys2{i});
  fill([xte;flipud(xte)],[ymu{i}+ysd;flipud(ymu{i}-ysd)],...
       col{i},'EdgeColor',col{i},'FaceAlpha',0.1,'EdgeAlpha',0.3);
end

plot(xtr,ytr,'k+'), plot(xtr,ytr,'ko'), legend(leg,'Location','best')
ylim([-5 5])


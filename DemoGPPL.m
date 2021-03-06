clear all 
close all
format compact

% You can adjust this:
% Preference function of the user (considered unknown)
% pf = @(x) -0.06*x.^4 - 0.08*x.^3 + 0.6*x.^2 + 0.6*x;
pf = @(x) 0.1*(-0.129*x.^4 - 0.1*x.^3 + 2.82*x.^2 + 3*x);
% pf = @(x) 5*x.^3 + 3*x.^2 - 80*x + 200;
% The number of training samples
M = 40;

compare_pf = @(x) ((pf(x(1)) > pf(x(2)))-0.5)*2;

% Generate training data and calculate corresponding labels on interval
% [a,b]
a=-5; b = 5; 
% xtr = randi([-5, 5], M,2);      % Integers
xtr = a + (b-a).*rand(M,2);     % Real values
C = num2cell(xtr, 2);
ytr = cellfun(compare_pf, C);

% Create a grid where we will test our GP on
ntr=200;     % number of training samples
xx=linspace(-5,5,ntr);
[t1, t2] = meshgrid(xx, xx);
xte = [t1(:) t2(:)];

col = {[.8,0,0],'k',[0,.5,0],'b',[0,.75,.75],[.7,0,.5]};                % colors

%% Calculate 
% hyper parameter optimization has not been implemented yet, use the
% following:


covSE = @covSqExp;                % Covarience kernel
covPJ = @covPrefJudge;            % Covarience kernel
inference = @inferLaplace;      % Inference function
lik = @likLogistic1;            % Likelihood 
piStarMAP = @likLogistic1;      % MAP prediction
piStarAvg = @cdfLogistic;       % Averaged prediction 
piStarErf = @predErf;
piStarProbit = @predProbit;     % Class prediction as in MacKay

% dbstop posteriorMode
% dbstop predict
% dbstop covPrefJudge

% Peform classification
alpha = zeros(M,1);
cov = {covPJ,covSE}; m = 2;
hyp{1}.cov = [0.2 0.5];
% hyp{1} = optimizeHyp(hyp{1}, -50, inference, cov{1}, lik, xtr, ytr);
hyp{2} = optimizeHyp(hyp{1}, -50, inference, cov{2}, lik, xtr, ytr);

%% Calculate predictions
for n=1:m
    hyp{n}.cov
    [post{n},nlZ{n}] = posteriorMode(hyp{n}, alpha, cov{n},lik,xtr,ytr); % Determine posterior and -log marginal likelihood
    [ymu{n},ys2{n},fmu{n},fs2{n}] = predict(hyp{n}, post{n}, cov{n},lik, piStarAvg, xtr, xte);  % predict
end
nlZ
%% Create the 2D plot
u = xtr(:,1); v = xtr(:,2);
for n =1:m
    figure; hold on;
    % axis off;
    colormap('gray');
%     ymu2D{n} = vec2mat(ymu{n}, nt); % should be a standard matlab function
    ymu2D{n} = reshape(ymu{n},ntr, [])';
    imagesc(xx,xx,ymu2D{n});
    axis tight
    xlabel('u')
    ylabel('v')
    plot(u(ytr<0),v(ytr<0),'ro');
    plot(u(ytr>=0),v(ytr>=0),'bx');
    title(sprintf('Predicted probability P[y=1|(u,v),g] with cov = %s',func2str(cov{n})))
end

%% Create a plot with the original function and the estimated function
% We try to recreate the original function (which is impossible) but it
% gives you a nice picture.
% We sum the result per column (so per column (so per x) we get a value
% which describes how 'much better' it is in comparisons with the rest.
% We then normalize this and stretch it out again so it better matches with
% the functions scale.
figure; hold on;
plot(xx, pf(xx));
leg = {'Orig function'};
yNorm = zeros(ntr,m);
m=1;
for n = 1:m
    yNorm(:,n) = sum(ymu2D{n});
    yNorm(:,n) =  - yNorm(:,n);
    mmin = min(yNorm(:,n));
    mmax = max(yNorm(:,n));
    yNorm(:,n) = (yNorm(:,n)-mmin) ./ (mmax-mmin);
    pf_xx = pf(xx);
    yNorm(:,n) = yNorm(:,n) * (max(pf_xx) - min(pf_xx)) + min(pf_xx);
    plot(xx, yNorm(:,n), 'Color',col{n});
    leg{end+1} = sprintf('Cov = %s',func2str(cov{n}));
end


ys2Norm = zeros(ntr,m); % Normalized variance for functions
% calculate the variance for the reconstructed regression line
for n=1:m
    ys2D = reshape(ys2{n}, ntr, [])';
    ys2Norm(:,n) = sum(ys2D) / ntr;
    f = [yNorm(:,n)+2*sqrt(ys2Norm(:,n)); flipud(yNorm(:,n)-2*sqrt(ys2Norm(:,n)))];
    fill([xx'; flipdim(xx', 1)], f, col{n},'EdgeColor',col{n},'FaceAlpha',0.1,'EdgeAlpha',0.3);
end

xlabel('\theta')
ylabel('Normalized f(\theta)')
title('Preference function')
legend(leg,'Location','best')

% We then find the maxima of our prediction and of the preference function
% We print the absolute distance between (smallest step size is 0.25
% because of the grid (see line 28)). We also take the difference between
% the two points (on the preference function).
[ymx, loc2] = max(pf_xx);
plot(xx(loc2), ymx, 'bo');
for n = 1:m
    [ymx, loc1] = max(yNorm(:,n));
    plot(xx(loc1), ymx, 'o', 'Color', col{n});
end
fprintf('Distance between two maxima: %f\n', abs(xx(loc1)-xx(loc2)));
fprintf('Difference between two maxima: %f\n', abs(pf(xx(loc1))-pf(xx(loc2))));

% We calculate all the correct labels for the grid (the testing data) and
% compare that to our predictions, we output the number of differences.
correct = num2cell(xte, 2);
correct = cellfun(compare_pf, correct);
our_prediction = ((ymu{2} > 0.5)-0.5).*2;
errors = correct ~= our_prediction;
fprintf('Number of comparisons wrong: %d of %d\n', sum(errors),length(correct));


%% plot various functions on one line
Sel = 1:2:200;
% Sel = 100:2:200;
plotLatent(ymu2D{1},xx,Sel)
fmu2D = reshape(fmu{1},ntr, [])';
plotLatent(fmu2D,xx,Sel)

% figure
% plot(loc2)


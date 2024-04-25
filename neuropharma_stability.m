function [stable, range_var] = neuropharma_stability(data,tolerance)
% function [stable, range_var] = neuropharma_stability(data,tolerance)
%
% This function generates the array indicating stability defined as the
% variance of values within tolerance limit (default 10%).
%
% When using multiple tolerance limits, output variable stable should be
% interpreted in a similar fashion to the minterms in a Karnaugh map.
%
% Assumptions:
%  - temporal dimension of data is along a column ie. num rows
%  - number of columns represent the different parameters
%
% Inputs:
% 	data 	  - input data of dimension time x parameters
%   tolerance - user defined tolerance limit
%
% Outputs:
% 	stable		- list of indices in a array to enable further processing
%
% Author:- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 28 June 2014 - basic implementation
%  0.2 - 29 June 2014 - multiple parameters
%  0.3 - 29 June 2014 - multiple tolerance values

%% input processing
if nargin == 0
    disp('Input undefined');
    return;
end

% assign default value
if nargin == 1
    tolerance = 0.1; % 10%
end

%% initializations

% number of parameters
n_params = size(data,2);

% length of the input data
len = size(data,1);

% number of tolerance limits
n_limits = length(tolerance);

% intialize output variable
stable = zeros(len,n_params,'single');

if nargout == 2
    % intialize range output variable
    range_var = zeros(len,n_params,'single');
end


%% compute stability output on the input data

% compute over each parameter separately
for param = 1:n_params
    
    % compute stability for a paramter
    for t = 3:len
        % extract the values in each window
        win = data(t-2:t,param);
        
        % compute maximum in the window
        max_win = max(win);
        
        % compute minimum in the window
        min_win = min(win);
        
        % compute range within the window
        val = max_win/min_win-1;
        
        if nargout == 2
            % store range value only if the output is requested
            range_var(t,param) = val;
        end
        
        % set output comparing if range is within user defined tolerance value
        for lmt = 1:n_limits
            
            % compare with each tolerance limit
            if val <= tolerance(lmt)
                
                % use Karnaugh map minterm representation to combine output
                stable(t,param) = stable(t,param)+ (2^(lmt-1));
            end
        end
    end
end

end
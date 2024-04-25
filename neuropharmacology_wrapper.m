% #! MATLAB script
% This script processes the neuropharmocological results documented in an excel sheet
% The excel sheet contain 1 sheet per experiment trial for all trials of a given drug
%
% Inputs:
% 	paths to input and output folders, excel file name to process
%   list of drugs to process
%
% Author :- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 01 July 2014 - basic implementation
%  0.2 - 04 July 2014 - upgraded for automation on multiple flags
%  0.3 - 24 July 2014 - added washout feature in flags
%  0.4 - 06 Oct  2014 - added writing output file feature
%  0.5 - 02 Jan  2015 - cleanup

% start afresh
clear;    close;  clc; % clear all data, figures, and console

%% specify inputs - configuration

% flag to enable plotting of single trial
single_trial = 1;

% flag to enable plotting of population results
population_stats = 0;

% whether to perform normalization on the parameters
enable_normalization_flags = [ 0 1 ];

% washout plots
washout_flags = [0 1];

% flag to convey whether to plot figures
draw_plots = 0;

% flag to convey whether to save population values as excel
write_xl_file = 1;

% name of the output excel file
output_xl_file = 'Population';

% flag to specify whether to overwrite on the output excel file
overwite = 0;

% list of drugs to process the data
drug_list = ...
    {
    'Kainate';
    'Pirenzepine';
    'Physostigmine';
    'Scopolamine';
    'DAP5';
    'Atropine';
    'NBQX';
    'Gabazine';
    'Carbachol';
    };

% path to the folder where data is present
data_path = 'data/';

% path to output folder
out_path_base = 'statistics';

% set the plot file extension type
file_extension = 'png';

% color for: Peak power, peak freq, AUC
col = [  1   0   0;  % red
         0  0.75 0;  % dark green
         0   0   1]; % blue

% width of line in the plots
line_width = 1;

% set font size for the figure legends
font_size = 8;

%% initializations
% Range within excel sheet - currently unused
%  xlRange = 'B1:D26';

% flag to enable wrapper integration
enable_wrapper = 1;

% name of the sheet within the excel file to process
only_sheet = ''; % empty processes all files


% call the script for each drug on the list
for num = 1:length(drug_list)
    
    % select the drug from the list of drugs
    drug = drug_list{num};
    
    switch drug
        
        case 'Carbachol'
            
            % name of the input excel file
            input_xl_file_name = 'Carbachol';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Carbachol-peak_10'
            
            % name of the input excel file
            input_xl_file_name = 'Carbachol-peak_10';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Gabazine'
            
            % name of the input excel file
            input_xl_file_name = 'Gabazine';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'NBQX'
            
            % name of the input excel file
            input_xl_file_name = 'NBQX';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Atropine'
            
            % name of the input excel file
            input_xl_file_name = 'Atropine';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'DAP5'
            
            % name of the input excel file
            input_xl_file_name = 'DAP5';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Scopolamine'
            
            % name of the input excel file
            input_xl_file_name = 'Scopolamine';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Kainate'
            
            % name of the input excel file
            input_xl_file_name = 'Kainate';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Physostigmine'
            
            % name of the input excel file
            input_xl_file_name = 'Physostigmine';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        case 'Pirenzepine'
            
            % name of the input excel file
            input_xl_file_name = 'Pirenzepine';
            
            % name of the sheet within the excel file to process
            only_sheet = '';
            
        otherwise
            % unsupported drug
            disp(['Drug: ' drug ' not on list']);
            continue;
            
    end
    
    for washout = washout_flags

        if washout
            input_xl_file_name = [input_xl_file_name ' - washout'];
            
            % concatenate input file name
            input_file_name = [data_path '\' input_xl_file_name '.xlsx'];

            % verify input file integrity
            if exist(input_file_name,'file') == 0
                % If File not found then ignore (WO is not always done)
                continue;
            end
            
            drug = [drug '_washout'];
        end
        
        for enable_normalization = enable_normalization_flags
            
            if single_trial
                
                % path to output folder
                out_path = [out_path_base '/trials'];
                
                if enable_normalization
                    out_path = [out_path '_norm'];
                end
                
                % call the script to plot each experiment of this drug
                neuropharmacology_trials;
            end
            
            if population_stats
                
                % path to output folder
                out_path = [ out_path_base '/population'];
                output_xl_file_name = output_xl_file;
                
                if enable_normalization
                    out_path = [out_path '_norm'];
                    output_xl_file_name = [output_xl_file '_norm'];
                end
                
                % call the script to plot each experiment of this drug
                neuropharmacology_population;
            end
        end
    end
end
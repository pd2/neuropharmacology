% #! MATLAB script
% This script processes the neuropharmocological results documented in an excel sheet
% The excel sheet contain 1 sheet per experiment trial for all trials of a given drug
%
% Assumptions on the format of the data recorded in excel sheet
% - temporal dimension - along a column ie. num of rows = sampling of data 
% - 1st column : time of the day when the data was recorded
% - Other columns: 3 parameters per electrode - arranged column wise 
%
% Inputs:
% 	paths to input and output folders, excel file name to process
%
% Outputs:
% 	saves a PNG plots for each trial for a given experiment / drug
%
% Author :- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience, 
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:- 
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 28 June 2014 - basic implementation to plot result
%  0.2 - 29 June 2014 - updated for all sheets in a excel file
%  0.3 - 01 July 2014 - bug fix for overnight runs, file handling

%% Configuration of this script - conditional execution to allow wrapper file
if ~(exist('enable_wrapper','var') && enable_wrapper)

% start afresh
clear;    close;  clc; % clear all data, figures, and console

% specify inputs - configuration

% path to the folder where data is present
data_path = 'data/';

% path to output folder
out_path = 'results/';

% name of the drug
drug = 'Carbachol';

% name of the input excel file
% xl_file_name = 'Carbachol';
xl_file_name = 'Carbachol - peak-10uM';

% name of the sheet within the excel file to process
only_sheet = '';

% whether to perform normalization on the parameters
enable_normalization = 0;

% Range within excel sheet - currently unused
%  xlRange = 'B1:D26';

% set the plot file extension type
file_extension = 'png';

% width of line in the plots
line_width = 1;

% set font size for the figure legends
font_size = 7;

% color for: Peak power, peak freq, AUC
col = [  1   0   0;  % red
         0  0.75 0;  % dark green
         0   0   1]; % blue

end

%% initialization of paramters

% File format assumption: time column, 3 params per electrode - column wise 

% number of parameters per recording
num_params = 3;

% is the time axis present in the excel sheet
time_col_offset = 1;

% set stability tolerance 10%
tolerance = 0.1;

% verify output path integrity
if exist(out_path,'dir') == 0
    mkdir(out_path);
end

%% process excel file

% concatenate input file name
input_file_name = [data_path '/' xl_file_name '.xlsx'];

% verify input file integrity
if exist(input_file_name,'file') == 0
    
    % File not found. Print to console and exit
    disp(['Error: ' input_file_name ' does not exists']);
    disp ' ';    
    return;
end

% check the status of the input file
[file_status, list_of_sheets, format] = xlsfinfo(input_file_name);

% Check integrity of the file format
if ~strcmp(file_status,'')
    
    % On Windows systems with Excel software, 'format' is a string that 
    % contains the description MS Excel software returns for the file.
    if ~strcmp(format,'xlOpenXMLWorkbook')
        disp('Warning: Processing a untested excel file format');
    end
    
    % Print to console the list of sheets within the given excel sheet
    disp(['Sheets present in ' input_file_name ' :']); 
    disp(list_of_sheets);
    
else
    
    % Improper file - Print to console and exit
    disp(['Error: ' input_file_name 'is not a valid input file'])
%     disp('Exiting program');
    disp ' ';
    
    return;
end

% get the number of sheets in the excel sheet
num_sheets = size(list_of_sheets,2);
% if no sheets to process then exit
if (num_sheets==0)
    disp('Nothing to process');
    disp ' ';
    return;
end

%% perform for each sheet

for num = 1:length(list_of_sheets)
    
    sheet_name = list_of_sheets{num}; % format cell as string 
    
    % perform only for a specific sheet
    if ( strcmp(only_sheet,'') || strcmp(only_sheet,sheet_name) )
        
    % print to console the current sheet
    disp(['Processing sheet: ' sheet_name]);
    
    % read the file contents and extract data into MATLAB
    data = xlsread(input_file_name,sheet_name);

    %% process data
    
    % check for non-zero data 
    if ~size(data)
        disp('No data');
        continue;
    end

    % extract x axis time scale
    interval = ( data(2:end,1) - data(1:end-1,1) ) ;

    % compute time scale from interval for plots in minutes
    time = 24 * 60 * cumsum([0; interval]) ; % data is in days
    time = mod(time,24*60); % bug fix for over night runs
    time = single(time); % bug fix for double precision

    % number of electrodes in this experiment trial
    num_electrodes = (size(data,2) - time_col_offset)/num_params;


    % create figure
    hfig = figure('visible','off');
    
    %% process each electrode separately
    for electrode = 1: num_electrodes
        
        %% create subplot for peak power of each electrode
        subplot(num_params,num_electrodes,electrode+num_electrodes*(1-1));
        
        % extract peak power values from excel data
        peak_power = data(:, time_col_offset+(electrode-1)*num_params+1);
        
        % normalize w.r.t control reading
        if enable_normalization
            peak_power = peak_power/peak_power(1)*100;
        end
        
        % compute stability
        stable_val = peak_power .* neuropharma_stability(peak_power,tolerance);
        
        % plot peak power
        plot(time,peak_power,'.-','Color',col(1,:),'LineWidth',line_width);
        hold on;
        
        % coordinates for circling the stable readings
        mark_time = time(stable_val~=0);
        mark_val = stable_val(stable_val~=0); 
        % circle output when stable
        plot(mark_time,mark_val,'o','Color',col(1,:));
        
        % annotation of the plot
        axis tight;
        grid on;
        title(['Electrode ' num2str(electrode)],'FontSize',font_size);
        %     xlabel('Time (in mins)');
        if (electrode == 1)
        if enable_normalization
            ylabel('Normalized Peak power %','FontSize',font_size);
        else
            ylabel('Peak power (\muV^2/Hz)','FontSize',font_size);
        end
        end
        
        %% create subplot for peak frequency of each electrode
        subplot(num_params,num_electrodes,electrode+num_electrodes*(2-1));
        
        % extract peak frequency values from excel data
        peak_freq = data(:, time_col_offset+(electrode-1)*num_params+2);
        
        % normalize w.r.t control reading
        if enable_normalization
            peak_freq = peak_freq/peak_freq(1) *100;
        end
        
        % compute stability
        stable_val = peak_freq.*neuropharma_stability(peak_freq,tolerance);
        
        % plot peak frequency
        plot(time,peak_freq,'.-','Color',col(2,:),'LineWidth',line_width);
        hold on;
        
        % coordinates for circling the stable readings
        mark_time = time(stable_val~=0);
        mark_val = stable_val(stable_val~=0); 
        % circle output when stable
        plot(mark_time,mark_val,'o','Color',col(2,:));
        
        % annotation of the plot
        axis tight;
        grid on;
        %     xlabel('Time (in mins)');
        if (electrode == 1)
        if enable_normalization
            ylabel('Normalized Peak Frequency %','FontSize',font_size);
        else
            ylabel('Peak Frequency (Hz)','FontSize',font_size);
        end
        end
        %     title(['Electrode ' num2str(electrode)]);
        
        %% create subplot for area under curve of each electrode
        subplot(num_params,num_electrodes,electrode+num_electrodes*(3-1));
        
        % extract area under curve values from excel data
        area_under_curve = data(:, time_col_offset+(electrode-1)*num_params+3);
        
        % normalize w.r.t control reading
        if enable_normalization
            area_under_curve = area_under_curve/area_under_curve(1) *100;
        end
        
        % compute stability
        stable_val = area_under_curve .* neuropharma_stability(area_under_curve,tolerance);
        
       % plot area under curve
        plot(time,area_under_curve,'.-','Color',col(3,:),'LineWidth',line_width);
        hold on;
        
        % coordinates for circling the stable readings
        mark_time = time(stable_val~=0);
        mark_val = stable_val(stable_val~=0); 
        % circle output when stable
        plot(mark_time,mark_val,'o','Color',col(3,:));
        
        % annotation of the plot
        axis tight;
        grid on;
        xlabel('Time (in mins)','FontSize',font_size);
        if (electrode == 1)
        if enable_normalization
            ylabel('Normalized AUC %','FontSize',font_size);
        else
            ylabel('AUC (\muV^2/Hz*kHz)','FontSize',font_size);
        end
        end
        
        %     legend({['Peak power '  '%']; ['Peak Freq ' '%']; ['AUC ' '%']});
        %     title(['Electrode ' num2str(electrode)]);
        
    end
    
    % super title for entire plot
    annotation('textbox',[.35 .96 .3 .035],'String',[xl_file_name],...
        'HorizontalAlignment','center','FontSize',font_size+2);
    
    % generate output file name with path
    out_file_name = [out_path '/' xl_file_name '_' sheet_name];
    
    if enable_normalization
        out_file_name = [out_file_name '_norm'];
    end 
    % save the generate plot
    saveas(hfig,out_file_name,file_extension);
    
    % close figure
    close(hfig);
    
    disp('Done');

    else
        % print to console the skipped sheets
        disp(['Skipping sheet: ' sheet_name]);
    end
    
end

disp ' ';
disp(['Output plots saved in folder: "' out_path '"']);

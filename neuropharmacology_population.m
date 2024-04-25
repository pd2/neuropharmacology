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
% 	saves PNG population plots for a given drug
%
% Author :- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 01 July 2014 - basic implementation for population plot
%  0.2 - 02 July 2014 - bug fix for double precision
%  0.3 - 05 Oct  2014 - feature upgrade on plots
%  0.4 - 06 Oct  2014 - feature addition - outputing a excel file
%  0.5 - 16 Oct  2014 - feature addition - plot population data from excel file

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
    drug = 'NBQX';
    
    % name of the input excel file
    input_xl_file_name = 'NBQX';
    
    % name of the output excel file
    output_xl_file_name = 'population';
    
    % whether to perform normalization on the parameters
    enable_normalization = 0;
    
    % flag to convey whether to compute population statistics
    population_stats = 1;
    
    % flag to convey whether to plot figures
    draw_plots = 1;
    
    % flag to convey whether to save population values as excel
    write_xl_file = 1;
    
    % name of the excel file with population data
    xl_file_name = 'Population - Physostigmine';
    
    % flag to specify whether to overwrite on the output excel file
    overwite = 0;
    
    % name of the sheet within the excel file to process
    if population_stats
        only_sheet = ''; %'20140610';
    else
        only_sheet = 'Kainate_pop'; % cannot be empty
    end
    
    % Range within excel sheet - currently unused
    %  xlRange = 'B1:D26';
    
    % set the plot file extension type
    file_extension = 'png';
    
    % width of line in the plots
    line_width = 1;
    
    % set font size for the figure legends
    font_size = 8;
    
    % color for: Peak power, peak freq, AUC
    col = [ 1   0   0;  % red
            0  0.75 0;  % dark green
            0   0   1]; % blue
    
end

%% initialization of paramters

% number of standard deviations for plotting error bars
n_stds = 1.96;

% File format assumption: time column, 3 params per electrode - column wise

% number of parameters per recording
num_params = 3;

% is the time axis present in the excel sheet
time_col_offset = 1;

% set stability tolerance 10%
tolerance = 0.1;

% check sanity of user defined flags
if ( (population_stats == 1) && (draw_plots == 0) && (write_xl_file == 0) )
    % No outputs: Neither writing output file nor ploting results.
    disp('Error: No outputs requested. Exiting.. ')
    return;
end
if ( (population_stats == 0) && (write_xl_file == 1) )
    % Do not output excel file when reading from the final result from excel
    disp('Warning: Outputs file disabled.')
    write_xl_file = 0; % disble output file write
end
if ( (population_stats == 0) && (draw_plots == 0) )
    % No output : Not ploting the results read from population excel.
    disp('Error: No plots requested. Exiting.. ')
    return;
end
disp ' ';

% verify output path integrity
if exist(out_path,'dir') == 0
    mkdir(out_path);
end

%% process input single trial excel file

% concatenate input file name with path

% assign input file based on user flag 
if population_stats
    input_file_name = [data_path '/' input_xl_file_name '.xlsx'];
else
    input_file_name = [data_path '/' xl_file_name '.xlsx'];
end

% verify input file integrity
if exist(input_file_name,'file') == 0

    % File not found. Print to console and exit
    disp(['Error: Input file ' input_file_name ' does not exists']);
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
        disp('Warning: Processing an untested excel file format');
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
    disp('Not sheets to process');    disp ' ';
    return;
end

% check whether to compute statistics from single trials
if population_stats
    %% initialize variables
    
    % initialize variables to track the number of trials per drug
    n_slices = 0;
    n_animals = 0;
    
    %
    final_sheets = {'Trials'};
    
    % create a generic structure
    population = struct('time',zeros(0,'single'),'reading',{});
    
    % population structure as required by neuropharma_collate_trials() function
    pop_peak_power = struct(population);
    pop_peak_freq = struct(population);
    pop_auc = struct(population);
    
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
            
            %% process each electrode separately
            for electrode = 1: num_electrodes
                
                % extract peak power values from excel data
                peak_power = data(:, time_col_offset+(electrode-1)*num_params+1);
                
                % normalize w.r.t control reading
                if enable_normalization
                    peak_power = peak_power/peak_power(1)*100;
                end
                
                % combine current trial into population data
                pop_peak_power = neuropharma_collate_trials(pop_peak_power, time, peak_power);
                
                % extract peak frequency values from excel data
                peak_freq = data(:, time_col_offset+(electrode-1)*num_params+2);
                
                % normalize w.r.t control reading
                if enable_normalization
                    peak_freq = peak_freq/peak_freq(1) *100;
                end
                
                % combine current trial into population data
                pop_peak_freq = neuropharma_collate_trials(pop_peak_freq, time, peak_freq);
                
                % extract area under curve values from excel data
                area_under_curve = data(:, time_col_offset+(electrode-1)*num_params+3);
                
                % normalize w.r.t control reading
                if enable_normalization
                    area_under_curve = area_under_curve/area_under_curve(1) *100;
                end
                
                % combine current trial into population data
                pop_auc = neuropharma_collate_trials(pop_auc, time, area_under_curve);
                
                % increment the count for num slices
                n_slices = n_slices + 1;
                
            end
            
            % collate the trials used
            final_sheets = [final_sheets {sheet_name}];
            
            % increment the count for num animals
            n_animals = n_animals + 1;
            
        else
            % print to console the skipped sheets
            disp(['Skipping sheet: ' sheet_name]);
        end
        
    end
    
    % compute statistical results
    [pop_peak_power.mean, pop_peak_power.se] = neuropharma_population_stats(pop_peak_power.reading);
    [pop_peak_freq.mean, pop_peak_freq.se] = neuropharma_population_stats(pop_peak_freq.reading);
    [pop_auc.mean, pop_auc.se] = neuropharma_population_stats(pop_auc.reading);
    
else
    
    %% iterate over all sheets
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
            
            % extract x axis time scale (reference) in mins
            time = data(2:end,1)';
            
            pop_peak_power.time = time;
            pop_peak_freq.time = time;
            pop_auc.time = time;
            
            % extract mean of peak power population data
            pop_peak_power.mean = data(2:end,2)';
            
            % extract s.e.m of peak power population data
            pop_peak_power.se = data(2:end,5)';
            
            % extract mean of peak frequency population data
            pop_peak_freq.mean = data(2:end,3)';
            
            % extract s.e.m of peak frequency population data
            pop_peak_freq.se = data(2:end,6)';
            
            % extract mean of area under curve population data
            pop_auc.mean = data(2:end,4)';
            
            % extract s.e.m of area under curve population data
            pop_auc.se = data(2:end,7)';
            
            % extract n values for this population
            n_slices = data(1,9);
            n_animals = data(2,9);
            
            % do not continue to process the sheets after a hit, instead exit
            break;
           
        end
    end
end

% save the population results as excel file
if ( write_xl_file ) % && (compute_pop_stats == 0) )
    tic;
    %% process output excel file
    
    % concatenate output file name with path
    output_file_name = [out_path '/' output_xl_file_name '.xlsx'];
    
    sheet_name = [ drug '_pop'];
    
    % turn OFF the warning for addition of new sheet to excel file
    warning('off','MATLAB:xlswrite:AddSheet');
    
    % write reference time data
    % [status,msg] = xlswrite(output_file_name,{'Ref Time'}, sheet_name,'A1');
    % [status,msg] = xlswrite(output_file_name,pop_peak_power.time', sheet_name,'A2');
    [status, msg] = np_xlswrite_w_header(output_file_name,'Ref Time',...
        pop_peak_power.time','A',sheet_name,overwite);
    
    % revert the status of the warning altered previously
    warning('on','MATLAB:xlswrite:AddSheet');
    
    % verify write operation
    if status == 0
        % Print to console and exit
        disp(['Error: Write operation failed']);    disp ' ';
        return;
    end
    
    % write population data headers
    [status, msg] = xlswrite(output_file_name,...
        {'Mean Peak Power','Mean Peak Freq','Mean AUC',...
        's.e.m Peak Power','s.e.m Peak Freq','s.e.m AUC'},sheet_name,'B1');
    
    % verify write operation
    if status == 0
        % Print to console and exit
        disp(['Error: Write operation failed']);    disp ' ';
        return;
    end
    
    % write population data values
    [status, msg] = xlswrite(output_file_name,...
        [pop_peak_power.mean',pop_peak_freq.mean',pop_auc.mean',...
        pop_peak_power.se',pop_peak_freq.se',pop_auc.se';],sheet_name,'B2');
    
    % verify write operation
    if status == 0
        % Print to console and exit
        disp(['Error: Write operation failed']);    disp ' ';
        return;
    end
    
    % write n values for slices and animals
    [status,msg] = xlswrite(output_file_name,{'N Slices','N Animals';n_slices,n_animals}', sheet_name,'H1');
    
    % verify write operation
    if status == 0
        % Print to console and exit
        disp(['Error: Write operation failed']);    disp ' ';
        return;
    end
    
    disp ' ';
    disp(['Population data saved in folder: "' out_path '"']);
    
    toc;
end

if draw_plots
    % create figure
    hfig_all = figure('visible','off');
    
    % super title for entire plot
    annotation('textbox',[.3 .95 .3 .04],'String',[input_xl_file_name],...
        'HorizontalAlignment','center','FontSize',font_size+2);
    
    %% create subplot for peak power
    subplot(num_params,1,1);
    
    % plot peak power with error bars
    errorbar(pop_peak_power.time,pop_peak_power.mean,n_stds*pop_peak_power.se,'x-','Color',col(1,:),'LineWidth',line_width);
    
    % generate output file name with path
    out_file_name = [out_path '/' input_xl_file_name '_population_peak_power'];
    
    % annotate  the plot
    if enable_normalization
        ylabel_norm = 'Normalized Peak power %';
        out_file_name = [out_file_name '_norm'];
    else
        ylabel_wo_norm = 'Peak power (\muV^2/Hz)';
    end
    np_annotate;
%     a = ylim; ylim([a(1) 100]);    
    
    % list of sheets used
    % annotation('textbox',[.91 .75 .085 .175],'String',final_sheets,'FontSize',font_size-1);
    
    % create figure
    hfig = figure('visible','off');
    
    % plot peak power with error bars
    errorbar(pop_peak_power.time,pop_peak_power.mean,n_stds*pop_peak_power.se,'x-','Color',col(1,:),'LineWidth',line_width);
    
    % annotate the plot
    title(['Effect of ' input_xl_file_name]);
    np_annotate;
    % name the x-axis
    xlabel('Time (mins)','FontSize',font_size);
    
    % save the generate plot
    saveas(hfig,out_file_name,file_extension);
    
    % close figure
    close(hfig);
    
    %% create subplot for peak frequency
    subplot(num_params,1,2);
    
    % plot peak power with error bars
    errorbar(pop_peak_freq.time, pop_peak_freq.mean, n_stds * pop_peak_freq.se,'x-','Color',col(2,:),'LineWidth',line_width);
    
    % generate output file name with path
    out_file_name = [out_path '/' input_xl_file_name '_population_peak_freq'];
    
    % annotate the plot
    if enable_normalization
        ylabel_norm = 'Normalized Peak Frequency %';
        out_file_name = [out_file_name '_norm'];
    else
        ylabel_wo_norm = 'Peak Frequency (Hz)';
    end
    np_annotate;
    
    % create figure
    hfig = figure('visible','off');
    
    % plot peak power with error bars
    errorbar(pop_peak_freq.time, pop_peak_freq.mean, n_stds * pop_peak_freq.se,'x-','Color',col(2,:),'LineWidth',line_width);
    
    % annotate the plot
    title(['Effect of ' input_xl_file_name]);
    np_annotate;
    % name the x-axis
    xlabel('Time (mins)','FontSize',font_size);
    
    % save the generate plot
    saveas(hfig,out_file_name,file_extension);
    
    % close figure
    close(hfig);
    
    %% create subplot for area under curve
    subplot(num_params,1,3);
    
    % plot peak power with error bars
    errorbar(pop_auc.time, pop_auc.mean, n_stds * pop_auc.se,'x-','Color',col(3,:),'LineWidth',line_width);
    
    % generate output file name with path
    out_file_name = [out_path '/' input_xl_file_name '_population_auc'];
    
    % annotate the plot
    if enable_normalization
        ylabel_norm = 'Normalized AUC %';
        out_file_name = [out_file_name '_norm'];
    else
        ylabel_wo_norm = 'AUC (\muV^2/Hz*kHz)';
    end
    np_annotate;
    
    % create figure
    hfig = figure('visible','off');
    
    % plot peak power with error bars
    errorbar(pop_auc.time, pop_auc.mean, n_stds * pop_auc.se,'x-','Color',col(3,:),'LineWidth',line_width);
    
    % annotate the plot
    title(['Effect of ' input_xl_file_name]);
    np_annotate;
    % name the x-axis
    xlabel('Time (mins)','FontSize',font_size);
    
    % save the generate plot
    saveas(hfig,out_file_name,file_extension);
    
    % close figure
    close(hfig);
    
    %% save combined Population plot
    annotation('textbox',[.6 .95 .3 .03],'String',...
        ['N (slices) = ' num2str(n_slices) ';  N (animals) = ' num2str(n_animals)],...
        'HorizontalAlignment','center','FontSize',font_size-1);
    
    % name the x-axis
    xlabel('Time (mins)','FontSize',font_size);
    
    % generate output file name with path
    out_file_name = [out_path '/' input_xl_file_name '_population'];
    
    if enable_normalization
        out_file_name = [out_file_name '_norm'];
    end
    % save the generated plot
    saveas(hfig_all,out_file_name,file_extension);
    
    % close figure
    close(hfig_all);
    
    disp ' ';
    disp(['Output plots saved in folder: "' out_path '"']);
    
end

% display only if population data was computed from single trials
if population_stats
    % Print to console the n values for the drug
    disp(['Num of slices: ' num2str(n_slices)]);
    disp(['Num of animals: ' num2str(n_animals)]);
end

disp('Done');

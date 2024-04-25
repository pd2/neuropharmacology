function [status, msg] = np_xlswrite_w_header(outfile,header,data,column,sheet,overwrite)
% function [status, msg] = np_xlswrite_w_header(outfile,header,data,column,sheet,overwrite)
%
% This function writes header and data along the requested column in a 
% specified sheet of an excel file.
%
% Assumptions:
%  - Header and Data are expected to be written along a column not row
%  - Default values: column = 'A'; sheet = 1; overwrite = 0;
%
% Inputs:
% 	outfile - Output excel File name with extension; option: with full path
%   header  - String to be written as header
%   data    - Actual data to be written 
%   column 	- char datatype - specifying the column to write the data
%   sheet   - if int then sheet no; if String then sheet name 
%   overwrite - flag to convey whether to overwrite any data
%
% Outputs:
% 	status  - flag to convey the status of write operation 1: done, 0: fail
%   msg     - string to convey the message alongside the status     
%
% Author:- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 06 Oct  2014 - basic implementation

%% input processing
status = 0;

if nargin < 3
    msg = 'First 3 inputs are mandatory';
    disp('Input undefined');
    return;
end

% assign default values to inputs
if nargin == 3
    column = 'A';
end
if nargin <= 4
    sheet = 1;
end
if nargin <= 5
    overwrite = 0;
end

if exist(outfile,'file') == 2
    
    % check the status of the output excel file
    [file_status, list_of_sheets, format] = xlsfinfo(outfile);

    % Check integrity of the file format
    if ~strcmp(file_status,'')

        % On Windows OS with Excel software, 'format' is the string that 
        % contains a description that MS Excel returns for a file.
        if ~strcmp(format,'xlOpenXMLWorkbook')
            disp('Warning: Using an untested excel file format');
        end

        % Compare input sheet with list of sheets within the given excel
        if isnumeric(sheet) && isscalar(sheet) && isreal(sheet) 
            input_sheet = ['Sheet' num2str(sheet)];
        elseif ischar(sheet)
            input_sheet = sheet;
        end
        
        if ( (overwrite==0) && sum(strcmp(list_of_sheets,input_sheet)) )
            % File present. Print to console and exit
            disp(['Error: Overwrite is 0 but sheet exists in ' outfile]);
            disp ' ';
            status = 0;
            msg = 'User flag "overwrite" is 0 but sheet within file exists';
            return;
        end

    else

        % Improper file - Print to console and exit
        disp(['Error: ' outfile 'is not a valid excel file'])
        disp ' ';
        return;
    end

end


cell_pos = [column '1'];

[status, msg] = xlswrite(outfile,{header}, sheet,cell_pos);

% verify write operation
if status == 0
    % Print to console and exit
    disp(['Error: Write operation failed']);
    disp(msg.message);
    disp ' ';    
    return;
end

cell_pos = [column '2'];

[status, msg] = xlswrite(outfile, data, sheet, cell_pos);

% verify write operation
if status == 0
    % Print to console and exit
    disp(['Error: Write operation failed']);
    disp(msg.message);
    disp ' ';    
    return;
end

end

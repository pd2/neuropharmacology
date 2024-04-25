% scipt np_annotate.m

% Version History:- 
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 02 July 2014 - basic implementation to plot result

% annotation of the plot

% close the axis tightly with data
axis tight;

% enable grid lines
grid on;


% name the y-axis
if enable_normalization
    ylabel(ylabel_norm,'FontSize',font_size);
else
    ylabel(ylabel_wo_norm,'FontSize',font_size);
end

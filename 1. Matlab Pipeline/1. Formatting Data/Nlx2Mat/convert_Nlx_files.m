%% convert session files
% This script converts neuralynx files to a usable matlab format

%% Define data folder manually and add necessary path to working directory

% clear workspace
clear; clc

% designate folder where session-specfic files are located (most important)
datafolder = pwd;
cd(datafolder)

%{
% for probe 21-45
numCSC = [1:64]; % ** If your CSC are numbered, do this and comment below
remCSC = [1,2,3,7,9,10,17,18,19,20,22,23,25,26,28,33,38,41,42,49,53,57,64];
idxRem = dsearchn(numCSC',remCSC');
numCSC(idxRem)=[];
%}

%strCSC = [{'PFC_11'} {'PFC_10'} {'HPC_43'} {'HPC_41'} {'HPC_33'} {'HPC_31'}]; % if your csc are strings, do this and comment above
strCSC = [{'PFC_red'} {'PFC_blue'} {'HPC_black'} {'HPC_blue'} {'HPC_green'} {'HPC_red'}]; % if your csc are strings, do this and comment above
%strCSC = [{'PFC_red'} {'HPC_blue'}]; % if your csc are strings, do this and comment above

%strCSC = [{'PFC_black'} {'HPC_red'}]; % if your csc are strings, do this and comment above
%strCSC = [{'PFC_red'} {'HPC_blue'} {'HPC_red'}]; % if your csc are strings, do this and comment above
%strCSC = [{'HPC_b'} {'PFC_post'}];
%numCSC = [3,10,14]; % ** If your CSC are numbered, do this and comment below
%strCSC = [{'PFC_11'} {'PFC_10'} {'HPC_43'} {'HPC_41'} {'HPC_33'} {'HPC_31'}]; % if your csc are strings, do this and comment above
%strCSC = [{'PFC_red'} {'PFC_blue'} {'HPC_red'} {'HPC_clear'} {'HPC_blue'} {'HPC_black'} {'REF'}]; % if your csc are strings, do this and comment above
%numCSC = [3,10,14]; % ** If your CSC are numbered, do this and comment below
%strCSC = [{'PFC_11'} {'PFC_10'} {'HPC_43'} {'HPC_41'} {'HPC_33'} {'HPC_31'}]; % if your csc are strings, do this and comment above
%strCSC = [{'PFC_red'} {'PFC_blue'} {'HPC_red'} {'HPC_clear'} {'HPC_blue'} {'HPC_black'} {'REF'}]; % if your csc are strings, do this and comment above
%strCSC = [{'PFC_white'} {'PFC_blue'} {'HPC_white'} {'HPC_clear'} {'HPC_blue'} {'HPC_green'}]; % if your csc are strings, do this and comment above

%% Timestamps and events

% load & convert Video-Tracking data
try
    [TimeStamps, ExtractedX, ExtractedY,ExtractedAngle] = Nlx2MatVT(strcat(datafolder,'\VT1.nvt'), [1 1 1 0 0 0], 1, 1, []);
    save('VT1.mat','-regexp', '^(?!(datafolder|strCSC|numCSC)$).');
    clearvars -except datafolder numCSC strCSC
catch
    disp('Could not convert VT data - may be missing')
end

% load & convert Events data
try
    [TimeStamps, EventIDs, TTLs, Extras, EventStrings] = Nlx2MatEV(strcat(datafolder,'\events.nev'), [1 1 1 1 1], 0, 1, [] );
    save('Events.mat','-regexp', '^(?!(datafolder|strCSC|numCSC)$).');
    clearvars -except datafolder numCSC strCSC
catch
    disp('Could not convert Events - may be missing')
end

%% CSC data

if exist('numCSC')
    for i = numCSC
        try
            % define csc name in raw format
            varName  = ['\csc',num2str(i),'.ncs'];
            % define variable name to save it as
            saveName = ['\CSC',num2str(i),'.mat'];
            % convert CSC
            [Timestamps, ChannelNumbers, SampleFrequencies, NumberOfValidSamples,...
                Samples, Header] = Nlx2MatCSC(strcat(datafolder,varName), [1 1 1 1 1], 1, 1, []);
            % save CSC.mat file
            save(strcat(datafolder,saveName), 'Timestamps', 'ChannelNumbers', 'SampleFrequencies', 'NumberOfValidSamples',...
                'Samples', 'Header');
            disp(['Successfully converted and saved CSC',num2str(i)])
            % house keeping
            clearvars -except datafolder i numCSC strCSC
            %disp(['Successfully converted CSC',num2str(i)])
        catch
            disp(['Could not convert CSC',num2str(i)])
        end
    end
elseif exist('strCSC')
    for i = 1:length(strCSC)
        try
            % define csc name in raw format
            varName  = ['\',strCSC{i},'.ncs'];
            % define variable name to save it as
            saveName = ['\',strCSC{i},'.mat'];
            % convert CSC
            [Timestamps, ChannelNumbers, SampleFrequencies, NumberOfValidSamples,...
                Samples, Header] = Nlx2MatCSC(strcat(datafolder,varName), [1 1 1 1 1], 1, 1, []);
            % save CSC.mat file
            save(strcat(datafolder,saveName), 'Timestamps', 'ChannelNumbers', 'SampleFrequencies', 'NumberOfValidSamples',...
                'Samples', 'Header');
            disp(['Successfully converted and saved ',strCSC{i}])
            % house keeping
            clearvars -except datafolder i numCSC strCSC
        catch
            disp(['Could not convert ',strCSC{i}])
        end
    end
end

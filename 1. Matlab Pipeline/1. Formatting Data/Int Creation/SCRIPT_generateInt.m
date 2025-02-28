%% SCRIPT_generateInt
%
% this code is meant for generation of the Int file on T-maze tasks. It
% provides a method to visualize all trials, then tag certain trials
% containing potential artifacts in the behavior that might interfere with
% analysis procedures. This code also saves out a Table.

%% user parameters -- CHANGE ME --
% MAKE SURE THAT YOUR CURRENT FOLDER IS THE DATAFOLDER YOU WANT TO WORK
% WITH
disp('If you have poor tracking data, you will have poor estimations of things. ')
disp('Make sure your current directory is set to your datafolder of interest')
disp('Make sure you view the details of this script to make sure it matches what you want');
disp('Make sure you have an Int_information added to path or in your datafolder of interest')
disp('Please see the details of this code for help with generating Int_information');

% prep
clear;
datafolder   = pwd;
missing_data = 'ignore';
vt_name      = 'VT1.mat';
taskType     = 'DA';
load('Int_information')

% display information
disp(['Int parameters ']); disp(' ')
disp(['missing_data: ',missing_data])
disp(['task type: ',taskType])
    
%% pull in video tracking data
% meat
[x,y,t] = getVTdata(datafolder,missing_data,vt_name);

% number of position samples
numSamples = length(t);

%% define rectangles for all coordinates

% stem
xv_stem = [STM_fld(1)+STM_fld(3) STM_fld(1) STM_fld(1) STM_fld(1)+STM_fld(3) STM_fld(1)+STM_fld(3)];
yv_stem = [STM_fld(2) STM_fld(2) STM_fld(2)+STM_fld(4) STM_fld(2)+STM_fld(4) STM_fld(2)];

% choice point
xv_cp = [CP_fld(1)+CP_fld(3) CP_fld(1) CP_fld(1) CP_fld(1)+CP_fld(3) CP_fld(1)+CP_fld(3)];
yv_cp = [CP_fld(2) CP_fld(2) CP_fld(2)+CP_fld(4) CP_fld(2)+CP_fld(4) CP_fld(2)];

% left reward field
xv_lr = [lRW_fld(1)+lRW_fld(3) lRW_fld(1) lRW_fld(1) lRW_fld(1)+lRW_fld(3) lRW_fld(1)+lRW_fld(3)];
yv_lr = [lRW_fld(2) lRW_fld(2) lRW_fld(2)+lRW_fld(4) lRW_fld(2)+lRW_fld(4) lRW_fld(2)];

% right reward field
xv_rr = [rRW_fld(1)+rRW_fld(3) rRW_fld(1) rRW_fld(1) rRW_fld(1)+rRW_fld(3) rRW_fld(1)+rRW_fld(3)];
yv_rr = [rRW_fld(2) rRW_fld(2) rRW_fld(2)+rRW_fld(4) rRW_fld(2)+rRW_fld(4) lRW_fld(2)];

% startbox
xv_sb = [PED_fld(1)+PED_fld(3) PED_fld(1) PED_fld(1) PED_fld(1)+PED_fld(3) PED_fld(1)+PED_fld(3)];
yv_sb = [PED_fld(2) PED_fld(2) PED_fld(2)+PED_fld(4) PED_fld(2)+PED_fld(4) lRW_fld(2)];

%% identify where each sample in the position data belongs to

% stem 
[in_stem,on_stem] = inpolygon(x,y,xv_stem,yv_stem);

% choice point
[in_cp,on_cp] = inpolygon(x,y,xv_cp,yv_cp);

% left reward field 
[in_lr,on_lr] = inpolygon(x,y,xv_lr,yv_lr);

% right reward field 
[in_rr,on_rr] = inpolygon(x,y,xv_rr,yv_rr);

% startbox 
[in_sb,on_sb] = inpolygon(x,y,xv_sb,yv_sb);

%% loop across data, identify entry and exit points and get timestamps

% intialize some variables
stem_entry     = [];
cp_entry       = []; % is stem exit
goalArm_entry  = []; % is choice point exit
goalZone_entry = []; % is goal arm exit
retArm_entry   = []; % is goal field exit
startBox_entry = []; % is return arm exit
trajectory     = [];

whereWasRat = [];

for i = 2:numSamples-1

    % start with startbox
    if in_sb(i) == 1 && isempty(whereWasRat)
        %was_in_sb = 1;
        whereWasRat = 'sb';
    end

    % when should was_in_sb_now_in_stem be reset? Once the task sequence is
    % accomplished. In other words, once he was in the return arm, but is
    % now in the startbox. note that the isempty line is placed to track
    % the first sample as he couldn't have been in the ret arm and then in
    % sb
    if in_sb(i) == 0 && in_stem(i) == 1 && contains(whereWasRat,'sb')
        % look into the future. The next in_... should be cp
        for k = i:numSamples-1
            % the rat should not be in the startbox, and if so, then this
            % is not the stem entry
            if in_sb(k) > in_cp(k)
                %pause;
                break
            elseif in_cp(k) > in_sb(k)
                % this is the entry timestamp
                stem_entry = [stem_entry t(i)];
                % re-assign startbox as he now was in stem
                whereWasRat = 'stem';
               
                % you want to break out to avoid this loop
                break
            end
        end
    end

    % if they aren't on stem, but they're in choice and were previously in
    % stem
    if in_stem(i) == 0 && in_cp(i) == 1 && contains(whereWasRat,'stem')  
        
        % this is the entry timestamp
        cp_entry = [cp_entry t(i)];
        % re-assign startbox as he now was in stem
        whereWasRat = 'cp';
    end

    % if the rat is not in the cp, is not in the stem, is not in the goal
    % fields, is not in the startbox, but his last position was in the
    % choice point
    if in_stem(i) == 0 && in_cp(i) == 0 && in_lr(i) == 0 && in_rr(i) == 0 && ...
            in_sb(i) == 0 && contains(whereWasRat,'cp')
        % store timestamp
        goalArm_entry = [goalArm_entry t(i)];
        % tracker
        whereWasRat = 'goalArm';
    end  

    % if the rat is in the left reward field or on it, but didn't used to
    % be in the field nor on it, but his next coordinate is in it
    if in_lr(i) == 1 && contains(whereWasRat,'goalArm')
        goalZone_entry = [goalZone_entry t(i)];
        trajectory = [trajectory;'L'];
        % tracker
        whereWasRat = 'goalZone';
    elseif in_rr(i) == 1 && contains(whereWasRat,'goalArm')
        goalZone_entry = [goalZone_entry t(i)];
        trajectory = [trajectory;'R'];
        % tracker
        whereWasRat = 'goalZone';
    end 

    % if the rat is not in the cp, is not in the stem, is not in the goal
    % fields, is not in the startbox, but his last position was in either
    % the left or the right goal fields, and his next coordinate is in no
    % location previously covered, then hes in the return arms
    %idxWayOut = 
    if in_stem(i) == 0 && in_cp(i) == 0 && in_lr(i) == 0 && in_rr(i) == 0 && ...
            in_sb(i) == 0 && contains(whereWasRat,'goalZone')
        retArm_entry = [retArm_entry t(i)];
        % tracker
        whereWasRat = 'retArm';
    end      

    % if the rat is not in the stem
    if in_sb(i) == 1 && contains(whereWasRat,'retArm')
        startBox_entry = [startBox_entry t(i)];
        % tracker
        whereWasRat = 'sb';
    end     

end

% create a method for CA - ie without the startbox


%% create old Int file - ie Int file from 2006-2021
Int_old = [];
% stem entry
Int_old(:,1) = stem_entry;
% cp
Int_old(:,5) = cp_entry;
% goal arm entry
Int_old(:,6) = goalArm_entry;
% goal zone entry
Int_old(:,2) = goalZone_entry;
% return arm entry
Int_old(:,7) = retArm_entry;
% startbox entry
Int_old(:,8) = startBox_entry;

% identify which t-maze task
trajectory = cellstr(trajectory);

% get index of turning behaviors
leftTurns  = find(contains(trajectory,'L'));
rightTurns = find(contains(trajectory,'R'));

% left
Int_old(leftTurns,3) = 1; 

% right
Int_old(rightTurns,3) = 0;
   
% -- create choice accuracy index -- %
if contains(taskType,[{'DA'} {'CA'}])
    
    numtrials = size(Int_old,1);
    for i = 1:numtrials-1
        if Int_old(i,3) == 1 && Int_old(i+1,3) == 0 || Int_old(i,3) == 0 && Int_old(i+1,3) == 1
            Int_old(i+1,4) = 0;
        else
            Int_old(i+1,4) = 1;
        end
    end
    percentCorrect = (((numtrials/2)-(sum(Int_old(:,4))/2))/(numtrials/2))*100;
    
elseif contains(taskType,'DNMP')
    
    numtrials = size(Int_old,1);
    choice_trials = 2:2:numtrials;
    for i = 1:size(choice_trials,2)
        if  Int_old(choice_trials(i),3) == Int_old(choice_trials(i)-1,3)
            Int_old(choice_trials(i),4)   = 1;
            Int_old(choice_trials(i)-1,4) = 1;
        end
    end
    percentCorrect = (((numtrials/2)-(sum(Int_old(:,4))/2))/(numtrials/2))*100;
    
elseif contains(taskType,[{'CD'} {'CDWM'}])
    % 
    %prompt   = ['Enter expected sequence of trials (i.e L R R L L R R L L)'];
    %expected = input(prompt,'s');
    % could also require an input as an excel sheet or matrix or something
    
    error('Code does not support this feature yet - please see ideas in code')
    
end

%% New Int file (2021)
% define some variables for the table
trajNumber = (1:length(stem_entry))';
stemEntry  = stem_entry'; 
cpEntry    = cp_entry';
gaEntry    = goalArm_entry';
gzEntry    = goalZone_entry';
retEntry   = retArm_entry';
sbEntry    = startBox_entry';
trajBinary = Int_old(:,3);

% choice accuracy
accuracy = cell([numtrials 1]);
if contains(taskType,[{'DA'} {'CA'}])
    incor  = find(Int_old(:,4) == 1);
    cor    = find(Int_old(:,4) == 0);
    accuracy(incor) = {'Incorrect'};
    accuracy(cor)   = {'Correct'};
end
accBinary = Int_old(:,4);

%% include a column in our IntTable that estimates time spent in delay
% this does require the user to exclude trials if startbox entry or exit
% cannot be estimated (look at the trial-by-trial tracking data)
delayTemp = (stemEntry(2:end)-sbEntry(1:end-1))./1e6;
delayTime = NaN([size(Int_old,1) 1]);
delayTime(2:end) = delayTemp;

%% CHECK YOUR DATA!!!
[remStem2Choice, remReturn, remDelay, remDoubleTrial] = checkInt(Int_old,x,y,t);

numtrials = size(Int_old,1);
for i = 1:numtrials-1
    if Int_old(i,3) == 1 && Int_old(i+1,3) == 0 || Int_old(i,3) == 0 && Int_old(i+1,3) == 1
        Int_old(i+1,4) = 0;
    else
        Int_old(i+1,4) = 1;
    end
end
percentCorrect = (((numtrials/2)-(sum(Int_old(:,4))/2))/(numtrials/2))*100;

% display progress
C = [];
C = strsplit(datafolder,'\');
X = [];
X = [C{end},' behavioral accuracy = ',num2str(percentCorrect),'%'];
disp(X);

% remove data selected by user
trackingErrorStem = zeros([size(Int_old,1) 1]);
trackingErrorStem(remStem2Choice)=1;
trackingErrorReturn = zeros([size(Int_old,1) 1]);
trackingErrorReturn(remReturn)=1;

% if you try to remove the last trial (i.e. the tracker failed to capture
% the rat entering the startbox on trial 37/37), then you will create a
% false index to remove. There was only 37 trials, it doesn't matter if you
% tag the last trial to remove a delay that doesn't exist
if ~isempty(find(remDelay == size(Int_old,1)))
    remDelay(find(remDelay == size(Int_old,1)))=[]; % remove
end
trackingErrorSB = zeros([size(Int_old,1) 1]);
trackingErrorSB(remDelay+1)=1;

% handle potential double trials
trackingDoubleTrial = zeros([size(Int_old,1) 1]);
trackingDoubleTrial(remDoubleTrial:remDoubleTrial+1)=1;

% create the table
Int = Int_old;
trackingErrorStem = logical(trackingErrorStem);
trackingErrorReturn = logical(trackingErrorReturn);
trackingErrorSBentry = logical(trackingErrorSB);
trackingDoubleTrial = logical(trackingDoubleTrial);

% find anomalies (non existing data)
anomaly = zeros([size(Int,1), 1]);
for i = 1:size(Int,1)
    nanData = [];
    nanData = find(Int(i,[1:2 5:8])==0);
    if isempty(nanData)==0
        anomaly(i)=1;
    end
end
failedTimeStamp = [];
failedTimeStamp = logical(anomaly);

% generate table
IntTable = table(trajNumber,stemEntry,cpEntry,gaEntry,gzEntry,retEntry,sbEntry,trajectory,accuracy,trajBinary,accBinary,delayTime,trackingErrorStem,trackingErrorReturn,trackingErrorSBentry,failedTimeStamp,trackingDoubleTrial);

% save data
question = 'Are you satisfied with the Int file and ready to save? [Y/N] ';
answer   = input(question,'s');

if contains(answer,'Y') | contains(answer,'y')
    cd(datafolder);
    
    % have user define a name
    question    = 'Please enter an Int file name: ';
    IntFileName = input(question,'s');
    
    % save
    save(IntFileName,'Int','IntTable');
end
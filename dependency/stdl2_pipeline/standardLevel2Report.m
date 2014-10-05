%% Visualize the EEG 
visualizeNoisyParameters(EEG.etc.noisyParameters, ...
    [EEG.etc.noisyParameters.name '...after standard level 2 processing'], EEG);

%% Experimental --- in progress
reference = EEG.etc.noisyParameters.reference;
report1 = struct('results', reference.noisyChannelOriginal, ...
                       'chanlocs', reference.channelLocations, ...
                 'chaninfo', reference.channelInformation, ...
                 'refchans', reference.referenceChannels, ...
                 'corthresh', reference.correlationThreshold, ...
                 'name', EEG.etc.noisyParameters.name, ...
                 'msg', 'After high-pass filtering');
report2 = struct('results', reference.noisyChannelResults, ...
                       'chanlocs', reference.channelLocations, ...
                 'chaninfo', reference.channelInformation, ...
                 'refchans', reference.referenceChannels, ...
                  'corthresh', reference.correlationThreshold, ...
                 'name', EEG.etc.noisyParameters.name, ...
                 'msg', 'After referencing');             
compareChannelIndicators(report1, report2);

%% Now look at the difference between the mean and noisy mean


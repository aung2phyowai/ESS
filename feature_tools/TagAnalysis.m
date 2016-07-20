classdef TagAnalysis < Entity
    %tagAnalysis Contains HED tag analysis results
    %   This class contains methods to read events and their associated
    % HED tags from a variety of sources (multiple ESS containers, files,
    % variables) and perform different types of analysis on them.
    
    properties
        eventInstanceCodes = [] % event codes associated with instances of events,
        % this is a cell string with potentially thousands of strings.
        % this is read e.g. directly from event instances files.
        % these could be from multiple studies.
        % the name of te study is appended as '[study name]-[event code]',
        % e.g. ucsd_rsvp-16
        eventInstanceHEDStrings  = {} % HED strings associated with event instances.
        
        eventCodes  = []% event codes, could be from multiple studies.
        % the name of te study is appended as 'study-[event code]'.
        % These are not individual event codes but the unique codes in the study.
        eventHEDStrings = {} % HED strings associated with eventCodes
        eventCounts  = [] % number of instances of the event code
        tags        = {} % unique tags (including all subtags) of  'eventInstanceHEDStrings'
        tagEventCodes  = {} % event codes associatd with 'tag' items.
        tagEventInstanceCounts  = [] % the number of event instances associated with 'tag' items.
        tagNumberOfEventCodes = [] % number of distinct event codes associated with the tag.
                            % events from different studies are always assumed to have different codes. 
        tagSummaryText = {}      % a summary description of tag properties.
        tagEntropy = []       % Shannon Entropy of tag occurances across different event codes.
        tagStudies = {}    % studies in which the tag has an associated event code.
        tagNumberOfStudies = [] % number of studies in which the tag has an associated event code.
        tagTotalInstances = []; % total number of events, from any study, in which the tag is present.
    end
    
    methods        
        function obj = TagAnalysis
            obj = obj@Entity;
            obj = obj.defineAsSubType(mfilename('class'));
        end;
        
        function obj = addFromEventInstanceFile(obj, filename, studyName)
            % obj = addFromEventInstanceFile(obj, filename, studyName)
            % add new events from an event instance file (tab delimited based on ESS Level 1
            % convention)
            
            [newEventInstanceCodes, newEventInstancesLatencies, newEventInstanceHEDStrings] = readEventInstanceFile(filename);
            
            newEventInstanceCodes = strcat([studyName '-'], newEventInstanceCodes);
            
            obj.eventInstanceHEDStrings = [obj.eventInstanceHEDStrings newEventInstanceHEDStrings];
            obj.eventInstanceCodes = [obj.eventInstanceCodes newEventInstanceCodes];
            
            obj = emptyDependentValues(obj);
        end;
        
        function obj = addFromESSContainer(obj, essObjOrFolders)
            % obj = addFromESSContainer(obj, essObjOrFolders)
            % Add event codes from one or more ESS container.
            % essObjOrFolders can be either a cell array of ESS containers (any level)
            % or have strings pointing to ESS containers (currently only level 2 supported as a
            % folder).
            
            if ~iscell(essObjOrFolders)
                essObjOrFolders = {essObjOrFolders};
            end;                                                       

            for j=1:length(essObjOrFolders)
                if ischar(essObjOrFolders{j})
                    essObj = level2Study(essObjOrFolders{j});
                else
                    essObj = essObjOrFolders{j};
                end;
                
                filenames = essObj.getFilename('filetype', 'event');
                shortStudyName = strrep(strrep(essObj.title, '-', ''), ' ', '_'); % remove - and replace spaces with _
                if length(shortStudyName) > 15
                    shortStudyName = shortStudyName(1:15);
                end;
                
                if isempty(shortStudyName)
                    error('Container study name is empty');
                end;
                
                fprintf('Reading event instances from study %s.\n', essObj.title);
                fprintf('File (of %d):', length(filenames))
                for i=1:length(filenames)
                    fprintf(' %d,', i);
                    obj = obj.addFromEventInstanceFile(filenames{i}, shortStudyName);
                end;
                fprintf('\n Finished.\n');
            end;
        end;
        
        function obj = emptyDependentValues(obj)
            obj.eventCodes  = [];
            obj.eventCounts  = [];
            obj.tags        = {};
            obj.tagEventCodes  = {};
            obj.tagEventInstanceCounts  = [];
            obj.tagNumberOfEventCodes = [];
            obj.tagSummaryText = {};
            obj.tagEntropy = [];
            obj.tagTotalInstances = [];
        end
        
        function obj = update(obj)
            % get unique combinations of event code and hed strings
            randomString = getUuid;
            
            combined = cell(length(obj.eventInstanceCodes), 1);
            for i=1:length(obj.eventInstanceCodes)
                combined{i} = [obj.eventInstanceCodes{i} randomString obj.eventInstanceHEDStrings{i}];
            end;
            % combined = strcat(obj.eventInstanceCodes, randomString, obj.eventInstanceHEDStrings); % above was a bit faster.
            
            
            [dummy uniqueStringId originIds] = unique(combined, 'stable');
            obj.eventCodes = obj.eventInstanceCodes(uniqueStringId);
            obj.eventHEDStrings = obj.eventInstanceHEDStrings(uniqueStringId);
            
            %% separate HED strings into all subtags and associated events counts to these tags
            tag = {};
            tagEventCode = {};
            tagEventCount = [];
            for i=1:length(uniqueStringId)
                obj.eventCounts(i) = sum(originIds == i);
                % create all the sub-tags, then see which ones happen in more than one event code
                [uniqueTagForUniqueEvent, uniqueTagCount, originalHedStringId] = hed_tag_count(strrep(strrep(obj.eventHEDStrings(i), '(', ''), ')', ''));
                tag = [tag uniqueTagForUniqueEvent'];
                tagEventCode((length(tagEventCode)+1):length(tag)) = obj.eventCodes(i);
                tagEventCount((length(tagEventCount)+1):length(tag)) = obj.eventCounts(i);
            end;
            
            %% find unique (tag,code) tuples and combine event counts for instances of these tuples to 
            % create unique tags
            randomString = getUuid;
            combined = strcat(tagEventCode, '-', randomString,'-', tag);
            [dummy uniqueId originIds] = unique(combined, 'stable');
            
            for i=1:length(uniqueId)
                aggregateTagEventCount(i) = sum(tagEventCount(originIds == i));
            end
            tag = tag(uniqueId);
            tagEventCode = tagEventCode(uniqueId);
            tagEventCount = aggregateTagEventCount;
            %%
            
            
            [uniqueTag uniqueTagId originTagIds] = unique(tag, 'stable');
            uniqueTagText = {};
            for i=1:length(uniqueTag)
                uniqueTagText{i} = '';[uniqueTag{i} ': '];
                codeId = find(originTagIds == i);
                uniqueTagEventCodes{i} =  tagEventCode(codeId);
                uniqueTagEventInstanceCounts{i} =  tagEventCount(codeId);
                p =  uniqueTagEventInstanceCounts{i} / sum(uniqueTagEventInstanceCounts{i});
                uniqueTagEntropy(i) = -sum(p.*log(p));
                for j=1:length(codeId)
                    uniqueTagText{i} = [uniqueTagText{i} 'code ' tagEventCode{codeId(j)} '(' num2str(tagEventCount(codeId(j))) '),'];
                end
            end;
            
            [uniqueTagEntropy ord] = sort(uniqueTagEntropy, 'descend');
            uniqueTag = uniqueTag(ord);
            uniqueTagEventCodes = uniqueTagEventCodes(ord);
            uniqueTagEventInstanceCounts = uniqueTagEventInstanceCounts(ord);
            uniqueTagText = uniqueTagText(ord);
            
            obj.tags = uniqueTag(:);
            obj.tagEventCodes = uniqueTagEventCodes(:);
            obj.tagEventInstanceCounts = uniqueTagEventInstanceCounts(:);
            obj.tagTotalInstances = cellfun(@sum, obj.tagEventInstanceCounts);
            obj.tagEntropy = uniqueTagEntropy(:);
            obj.tagNumberOfEventCodes = vec(cellfun(@length, uniqueTagEventCodes));
            obj.tagSummaryText = uniqueTagText(:);
            
            obj.tagStudies = cell(length(obj.tagEventCodes), 1);
            for i=1:length(obj.tagEventCodes)
                events = obj.tagEventCodes{i};
                studies = cell(length(events), 1);
                for j=1:length(events)
                     studies{j} = events{j}(1:(find(events{j}== '-', 1) - 1));
                end;
                obj.tagStudies{i} = unique(studies);
            end;
                
            obj.tagNumberOfStudies = vec(cellfun(@length, obj.tagStudies));
            
        end;
        
        function ids = find(obj, varargin)
            ids = find(obj.tagNumberOfStudies > 1);
           
            skiptags = {'Event', 'Event/Description',  'Event/Label', 'Event/Category' 'Participant'  'Attribute'  'Item'  'Attribute/Onset'};
            skipIds = find(ismember(obj.tags, skiptags));
            
            ids = setdiff(ids, skipIds);
            
            % sort by tag entropy
            e = obj.tagEntropy(ids);
            [dumy, ord] = sort(e, 'descend');
            ids = ids(ord);
        end;
        
        function outTable = getTable(obj, ids)
            % outTable = getTable(obj, ids)
            % creates a table from the most useful information using 
            % the subset of tags indicated in 'ids' input variable. 
            outTable = table(obj.tagTotalInstances(ids), obj.tagNumberOfEventCodes(ids),obj.tagNumberOfStudies(ids),...
                obj.tagEntropy(ids), 'RowNames', obj.tags(ids),... 
                'VariableNames', {'Total_Instances', 'Number_of_Codes', 'Number_of_Studies', 'Shannon_Entropy'});
        end;
    end
    
end


classdef TrialGroupAxis < InstanceAxis
    % A group of trials, often selected based on a particular criteria such 
    % as matching a HED tag or having the same event code.This axis represents
    % multiple groups, each group having a "common HED string". All information
    % about single-trials in the groupis placed in items of "groups" property.

    properties
        commonHedStrings % HED string that all the trials in the group match to. Mandatory if trial groups were selected by matching to a single HED string.
        groups % a cell array with multiple TrialAxis, each for a separate trial group. Mandatory.
        descriptions % a cell array of strings containing human-readable descriptions of trial groups. Optional.
    end;
    methods
        function obj =  TrialGroupAxis(varargin)
            obj = obj@InstanceAxis;
            obj = obj.defineAsSubType(mfilename('class'));
            obj = obj.setId;
            
            obj.typeLabel = 'trialGroup';
            obj.perElementProperties = [obj.perElementProperties {'groups' 'commonHedStrings' 'descriptions'}];

            inputOptions = arg_define(varargin, ...
                arg('groups', {}, {},'A cell array with one or more TrialAxis. One for for each trial group. Mandatory.'),...
                arg('commonHedStrings', {}, {},'A cell array with trial groups HED strings. All trials in each group match the corresponding ''common HED string''.', 'type', 'cellstr'),...
                arg('payloads', {}, {},'A cell array with extra information for each ''group''.'),...
                arg('descriptions', {}, {},'A cell array with trial groups HED strings. All trials in each group match the corresponding ''common HED string''.', 'type', 'cellstr')...                            
            );
            
 
            if length(length(inputOptions.groups)) < max(length(length(inputOptions.commonHedStrings)), length(inputOptions.descriptions))
                error('Missing items in ''groups'' variable (at least one other per-item array contains more items)');
            end;
            
            otherfields = {'commonHedStrings' 'descriptions' 'payloads'};
            for i=1:length(otherfields)
                if ~isempty(inputOptions.groups) && ~isempty(inputOptions.(otherfields{i})) && length(inputOptions.groups) ~= length(inputOptions.(otherfields{i}))
                    error('If both "groups" and ''%s'' are provided, they need to have the same length.', otherfields{i});
                end;
            end;
        
            for i=1:length(inputOptions.groups)
                if ~isa(inputOptions.groups{i}, 'TrialAxis')
                    error('All groups must contain objects of class ''TrialAxis''.');
                end;
            end;
                       
            if isempty(inputOptions.descriptions)
                for i=1:length(inputOptions.groups)
                    inputOptions.descriptions{i} = '';
                end;
            end;
            
            if isempty(inputOptions.commonHedStrings)
                for i=1:length(inputOptions.groups)
                    inputOptions.commonHedStrings{i} = '';
                end;
            end;
            
            % place empty elements for instances, code and hed strings.
            if isempty(inputOptions.payloads)
                inputOptions.payloads = cell(length(inputOptions.groups), 1);
            end;   
            
            obj.commonHedStrings = inputOptions.commonHedStrings(:);
            obj.groups = inputOptions.groups(:);
            obj.descriptions = inputOptions.descriptions(:);
            obj.payloads = inputOptions.payloads(:);
        end      
        
        function number = getGroupNumberOfTrials(obj, groupNumber)
            number = length(obj.groups{groupNumber});
        end;
        
        function matchVector = getHEDMatch(obj, queryHEDString)
            % matchVector = getHEDMatch(obj, queryHEDString)

            [uniqueHedStrings, dummy, ids]= unique(obj.commonHedStrings);
            matchVector = false(length(obj.commonHedStrings), 1);
            for i=1:length(uniqueHedStrings)
                events.usertags = uniqueHedStrings{i};
                matchVector(ids == i) = findTagMatchEvents(events, queryHEDString);
            end;

        end;
        
        function idMask = parseRange(obj, rangeCell)
            switch  rangeCell{1}               
                case 'match' % to be used as {'trialGroup' 'match' '[HED string]'}
                    idMask = getHEDMatch(obj, rangeCell{2});
                otherwise
                    error('Range string not recognized');
            end
        end;
    end;
end
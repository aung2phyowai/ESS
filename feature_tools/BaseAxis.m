classdef BaseAxis < Entity
    properties
        typeLabel % quantity represented by the axis, e.g. 'time', 'channel', 'trial'. 
                  % these are automatically set by child objects and should not be changed by
                  % extrenal scripts.
        customLabel % for distinguishing axes with the same type, e.g. two 'channel' axis, 
                      % instead can use e.g. 'toChannel', 'fromChannel'
                      
        perElementProperties = {};% a cell array of strings with the names of properties in
        % the axis that are vectors with each element of
        % the vector associatd with one axis element.
        % For example, "times" is a vector of size N
        % with each element associated with an axis of
        % lenght N elements (N time points).
        % In contrast, an axis can properties, e.g.
        % "typeLabel that are associated with the whole
        % axis and not its individual elements.
    end;
    properties %(Access = protected)
        intersectionPerItemProperties = {}
        % when calculating axis intersection with another axis,
        % items for which these per-item properties are exactly
        % the same will be selected.
        intersectionEqualityProperties = {'typeLabel' 'customLabel'} 
        % when calculating axis intersection with another axis,
        % these properties have to exactly the same, or there is
        % is no intersection (it is empty).
    end;
   % methods (Static)
        % length % Returns the number of elements in the axis
        %    parseRange % Parses a given domain-specific rangeexpression into a slice or index sequence
        %     selectRange % Returns a sub-range of the axes for some slice or index sequence; slices produce a view.
        %     assign_range % Assigns contents of some axis to an indexed sub-range of the axis in-place
        %     concat % Returns a new axis object that is the concatenation of all axes in the argument list
   % end
    methods
        function obj = BaseAxis
            obj = obj@Entity;
            obj = obj.defineAsSubType(mfilename('class'));
        end;
        
        function l = length(obj)
            if isempty(obj.perElementProperties)
                l = 0;
            else
                l = size(obj.(obj.perElementProperties{1}), 1);
            end;
        end
        
        function [sref, varargout] = subsref(obj, s)
            switch s(1).type
                case '.'
                    [sref, varargout{1:(nargout-1)}] = builtin('subsref',obj,s);
                case '()'
                    for j=1:length(s) % to handle t(1:5).times case, t  = Time
                        if j == 1
                            sref = obj;
                            
                            for i=1:length(obj.perElementProperties) % subsleect all per-element axis properties.
                                % for per-item properties with more than
                                % one singleton dimension, e.g. 3D
                                % position, slicing should only apply 
                                % on the first dimension.
                                subStruct = s(1);
                                for k=2:ndims(obj.(obj.perElementProperties{i}))
                                    subStruct.subs{k} = ':';
                                end;
                                    
                                sref.(obj.perElementProperties{i}) = builtin('subsref', obj.(obj.perElementProperties{i}), subStruct);
                            end;
                            
                            sref = sref.setAsNewlyCreated;
                        else
                            [sref, varargout{1:(nargout-1)}] = builtin('subsref',sref,s(j));
                        end;
                    end;
                    return
                case '{}'
                    error('MYDataClass:subsref',...
                        'Not a supported subscripted reference')
            end
        end;
        
        function out = index(obj, varargin)
            out = subsref(obj, substruct('()', varargin));
        end;
        
        function valid = isValid(obj)
            valid = true;
            if isempty(obj.perElementProperties)
                fprintf('Axis of type "%s" does not have any per-item properties. Each axis should at least have one.\n', obj.typeLabel);
                valid = false;
            end;           
            
            firstDimensionLength = [];
            for i=1:length(obj.perElementProperties) % make sure all per-tem properties have the same length in the first dimension 
                firstDimensionLength = size(obj.(obj.perElementProperties{i}), 1);
                if firstDimensionLength ~= obj.length
                    valid = false;
                    fprintf('Per-item property "%s" of axis of type "%s" has a different first dimension that axis length.\n', obj.perElementProperties{i}, obj.typeLabel);
                end;
            end;
        end;
        
        function ids = parseRange(obj, rangeCell)
            % this function is overriden in child classes. 
        end;
        
        function [intersectionAxis, idObj, idOthrObj]= intersect(obj, otherAxisObj)
            intersectionAxis = [];
            idObj = [];
            idOthrObj = [];
            for i = 1:length(obj.intersectionEqualityProperties)
                if ~isequal(obj.(obj.intersectionEqualityProperties{i}), otherAxisObj.(obj.intersectionEqualityProperties{i}))
                    return;
                end;
            end;
            
            idObj = 1:length(obj);
            idOthrObj = 1:length(otherAxisObj);
            for i=1:length(obj.intersectionPerItemProperties)
                warning off 'MATLAB:INTERSECT:RowsFlagIgnored'
                [dummy ia ib] = intersect(obj.(obj.intersectionPerItemProperties{i}), otherAxisObj.(obj.intersectionPerItemProperties{i}), 'rows', 'stable');
                warning on 'MATLAB:INTERSECT:RowsFlagIgnored'
                idObj = intersect(idObj, ia);
                idOthrObj = intersect(idOthrObj, ib);
            end;
            
            intersectionAxis = obj.index(idObj);
            
            % place appropriate nan, etc values for properties that differ across axes and have not
            % been used in intersection ovrlap calculation
            otherPerItemProperties = setdiff(obj.perElementProperties, obj.intersectionPerItemProperties);
            for i = 1:length(otherPerItemProperties)
                for j=1:length(idObj)
                    if ~isequal(obj.(otherPerItemProperties{i})(idObj(j)), otherAxisObj.(otherPerItemProperties{i})(idOthrObj(j)))
                        switch class(intersectionAxis.(otherPerItemProperties{i})(j,:))
                            case 'char'
                                intersectionAxis.(otherPerItemProperties{i})(j) = '';
                            case 'cell'
                                intersectionAxis.(otherPerItemProperties{i})(j,:) = {};
                            case {'single' 'double' 'float' 'int' 'int32' 'int16' 'int8', 'uint32' 'uint16' 'uint8'}
                                intersectionAxis.(otherPerItemProperties{i})(j,:) = nan(1, size(intersectionAxis.(otherPerItemProperties{i})(j), 2));
                            case 'struct'
                                intersectionAxis.(otherPerItemProperties{i})(j,:) = struct;
                        end;
                    end;
                end;
            end;
            
            intersectionAxis = setAsNewlyCreated(intersectionAxis);
            intersectionAxis = intersectionAxis.setId;
            if ~isequal(obj.description, otherAxisObj.description)
                intersectionAxis.description = '';
            end;
            
            if ~isequal(obj.custom, otherAxisObj.custom)
                intersectionAxis.custom = '';
            end;
            
        end;
    end
end
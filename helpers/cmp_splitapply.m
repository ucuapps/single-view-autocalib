function varargout = cmp_splitapply(fun,varargin)
% SPLITAPPLY Split data into groups and apply function
%   Y = SPLITAPPLY(FUN,X,G) splits the variable X into groups specified by G 
%   and applies the function FUN to each group. SPLITAPPLY returns Y as a 
%   column vector where each row contains the output from FUN for each group. 
%   Specify G as a vector of positive integers. You can use FINDGROUPS 
%   to create G. If G contains NaN values, SPLITAPPLY discards the 
%   corresponding values in X.
%
%   Y = SPLITAPPLY(FUN,X1,X2,...,G) splits variables X1,X2,... into groups 
%   specified by G and applies FUN to each group. SPLITAPPLY calls FUN once per 
%   group, with X1,X2,... as the input arguments to FUN.
%
%   [Y1,Y2,...] = SPLITAPPLY(FUN,...) splits variables into groups and applies FUN 
%   to each group. FUN returns multiple output arguments. FUN can return output 
%   arguments that belong to different classes, but the class of each output must 
%   be the same each time FUN is called. You can use this syntax with any of the 
%   input arguments of the previous syntaxes. The number of output arguments need 
%   not equal the number of input data variables.
%
%   Examples:
%      % Load patients data.
%      % List Height, Weight, Gender, and Smoker variables for patients.
%      load patients;
%      whos Height Weight Gender Smoker
%      
%      % Find groups of patients by gender and status as a smoker.
%      % Make a table that lists the four group identifiers.
%      [G,gender,smoker] = findgroups(Gender,Smoker);
%      results = table(gender,smoker)
%
%      % Split Weight into groups. Calculate mean weights for the groups
%      % of patients.
%      results.meanWeight = splitapply(@mean,Weight,G)
% 
%      % Find the average BMI by gender and status as a smoker.
%      meanBMIFcn = @(h,w)mean((w ./ (h.^2)) * 703);
%      results.meanBMI = splitapply(meanBMIFcn,Height,Weight,G)
%
%   See also FINDGROUPS, UNIQUE, VARFUN, ROWFUN

% Copyright 2015 MathWorks, Inc.



% Check number of inputs
narginchk(3,inf);


gnums = varargin{end};
varargin(end) = [];

% Check Function handle
if ~isa(fun,'function_handle')
    error(message('MATLAB:splitapply:InvalidFunction'));
end

% Check indices
if isempty(gnums) || ~isnumeric(gnums) || ~isvector(gnums) || ...
        any(gnums <= 0) || issparse(gnums)
    error(message('MATLAB:splitapply:InvalidGroupNums'));
end

% Drop leading singleton dimensions to find dimension to split on
[gnums, shiftby] = shiftdim(gnums);
gsize = length( gnums );
gdim = shiftby + 1;

% Ensure that indices are sorted (for transparent accumarray behavior)
[gnums, sgnums] = sort( gnums );

% Account for NaN Groups
ngroups = max(gnums);
if isnan(ngroups) %for the case of gnums being all NaN
    emptyGroup = 1;
else
    emptyGroup = ngroups+1;
end

% Filter out empty group numbers
emptyIdx = emptyGroups(gnums);
sgnums(emptyIdx,:) = emptyGroup;
gnums(emptyIdx,:) = emptyGroup;

% Check for non-integer group numbers (after filtering out the data) 
if any(floor(gnums) ~= gnums) || ~isreal(gnums)
    error(message('MATLAB:splitapply:InvalidGroupNums'));
end

% Check data
for argnumber = 1:length(varargin)
    argsize = size(varargin{argnumber},gdim);
    if isscalar(gnums) || isequal( gsize, argsize )
        continue; % Sizes match
    end
    
    % Different error messages depending on grouping vector orientation
    if gdim == 1 %column vector gnums
        error(message('MATLAB:splitapply:RowMismatch', gsize, argnumber, argsize));
    elseif gdim == 2 %row vector gnums
        error(message('MATLAB:splitapply:ColumnMismatch', gsize, argnumber,argsize));
    end
end


% Check for non-continuous group numbers
% When sorted, valid group number vector will start at 1, and the numbers
% will not differ by more than 1
gdiffed = diff(gnums);
if ~isempty(gnums) && ((gnums(1) ~= 1) || ~all(gdiffed== 1 | gdiffed==0))
    error(message('MATLAB:splitapply:MissingGroupNums'));
end 

dataVars = {};
for argnumber = 1:length(varargin)
    expandedVars = expandVariables(varargin{argnumber});
    dataVars(end+1:end+size(expandedVars,2)) = expandedVars;
end

if isscalar(gnums)
   % Vector of group numbers is a scalar,  Use the first non-singleton
   % dimension as the dimension to split data on.
   sz = size(dataVars{1});
   gdim = find(sz == 1,1,'first');
   if isempty(gdim)
       gdim = 1;
   end
end

splitData = localsplit(dataVars,gnums,sgnums,gdim);

if any(emptyIdx)
    splitData(emptyGroup,:) = [];
end

varargout = localapply(fun,splitData,gdim,nargout);

% Clean up NaN Groups
%if any(emptyIdx)
%    for ii = 1:length(varargout)
%        varargout{ii}(emptyGroup) = [];
%    end
%end

end

function varRows = getVarRows(datavar,i,gdim)
if isscalar(datavar)
    varRows = datavar;
elseif isa(datavar,'table') % faster than calling istable
    varRows = datavar(i,:);
elseif ismatrix(datavar) && gdim == 1
    varRows = datavar(i,:);
elseif ismatrix(datavar) && gdim == 2
    varRows = datavar(:,i);
else
    % Each var could have any number of dims, no way of knowing,
    % except how many rows they have.  So just treat them as 2D to get
    % the necessary rows, and then reshape to their original dims.
    indexVar = repmat({':'}, 1, ndims(datavar));
    indexVar{gdim} = i;
    varRows = datavar(indexVar{:});
end
end

function out = localsplit(datavars,gnums,sgnums,gdim)
if isscalar(gnums)
    out = datavars; % all datvariables are the observations if gnums is scalar
else
    gmax = gnums(end);
    for i = 1:length(datavars)
        groupNums = accumarray(gnums,sgnums,[gmax,1],@(ii){ii});
        if i==1
            out = cell(length(groupNums),length(datavars));
        end
        
        for j=1:length(groupNums)
            out{j,i} = getVarRows(datavars{i},groupNums{j},gdim);
        end
        
    end
end
end


function finalOut = localapply(fun,dataVars,gdim,nout)
    if verLessThan('matlab','9.2')
        import_str= 'matlab.internal.tableUtils.ordinalString';     
    else
        import_str = 'matlab.internal.datatypes.ordinalString';
    end
    import(import_str);
        % Call function passing parameters
    [numGroups,numVars] = size(dataVars);
    funOut = cell(numGroups,nout);
    if (gdim > 1)
        funOut = funOut';
    end
    
    for curGroup = 1:numGroups
        try
            % Invoke the function based on the number of output arguments
            if nout > 0
                if gdim == 1
                    [funOut{curGroup,:}] = fun(dataVars{curGroup,:});
                else
                    [funOut{:,curGroup}] = fun(dataVars{curGroup,:});
                end
            else
                clear ans;
                fun(dataVars{curGroup,:});
                
                % did the call to 'fun' above output to ans?  
                % If so pass it through.
                if exist('ans','var')
                    funOut{1} = ans; %#ok<NOANS>
                    nout = 1;
                end
            end
        catch ME
            funStr = func2str(fun);
            throwAsCaller(MException(message('MATLAB:splitapply:FunFailed', funStr, ordinalString(curGroup), ME.message)));
        end

        if nout > 0
            for curVar=1:nout
                if gdim == 1
                    var = funOut{curGroup,curVar};
                else
                    var = funOut{curVar,curGroup};
                end

                if isscalar(var) || (size(var,gdim) == 1) 
                    % Output is Uniform
                    continue;
                end
                
                % Construct a suggested correction to be included in the
                % error message
                funStr = func2str(fun);
                if strcmp(funStr(1), '@') % anonymous function
                    funTokens = regexp(funStr, '(@\([^\(\)]*\))(.*)', 'tokens', 'once');
                    funSuggest = [funTokens{1}, '{',funTokens{2},'}'];
                else % simple function handle
                    funArgs = strjoin( strcat('x', strsplit(int2str(1:numVars)) ), ',');
                    funSuggest = ['@(',funArgs,'){',funStr,'(',funArgs,')}'];
                end
                
                throwAsCaller(MException(message('MATLAB:splitapply:OutputNotUniform', funStr, ordinalString(curGroup), funSuggest)));
            end
        end
    end
    
    finalOut = cell(1,nout);
    for curVar = 1:nout 
        if gdim == 1
            finalOut{curVar} = vertcat(funOut{:,curVar}); 
        else
            finalOut{curVar} = horzcat(funOut{curVar,:}); 
        end
    end
end

function emptyIdx = emptyGroups(gnums)
    emptyIdx = isnan(gnums);
end

function out = expandVariables(inVar)
    if istable(inVar)
        out = table2cell(varfun(@(x){x}, inVar));
    else
        out = {inVar};
    end
end

function [scen_para, scen_explanation] = read_scen_para(file_dir, scenario, scen_para)
    file = fopen(file_dir, 'r');
    lin = fgetl(file); %读取第一行的内容，忽略

    % Read file line by line and parse the data of scen_para
    lin = fgetl(file);
    while ischar(lin)  
        p1 = regexp(lin,'=');                           % Check if there is an equal sign
        if ~isempty(p1)                                 % If there is a "=" sign
            p2 = regexp(lin(1:p1(1)-1),'%', 'once');    % Check if the line is commented
            if isempty(p2)                              % If the line is not commented
                name = regexp( lin(1:p1(1)-1) ,'[A-Za-z0-9_]+','match');           % Read name
                if ~isempty(name)                       % If there is a name
                    p0 = regexp(name{1},'PL_', 'once');
                    if isempty(p0) 
                        tmp = lin(p1(1)+1:end);     % Copy line
                        p2 = regexp(tmp,'%');       % Check for comment
                        if ~isempty( p2 )
                            tmp = tmp(1:p2(1)-1 );      % Remove commented part
                        end
                        p3 = regexp( tmp,'[0-9.-]+','match');         % Check for numbers
                        if ~isempty( p3 )
                            p3 = regexp( tmp,'[0-9Eeji.+-]+','match'); % Include exponenetials and comlex numbers
                            if length(p3) == 8  % 严格校验，必须是8个值
                                % 此处是LEO场景大尺度参数矩阵&标准差矩阵赋值
%                                 p3 = reshape(p3, 8,2)';
                                eval( [ 'scen_para.',char(name),' = cell2mat(p3);']);
                            else
                                eval( [ 'scen_para.',char(name),' = str2double( p3 );']);
                            end 
                        else
                            p3 = regexp( tmp,'[A-Za-z]+' ,'match');   % Check for strings
                            if ~isempty( p3 )
                                scen_para.( name{1} ) = p3{1};
                            else
                                error('WrongInput',...
                                    ['Could not understand value of "',name{1},'" in file "',scenario,'.conf"']);
                            end
                        end  
                   else                      % If it is not a plpar
                        PLname = name{1}(4:end);        % Parse the name of the field in PLPAR
                        if strcmp(PLname,'model')       % If it is the model name
                            p3 = regexp( lin(p1(1)+1:end)  ,'[A-Za-z0-9_]+','match');
                            if isempty( p3 )            % If no value is given or wrongly formatted
                                error('WrongInput',...
                                    ['Could not understand value of "',name{1},'" in file "',scenario,'.conf"']);
                            else
                                scen_para.PL_model = p3{1};      % Set the model name
                            end
                        else
                            p4 = regexp( lin, '%' );    % Determine the beginning of the comment
                            if isempty( p4 )            % If there is no comment
                                p4 = numel(lin);        % Set the position to endline
                            end
                            p3 = regexp( lin(p1(1)+1:p4)  ,'[0-9e.-]+','match');
                            scen_para.( PLname ) = str2double(p3);
                        end
                    end  
                end
            end
            p_explanation = regexp(lin,'%', 'once');
            if ~isempty(p_explanation)
                explanation = {lin(p_explanation(1)+1:end)};
                assignin('base','explanation', explanation);
                if contains(name, 'PL_') && ~contains(name, 'PL_model')
                    name = name{1}(4:end);                
                end
                eval( [ 'scen_explanation.', char(name),'= explanation(1);']);
                eval( [ 'scen_name.', char(name),'= explanation{1};']);
            end
        end
        lin = fgetl(file);          % Get next line
    end
    fclose(file);
end


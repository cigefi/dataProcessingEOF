% Function dataProcessing
%
% Prototype: dataProcessing(dirName,var2Read,yearZero,yearN)
%            dataProcessing(dirName,var2Read)
%            dataProcessing(dirName)
%
% dirName = Path of the directory that contents the files 
% var2Read (Recommended)= Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [] = dataProcessingEOF(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessingEOF: dirName is a required input')
    end
    if nargin < 2 % Validates if the var2Read param is received
        temp = java.lang.String(dirName).split('/');
        temp = temp(end).split('_');
        var2Read = char(temp(1)); % Default value is taken from the path
    end
    if nargin < 3 % Validates if the yearZero param is received
        yearZero = 0; % Default value
    end
    if nargin < 4 % Validates if the yearN param is received
        yearN = 0; % Default value
    end
    
    if(yearZero > yearN) % Validates if the yearZero is higher than yearN
        yearTemp = yearZero;
        yearZero = yearN;
        yearN = yearTemp;
    end
    dirData = dir(dirName);  % Get the data for the current directory
    months = [31,28,31,30,31,30,31,31,30,31,30,31]; % Reference to the number of days per month
    monthsName = {'January','February','March','April','May','June','July','August','September','October','November','December'};
    path = java.lang.String(dirName);
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    %newName = strcat('[CIGEFI] EOF ',num2str(yearZero),'-'+num2str(yearN)+'.nc');
    newName = strcat('[CIGEFI] EOF.nc');
    newFile = char(path.concat(newName));
    fileConf = 0;
    
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            try
                yearC = str2num(fileT.substring(fileT.length-7,fileT.lastIndexOf('.')));
                if(yearZero>0)
                    if(yearC<yearZero) 
                        continue;
                     end
                end
                if(yearN>0)
                    if(yearC>yearN)
                        continue;
                    end
                end
                if(yearC > 0)
                    if fileConf == 0
                        configure_netcdf(fileT,newFile,yearC,var2Read);
                        fileConf = 1;
                    end
                    % Subrutine to writte the data in new Netcdf file
                    writeFile(fileT,var2Read,yearC,months,monthsName,newFile);
                end
            catch
                continue;
            end
        else
            if isequal(dirData(f).isdir,1)
                  newPath = char(path.concat(dirData(f).name));
                if nargin < 2 % Validates if the var2Read param is received
                    dataProcessingEOF(newPath);
                elseif nargin < 3 % Validates if the yearZero param is received
                    dataProcessingEOF(newPath,var2Read);
                elseif nargin < 4 % Validates if the yearN param is received
                    dataProcessingEOF(newPath,var2Read,yearZero)
                else
                    dataProcessingEOF(newPath,var2Read,yearZero,yearN)
                end
            end
        end
    end
end

function configure_netcdf(fileT,newFile,yearC,var2Read)
    nc_create_empty(newFile,'netcdf4');

    % Adding file dimensions
    nc_add_dimension(newFile,'latitude',0);
    nc_add_dimension(newFile,'longitude',0);
%     nc_add_dimension(newFile,'latitude',length(latDataSet));
%     nc_add_dimension(newFile,'longitude',length(lonDataSet));
    nc_add_dimension(newFile,'time',0); % 0 means UNLIMITED dimension

    % Global params
    nc_attput(newFile,nc_global,'parent_experiment',nc_attget(char(fileT),nc_global,'parent_experiment'));
    nc_attput(newFile,nc_global,'parent_experiment_id',nc_attget(char(fileT),nc_global,'parent_experiment_id'));
    nc_attput(newFile,nc_global,'parent_experiment_rip',nc_attget(char(fileT),nc_global,'parent_experiment_rip'));
    nc_attput(newFile,nc_global,'institution',nc_attget(char(fileT),nc_global,'institution'));
    nc_attput(newFile,nc_global,'realm',nc_attget(char(fileT),nc_global,'realm'));
    nc_attput(newFile,nc_global,'modeling_realm',nc_attget(char(fileT),nc_global,'modeling_realm'));
    nc_attput(newFile,nc_global,'version',nc_attget(char(fileT),nc_global,'version'));
    nc_attput(newFile,nc_global,'downscalingModel',nc_attget(char(fileT),nc_global,'downscalingModel'));
    nc_attput(newFile,nc_global,'experiment_id',nc_attget(char(fileT),nc_global,'experiment_id'));
    nc_attput(newFile,nc_global,'frequency','monthly');
    nc_attput(newFile,nc_global,'Year',num2str(yearC)); % nc_attput(FILE,VARIABLE,TITLE,CONTENT)
    nc_attput(newFile,nc_global,'reinterpreted_institution','CIGEFI - Universidad de Costa Rica');
    nc_attput(newFile,nc_global,'reinterpreted_date',char(datetime('today')));
    nc_attput(newFile,nc_global,'reinterpreted_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

    % Adding file variables
    monthlyData.Name = var2Read;
    monthlyData.Datatype = 'single';
    monthlyData.Dimension = {'time','latitude', 'longitude'};
    nc_addvar(newFile,monthlyData);

    timeData.Name = 'time';
    timeData.Dimension = {'time'};
    nc_addvar(newFile,timeData);

    latData.Name = 'latitude';
    latData.Dimension = {'latitude'};
    nc_addvar(newFile,latData);

    lonData.Name = 'longitude';
    lonData.Dimension = {'longitude'};
    nc_addvar(newFile,lonData);
end

function [] = writeFile(fileT,var2Read,yearC,months,monthsName,newFile)
    maskDataSet = nc_varget('lsmask.oisst.v2.nc','lsmask');
    
    % Catching data from original file
    latDataSet = nc_varget(char(fileT),'latitude'); 
    lonDataSet = nc_varget(char(fileT),'longitude');
    timeDataSet = nc_varget(char(fileT),var2Read);
    
    %h = waitbar(0,'Initializing data writing ...');
    for m=1:1:length(months)
%         if(m==1) % New file configuration
%             % Writing the data into file
%             nc_varput(newFile,'latitude',latDataSet);
%             nc_varput(newFile,'longitude',lonDataSet);
%         end
        k = 1;
        for i=1:1:length(maskDataSet(1,:,1))
            for j=1:1:length(maskDataSet(1,1,:))
                if maskDataSet(1,i,j) == 1
                    eof_mat(m,k,j) = timeDataSet(m,i,j);
                    k = k + 1;
                end
            end
        end
        %lat = [];
%         for i=1:1:length(latDataSet)
%             temp_row = timeDataSet(~isnan(timeDataSet(m,i,:)));
%             if temp_row > 0
%                eof_mat(m,k,:) = temp_row; 
%             end
% %             l = 1;
% %             without_nan = 0;
% %             for j=1:1:length(lonDataSet)
% %                 if isnan(timeDataSet(m,i,j)) == 0
% %                     eof_mat(m,k,l) = timeDataSet(m,i,j);
% %                     l = l + 1;
% %                     without_nan = 1;
% %                 end
% %             end
% %             if without_nan > 0
% %                 %lat(k) = latDataSet(i);
% %                 if m == 1
% %                     nc_varput(newFile,'latitude',latDataSet(i));
% %                 end
% %                 k = k +1;
% % %             else
% % %                 latDataSet(i) = [];
% %             end
%         end
        nc_varput(newFile,var2Read,eof_mat(m,:,:));
        disp(strcat('Data saved:  ',monthsName(m),' - ',num2str(yearC),' - ',num2str(1)));
    end
    % Writing the data into file
    %nc_varput(newFile,'latitude',lat);
    %nc_varput(newFile,var2Read,eof_mat);
    %close(h);
end

% Function dataProcessingEOF
%
% Prototype: dataProcessingEOF(dirName,var2Read,yearZero,yearN)
%            dataProcessingEOF(dirName,var2Read)
%            dataProcessingEOF(dirName)
%
% dirName = Path of the directory that contents the files 
% var2Read (Recommended)= Variable to be read (use 'ncdump' to check variable names)
% yearZero (Optional) = Lower year of the data to be read
% yearN (Optional) = Higher year of the data to be read
function [eof_mat] = dataProcessingEOF(dirName,var2Read,yearZero,yearN)
    if nargin < 1
        error('dataProcessingEOF: dirName is a required input')
    end
    if nargin < 2 % Validates if the var2Read param is received
        temp = java.lang.String(char(dirName(1))).split('/');
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
    eof_mat = [];
    dirData = dir(char(dirName(1)));
    months = [31,28,31,30,31,30,31,31,30,31,30,31]; % Reference to the number of days per month
    monthsName = {'January','February','March','April','May','June','July','August','September','October','November','December'};
    path = java.lang.String(dirName(1));
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    if(length(dirName)>1)
        newName = dirName(2);
    else
        newName = strcat(char(path),'[CIGEFI] EOF.nc');
    end
    %newName = strcat('[CIGEFI] EOF ',num2str(yearZero),'-'+num2str(yearN)+'.nc');
    %newName = strcat('[CIGEFI] EOF.nc');
    %newFile = char(path.concat(newName));
    newFile = newName;

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
                    if(exist(char(newName),'file')==0)
                        configure_netcdf(fileT,char(newFile),yearC,var2Read);
                    else
                        eof_mat = nc_varget(char(newFile),var2Read);
                    end
                    % Subrutine to writte the data in new Netcdf file
                    eof_mat = writeFile(fileT,var2Read,yearC,months,monthsName,newFile,eof_mat);
                end
            catch
                continue;
            end
        else
            if isequal(dirData(f).isdir,1)
                  newPath = char(path.concat(dirData(f).name));
                if nargin < 2 % Validates if the var2Read param is received
                    eof_mat = cat(1,eof_mat,dataProcessingEOF({[char(newPath)],[char(newName)]}));
                elseif nargin < 3 % Validates if the yearZero param is received
                   eof_mat = cat(1,eof_mat,dataProcessingEOF({newPath,newName},var2Read));
                elseif nargin < 4 % Validates if the yearN param is received
                   eof_mat = cat(1,eof_mat,dataProcessingEOF({newPath,newName},var2Read,yearZero));
                else
                    eof_mat = cat(1,eof_mat,dataProcessingEOF({newPath,newName},var2Read,yearZero,yearN));
                end
            end
        end
    end
    if(length(dirName)==1 && isempty(eof_mat)<1)
        nc_varput(char(newFile),var2Read,eof_mat); % Check 'var2Read'
    end
end

function configure_netcdf(fileT,newFile,yearC,var2Read)
    nc_create_empty(newFile,'netcdf4');

    % Adding file dimensions
    nc_add_dimension(newFile,'lat',601);
    nc_add_dimension(newFile,'lon',1150);
    % nc_add_dimension(newFile,'fn',0);
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
    nc_attput(newFile,nc_global,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
    nc_attput(newFile,nc_global,'data_analysis_date',char(datetime('today')));
    nc_attput(newFile,nc_global,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

    % Adding file variables
%     fNameData.Name = 'names';
%     fNameData.Datatype = 'string';
%     fNameData.Dimension = {'fn'};
%     nc_addvar(newFile,fNameData);
    
    monthlyData.Name = var2Read;
    monthlyData.Datatype = 'single';
    monthlyData.Dimension = {'time','lat', 'lon'};
    nc_addvar(newFile,monthlyData);

    timeData.Name = 'time';
    timeData.Dimension = {'time'};
    nc_addvar(newFile,timeData);

    latData.Name = 'lat';
    latData.Dimension = {'lat'};
    nc_addvar(newFile,latData);

    lonData.Name = 'lon';
    lonData.Dimension = {'lon'};
    nc_addvar(newFile,lonData);
end

function [eof_mat] = writeFile(fileT,var2Read,yearC,months,monthsName,newFile,eof_mat)
    maskDataSet = nc_varget('lsmask.oisst.v2.nc','lsmask');
    
    % Catching data from original file
    timeDataSet = nc_varget(char(fileT),var2Read);
    for m=1:1:length(months)
        k = 1;
        for i=1:1:length(maskDataSet(1,:,1))
            l = 1;
            for j=1:1:length(maskDataSet(1,1,:))
                if (maskDataSet(1,i,j) == 1 && isnan(timeDataSet(m,i,j)) == 0)
                    month(k,l) = timeDataSet(m,i,j);%#ok<AGROW>
                    l = l + 1;
                end
            end
            if l > 1
                k = k +1; 
            end
        end
        eof_mat = cat(1,eof_mat,reshape(month(month~=0),1,601,[]));
        disp(strcat('Data saved:  ',monthsName(m),' - ',num2str(yearC)));
    end
end
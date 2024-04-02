% DV_CheckAndCreateFolder: Check if a folder exists, and if not, create it.
%--------------------------------------------------------------------------
% DESCRIPTION:
%   This function checks if a folder exists, and if not, it creates it. It
%   also displays a message indicating whether the folder was created
%   successfully or if it already exists. Additionally, it changes the
%   current directory to the specified directory if it exists.
%
% INPUTS:
%   - folderName: Name of the folder to check or create.
%   - directoryToGo: (Optional) Directory to change into if it exists.
%
% OUTPUTS:
%   Displays a message indicating the status of the folder creation process.
%--------------------------------------------------------------------------

function DV_CheckAndCreateFolder(folderName, directoryToGo, mainFolder)

    % Change directory if the specified directory is provided and exists
    if nargin >= 2 && exist(directoryToGo, 'dir')
        cd(directoryToGo);
    end

    % Check if the folder exists, and if not, create it
    fullFolderPath = fullfile(pwd, folderName);

    % Check if the folder exists exactly, and if not, create it
    if ~exist(fullFolderPath, 'dir')
        mkdir(fullFolderPath);
        disp(['Folder "', folderName, '" created successfully.']);
    end
    
    % Change to the main folder if provided
    if nargin >= 3 && exist(mainFolder, 'dir')
        cd(mainFolder);
    end
end

com.mathworks.services.Prefs.setBooleanPref('EditorGraphicalDebugging', false);
warning('off', 'all');
rootdir = fileparts(mfilename('fullpath'));
addpath(genpath(rootdir));
init_solvers;

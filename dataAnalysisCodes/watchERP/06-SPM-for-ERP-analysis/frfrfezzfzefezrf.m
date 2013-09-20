spm('defaults', 'eeg');

S = [];
S.D = 'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\06-SPM-for-ERP-analysis\subject_S01\cefMspm8_2013-02-25-15-06-22-hybrid-10Hz.mat';
S.badchanthresh = 0.2;
S.methods.channels = {'all'};
S.methods.fun = 'peak2peak';
S.methods.settings.threshold = 50;
D = spm_eeg_artefact(S);


S = [];
S.D = 'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciResults\watchERP\06-SPM-for-ERP-analysis\subject_S01\acefMspm8_2013-02-25-15-06-22-hybrid-10Hz.mat';
D = spm_eeg_remove_bad_trials(S);



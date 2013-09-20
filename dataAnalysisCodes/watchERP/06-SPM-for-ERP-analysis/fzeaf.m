spm('defaults', 'eeg');

S = [];
S.D = [
       'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\06-SPM-for-ERP-analysis\efMspm8_2013-02-25-15-06-22-hybrid-10Hz.mat'
       'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\06-SPM-for-ERP-analysis\efMspm8_2013-02-25-16-32-02-hybrid-10Hz.mat'
       'D:\KULeuven\PhD\Work\Hybrid-BCI\HybBciCode\dataAnalysisCodes\watchERP\06-SPM-for-ERP-analysis\efMspm8_2013-02-25-16-01-13-hybrid-10Hz.mat'
       ];
S.recode = 'same';
D = spm_eeg_merge(S);



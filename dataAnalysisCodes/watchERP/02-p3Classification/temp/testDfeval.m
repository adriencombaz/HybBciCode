function testDfeval

allJobs = get(findResource, 'Jobs'); 
if ~isempty(allJobs), destroy(allJobs); end

[A, B] = dfeval(@averages, {1 10 100 1000}, ...
    {2 20 200 2000}, {6 60 600 6000})


end

function [mean_, median_] = averages (in1, in2, in3)
% AVERAGES Return mean and median of three input values
mean_ = mean([in1, in2, in3]);
median_ = median([in1, in2, in3]);
end
{smcl}
{* *! version 0.0.1  03MAY2015}{...}
{cmd:help cgwaterfall}
{hline}

{help cgwaterfall##syntax:Syntax}{tab}{help cgwaterfall##description:Description}{tab}{help cgwaterfall##options:Options}
{help cgwaterfall##required:Required Options}{tab}{help cgwaterfall##optional:Optional Arguments}{tab}{help cgwaterfall##examples:Examples}{tab}{help cgwaterfall##contact:Contact}

{title:Title}

{hi:cgwaterfall {hline 2}} A convenience wrapper for streamlining the generation 
of Waterfall charts from the {browse "http://cepr.harvard.edu/sdp/":Strategic Data Project} College Going Toolkit (CGTK).  For a demonstration of the materials from the toolkit, 
use {stata cgwaterfalldemo, id(all)} to see the code use to generate the example 
waterfall charts.{p_end}

{marker syntax}
{title:Syntax}

{p 4 4 4}{cmd:cgwaterfall} [{opt using}] [{opt if}], 
{cmdab:schn:ame(}{it:varname}{opt )} 
{cmdab:bys:ep(}{it:string}{opt )} 
{cmdab:year:span(}{it:numlist}{opt )} 
{cmdab:on:time(}{it:varname}{opt )} 
{cmdab:f:enr(}{it:varname}{opt )} 
{cmdab:s:enr(}{it:varname}{opt )} 
{cmdab:grad:var(}{it:varname}{opt )} 
{cmdab:coh:ortid(}{it:varname}{opt )} 
{cmdab:si:d(}{it:varname}{opt )} 
[ {cmdab:st:ats(}{it:string}{opt )} 
{cmdab:se:x(}{it:varname}{opt )} 
{cmdab:ra:ce(}{it:varname}{opt )} 
{cmdab:fr:l(}{it:varname}{opt )} 
{cmdab:fm:t(}{it:string}{opt )} 
{cmd: gph}
{cmdab:sche:me(}{it:passthru}{opt )} 
{cmdab:save:name(}{it:string}{opt )}
{cmdab:ag:ency(}{it:string}{opt )}
{cmdab:cell:size(}{it:integer}{opt )}
{cmdab:onts:ample(}{it:integer}{opt )}
{cmd:gpa(}{it:integer}{opt )}
{cmdab:onty:ear(}{it:integer}{opt )}
] {p_end}

{marker description}{title:Description}

{p 4 4 4}{cmd:cgwaterfall} is a convenience wrapper providing a unified API for 
generating any of the College Going Toolkit Waterfall charts.  There is a slight 
deviance in the methodology used to estimate the upper and lower bounds; more 
specifically, each school has its own unique lower/upper bound that is based on 
the arguments you supply to the stats option.  {p_end}

{marker options}{title:Options}
{p 4 4 4} The {opt using} argument is optional.  If you have data currently in 
memory, the program will keep those data safe when loading the data specified in 
the using argument and restore it upon completion.  If the data is in memory 
currently, you can omit this argument to use the data available. {p_end}

{marker required}
{dlgtab 0 0:Required Parameters}{break}
{p 4 4 8}{cmdab:schn:ame} is used to tell the program the name of the variable 
containing school names in your dataset.  For consistency with future releases 
and improvements, it is recommended that this variable correspond to the first 
high school attended variable you created while working through the toolkit.{p_end}

{p 4 4 8}{cmdab:bys:ep} is an argument used to specify whether the program 
should generate a single (by) graph with all of the schools in individual 
subplots, separate (sep) graphs for each school, or a single graph for the 
entire district (overall).
{it: Note: if you only need a graph for a single school, you can pass the name of the school and/or any other identifying information to the if qualifier to let the program know to only use data for that school.}{p_end}

{p 4 4 8}{cmdab:year:span} must be passed a pair of integers denoting the 
start and end years for the ninth grade cohorts you can observe persisting to 
the second year of college. {p_end}

{p 4 4 8}{cmdab:on:time} is an indicator variable used to denote whether or not 
the student graduated on-time ( == 1) or not ( != 1). {p_end}

{p 4 4 8}{cmdab:f:enr} is an indicator variable used to denote whether or not 
the student enrolled in college in the year following their high school 
graduation. {it:Note: this variable is called enrl_1oct_ninth_yr1_any in the CGTK}.  {p_end}

{p 4 4 8}{cmdab:s:enr} is an indicator variable used to denote whether or not 
the student enrolled in college two years after graduating from high school.  
{it:Note: this variable is called enrl_1oct_ninth_yr2_any in the CGTK}. {p_end}

{p 4 4 8}{cmdab:grad:var} is an indicator variable used to denote whether or not 
the student graduated from high school. {p_end}

{p 4 4 8}{cmdab:coh:ortid} is the variable in your dataset used to identify the 
year corresponding to the student entrance into the graduation cohort. The 
value of this variable should be between or equal to the values passed to the 
{cmdab:year:span} argument above.{p_end}

{p 4 4 8}{cmdab:si:d} should contain the name of your variable for student IDs.{p_end}

{marker optional}{dlgtab 4 0:Optional Parameters}{break}
{p 10 10 14}{cmdab:st:ats} is an argument used to define the lower bounds, 
central tendancy, and upper bounds used for the waterfall chart.  For the best, 
and most consistent performance, you should use three arguments like: lb ct ub.  
Where lb = lower bound, ct = central tendency, and ub = upper bound.  If no 
arguments are supplied the program will default to using: min mean max.  {p_end}

{p 10 10 14}The available statistics that you can select from are: {p_end}

{p2colset 14 30 25 20}
{p2line} 
{p2col : argument} Result {p_end}
{p2line} 
{p2col : {hi:mean}} {hi:Average (Proportion)} {p_end}
{p2col : {hi:min}} {hi:Minimum Proportion school averages} {p_end}
{p2col : {hi:max}} {hi:Maximum Proportion school averages} {p_end}
{p2col : {hi:semean}} {hi:Standard error of the mean (Proportion)} {p_end}
{p2col : {hi:sd}} {hi:Standard deviation across schools} {p_end}
{p2col : {hi:mad}} {hi:Median Absolute Deviance} {p_end}
{p2col : {hi:mdev}} {hi:Mean Absolute Deviance} {p_end}
{p2col : {hi:##}} {hi:## Percentile value of the Proportion} {p_end}
{p2line}{break}

{p 10 10 14}{cmdab:se:x} is an indicator used to identify the student sex.  If 
included, the resulting graphs will be disaggregated by sex. {p_end}

{p 10 10 14}{cmdab:ra:ce} is an indicator used to identify the student sex.  If 
included, the resulting graphs will be disaggregated by sex. {p_end}
 
{p 10 10 14}{cmdab:fr:l} is an indicator used to identify the student sex.  If 
included, the resulting graphs will be disaggregated by sex. {p_end}

{p 10 10 14}{cmdab:fm:t} is an optional argument used to specify the external 
image format to use when saving graph files (e.g., pdf, ps, eps, etc...).  {p_end}

{p 10 10 14}{cmd: gph} is an optional argument used to save the Stata graph 
files to disk.  If you do not specify this option, the Stata graph files (.gph) 
will be deleted during the program execution. {p_end}

{p 10 10 14}{cmdab:sche:me} is an option used to specify the scheme file to use 
to define the aesthetic properties of the graph.  If you want an easy way to 
generate customized scheme files, you can install {stata `"net describe brewscheme, from("http://www.paces-consulting.org/stata")"':net describe brewscheme} by clicking 
on the links below in the order in which they appear: {p_end}

{marker brewscheme}
{p 14 14 14}{stata `"net from "http://www.paces-consulting.org/stata""':net from "http://www.paces-consulting.org/stata"}{p_end}
{p 14 14 14}{stata net inst brewscheme, replace}{p_end}
{p 14 14 14}{stata `"brewscheme, histst(pastel1) barst(puor) barc(11) boxst(pastel2)  boxc(8) scatst(set1) scatc(9) somest(oranges) somec(9) cist(dark2) areast(greys)  scheme(sdpdemo)"'}{p_end}


{p 10 10 14}{cmdab:save:name} is an optional argument used to provide a name 
stub for exporting your graph files.  Leave this argument blank if you just want 
to view the graphs interactively, but provide a string if you want to save the 
resulting graphs. {p_end}

{p 10 10 14}{cmdab:ag:ency} is an optional argument used to provide the name of 
the SEA/LEA to be inserted in the agency level overall graphs. {p_end}

{p 10 10 14}{cmdab:cell:size} this parameter takes and interger used to remove 
cases that do not have sufficient observations to be used for public reporting 
purposes.  {hi:{it: This defaults to a value of 20}}.{p_end}

{p 10 10 14}{cmdab:onts:ample} should be the name of your variable indicating 
whether or not students were included in your analytical sample.{p_end}

{p 10 10 14}{cmd:gpa} expects a variable containing GPAs of students after their 
first year of high school.{p_end}

{p 10 10 14}{cmdab:onty:ear} takes the ontrack at the end of year 1 variable.{p_end}

{marker examples}{title:Examples}

{p 4 4 4}{hi:Create an agency-wide performance graph with school-level subplots.} {p_end}

{p 8 8 8}{stata `"cgwaterfall using analysis/CG_analysis, schn(first_hs_name) bys(by) year(2005 2005) ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) grad(chrt_grad) coh(chrt_ninth) sid(sid)"'}{p_end}

{p 4 4 4}{hi:Create a graph for persistence disaggregated by race and using the 25th and 75th percentiles of the average number of children in each group.} {p_end}

{p 8 8 8}{stata `"cgwaterfall, schn(first_hs_name) bys(by) year(2005 2005) ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) grad(chrt_grad) coh(chrt_ninth) si(sid) st(25 50 75) scheme(sdpdemo) race(race_ethnicity)"'} {p_end}

{p 4 4 4}{hi:Create a graph for each school with male and female sub-plots.} {p_end}

{p 8 8 8}{stata `"cgwaterfall, schn(first_hs_name) bys(sep) year(2005 2005) ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) grad(chrt_grad) coh(chrt_ninth) si(sid) st(sd mean) scheme(sdpdemo) sex(male)"'} {p_end}

{p 4 4 4}{hi:Get the data used for the graph back into memory}{p_end}
{p 8 8 8}{stata mat x = r(waterfall)}{p_end}
{p 8 8 8}{stata svmat x, names(col)}{p_end}

{p 4 4 4}{hi:To recover the value and variable labels immediately following the command, you can copy and paste the code below to rebuild the dataset used for the graphs.}
{it:Note: You may need to reapply labels for disaggregation variables manually}.{p_end}{break}
{p 8 8 8}foreach v in schnm outtype cellsize schcellsize loutcome schmoutcome moutcome uoutcome {c -(}{p_end}
{p 12 8 8}`r(`v')'{p_end}
{p 8 8 8}{c )-}{p_end}
{p 8 8 8}`r(schnmvarlab)'{p_end}
{p 8 8 8}`r(outtypevarlab)'{p_end}
{p 8 8 8}la val schnm schnm{p_end}
{p 8 8 8}la val outtype outtype{p_end}

{p 4 4 4}{hi: Overall on track for HS graduation status using Statas default graphics settings.} {p_end}

{p 8 8 8}cgwaterfall, schn(first_hs_name) bys(overall) year(2005 2005) 
ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) 
grad(chrt_grad) coh(chrt_ninth) si(sid) st(min mean max) onts(ontrack_sample) 
ontyear(ontrack_endyr1) gpa(cum_gpa_yr1) {p_end}

{p 4 4 4}{hi:Same as the graph above but using the customized graph scheme created {help cgwaterfall##brewscheme:above}.} {p_end}

{p 8 8 8}cgwaterfall, schn(first_hs_name) bys(overall) year(2005 2005) 
ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) 
grad(chrt_grad) coh(chrt_ninth) si(sid) st(min mean max) onts(ontrack_sample) 
ontyear(ontrack_endyr1) gpa(cum_gpa_yr1) scheme(sdpdemo) {p_end}

{p 4 4 4}{hi:Produces a lattice (Cleveland, {help cgwaterfall##cl93:1993}, {help cgwaterfall##cl94:1994}) style graph where the y-axis shows facets of student sex and the x-axis shows facets of free/reduced price lunch status.} {p_end} 
{p 8 8 8}cgwaterfall, schn(first_hs_name) bys(overall) year(2005 2005) 
ont(ontime_grad) f(enrl_1oct_ninth_yr1_any) s(enrl_1oct_ninth_yr2_any) 
grad(chrt_grad) coh(chrt_ninth) si(sid) st(min mean max) onts(ontrack_sample) 
ontyear(ontrack_endyr1) gpa(cum_gpa_yr1) scheme(sdpdemo) sex(male) frl(frpl_ever) {p_end}

{marker title}{title:References}

{marker cl93}{p 4 8 8} Cleveland, W. S. (1993). {it:Visualizing data}. Summit, NJ: Hobart Press.{p_end}

{marker cl94}{p 4 8 8} Cleveland, W. S. (1994). {it:The elements of graphing data}. Summit, NJ: Hobart Press.{p_end}


{marker contact}{title: Author}{break}
{p 1 1 1} William R. Buchanan, Ph.D. {break}
Strategic Data Fellow {break}
{browse "http://mde.k12.ms.us":Mississippi Department of Education} {break}
BBuchanan at mde [dot] k12 [dot] ms [dot] us

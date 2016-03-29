{smcl}
{* *! version 0.0.1  12MAY2015}{...}
{cmd:help cgbubble}
{hline}

{help cgbubble##syntax:Syntax}{tab}{help cgbubble##description:Description}{tab}{help cgbubble##options:Options}
{help cgbubble##required:Required Options}{tab}{help cgbubble##optional:Optional Arguments}{tab}{help cgbubble##examples:Examples}{tab}{help cgbubble##contact:Contact}

{title:Title}

{hi:cgbubble {hline 2}} A convenience wrapper for streamlining the generation 
of Bubble Plots from section D of the {browse "http://cepr.harvard.edu/sdp/":Strategic Data Project's} College Going Toolkit (CGTK).

{marker syntax}
{title:Syntax}

{p 4 4 4}{cmd:cgbubble} [{opt using}] [{opt if}], 
{cmdab:coh:ortid(}{it:varname}{opt )} 
{cmdab:y:ears(}{it:numlist}{opt )} 
{cmdab:qtile:math(}{it:string}{opt )} 
{cmdab:schn:ame(}{it:varname}{opt )} 
{cmdab:dipl:oma(}{it:varname}{opt )} 
{cmdab:enr:ollyear1(}{it:varname}{opt )} 
[ {cmdab:str:etch}
{cmd:scheme(}{it:passthru}{opt )} 
{cmdab:sav:ing(}{it:string}{opt )}
{cmdab:fm:t(}{it:string}{opt )} 
{cmdab:jit:ter(}{it:real}{opt )} ] 

{marker description}
{title:Description}

{p 4 4 4}{cmd:cgbubble} is a convenience wrapper for the generation of the 
College Enrollment Rates by 8th Grade Achievement Quartiles bubble plots from 
the College Going Toolkit. {p_end}

{marker options}
{title:Options}
{p 4 4 4} The {opt using} argument is optional.  If you have data currently in 
memory, the program will keep those data safe when loading the data specified in 
the using argument and restore it upon completion.  If the data is in memory 
currently, you can omit this argument to use the data currently in memory.{p_end}

{marker required}
{dlgtab 0 0:Required Parameters}{break}

{p 4 4 8}{cmdab:coh:ortid} is the variable in your dataset used to identify the 
year corresponding to the graduation cohort (chrt_grad in the toolkit). The 
value of this variable should be between or equal to the values passed to the 
{cmdab:y:ears} argument.{p_end}

{p 4 4 8}{cmdab:y:ears} must be passed a pair of integers denoting the 
start and end years for the ninth grade cohorts you can observe persisting to 
the second year of college. {p_end}

{p 4 4 8}{cmdab:qtile:math} is an ordinal variable indicating the quartile of 
students' 8th grade math scores. {it: Note: You could pass any variable classifying students into quartiles, but the labels on the graph would need to be edited post-hoc}.{p_end}

{p 4 4 8}{cmdab:schn:ame} is used to tell the program the name of the variable 
containing school names in your dataset.  For consistency with future releases 
and improvements, it is recommended that this variable correspond to the first 
high school attended variable you created while working through the toolkit.{p_end}

{p 4 4 8}{cmdab:dipl:oma} is an indicator variable used to denote whether or not 
the student graduated from high school. {p_end}

{p 4 4 8}{cmdab:enr:ollyear1} is an indicator variable used to denote whether or not 
the student enrolled in college in the year following their high school 
graduation. {it:Note: this variable is called enrl_1oct_ninth_yr1_any in the CGTK}.  {p_end}

{marker optional}
{dlgtab 4 0:Optional Parameters}{break}
{p 10 10 14}{cmdab:str:etch} is an optional argument used to strech the scaling 
of the values on the xaxis (e.g., w/o this option the x-axis will look more like 
the example in the toolkit and with the option the values will be dispersed over 
the x-axis). {p_end}

{p 10 10 14}{cmdab:sche:me} is an option used to specify the scheme file to use 
to define the aesthetic properties of the graph.  If you want an easy way to 
generate customized scheme files, you can install {stata `"net describe brewscheme, from("http://www.paces-consulting.org/stata")"':net describe brewscheme} by clicking 
on the links below in the order in which they appear: {p_end}

{marker brewscheme}{p 14 14 14}{stata `"net from "http://www.paces-consulting.org/stata""'}{p_end}
{p 14 14 14}{stata net inst brewscheme, replace}{p_end}
{p 14 14 14}{stata `"brewscheme, histst(pastel1) barst(puor) barc(11) boxst(pastel2)  boxc(8) scatst(set1) scatc(9) somest(oranges) somec(9) cist(dark2) areast(greys)  scheme(sdpdemo)"'}{p_end}

{p 10 10 14}{cmdab:sav:ing} is an optional argument used to provide a name 
stub for exporting your graph files.  Leave this argument blank if you just want 
to view the graphs interactively, but provide a string if you want to save the 
resulting graphs. {p_end}

{p 10 10 14}{cmdab:fm:t} is an optional argument used to specify the external 
image format to use when saving graph files (e.g., pdf, ps, eps, etc...).  {p_end}

{p 10 10 14}{cmdab:jit:ter} is an optional that allows you to control the level 
of jittering (random peturbation) added to the locations of the points to help 
avoid overlap/overplotting.{p_end}

{marker examples}
{title:Examples}

{p 4 4 4}{hi:Create an agency-wide performance graph with school-level subplots.} {p_end}

{p 8 8 8}{stata `"cgbubble using analysis/CG_analysis, schn(last_hs_name) year(2008 2008) enr(enrl_1oct_ninth_yr1_any) dipl(hs_diploma) qtile(qrt_8_math) coh(chrt_grad)"'}{p_end}

{p 4 4 4}{hi:Same as the graph above, but using a custom scheme file for the graph aesthetics.} {p_end} 
{p 8 8 8}{stata `"cgbubble, schn(last_hs_name)  year(2008 2008)  enr(enrl_1oct_ninth_yr1_any)  dipl(hs_diploma) coh(chrt_grad) qtile(qrt_8_math) scheme(sdpdemo)"'}{p_end}

{p 4 4 4}{hi:Stretch the values of the math quartiles across a larger portion of the x-axis.} {p_end} 
{p 8 8 8}{stata `"cgbubble, schn(last_hs_name)  year(2008 2008)  enr(enrl_1oct_ninth_yr1_any)  dipl(hs_diploma) coh(chrt_grad) qtile(qrt_8_math) str"'}{p_end}

{p 4 4 4}{hi:Same as the graph above, but using a custom scheme file for the graph aesthetics and with the bubbles stretched across a larger portion of the x-axis} {p_end} 
{p 8 8 8}{stata `"cgbubble, schn(last_hs_name)  year(2008 2008)  enr(enrl_1oct_ninth_yr1_any)  dipl(hs_diploma) coh(chrt_grad) qtile(qrt_8_math) scheme(sdpdemo) str"'}{p_end}

{marker contact}{title: Author}{break}
{p 1 1 1} William R. Buchanan, Ph.D. {break}
Strategic Data Fellow {break}
{browse "http://mde.k12.ms.us":Mississippi Department of Education} {break}
BBuchanan at mde [dot] k12 [dot] ms [dot] us

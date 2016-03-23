**GETTING DATA**
use "C:\Users\mvl\Dropbox\EU bevægelsen\doing data\replication.dta", clear

**RECODING*
replace intent=. if intent > 10 | alder==. //dropping those who cannot vote
replace intent=intent/10 //rescaling intent to vote to go between zero and one
ta intent

recode participate (2=0) (9=.)

replace samfniveau=(samfniveau-1)/2 // Rescaling social science level to go between zero and one

*Creating variable wich identifes the sample used for model
reg  intent participate inter koen i.alder  i.momeduc i.dadeduc c.samfniveau i.klasse i.gymnasium 
gen sample=e(sample)

*Creating variable identifying compliers
gen complier=0
replace complier=1 if participate==inter

**Creating dummy versions of a number of variables to make t-tests possible.
ta samfniveau, gen(ss) 
ta momeduc, gen(mom)
ta dadeduc, gen(dad)
ta alder, gen(age)
ta klasse, gen(class)

***Table 1***	

*Running t-tests and writing table at the same time
file open anyname using tab1.txt, write text replace
file write anyname  _newline  _col(0)  "\begin{table} [htbp] \centering \caption{Descriptive statistics}\begin{tabular}{l*{10}{c}}\hline\hline"
file write anyname _newline _col(0) "&Treatment & Control & Std. difference &P-value & n  \hline "
foreach x of varlist  participate samfniveau  class*  koen* age* mom* dad* gym* {
ttest `x' if sample==1 , by(inter)
file write anyname _newline  _tab %9.2f  (r(mu_2)) " &" _tab %9.2f  (r(mu_1)) " &" _tab %9.2f ((r(mu_2)-r(mu_1))/r(sd_1)) " &" 
reg `x' inter  if sample==1 , cluster(cluster)
file write anyname _tab %9.2f (2*(1-normal(abs(_b[inter]/_se[inter])))) " &" _tab %9.2f  (e(N)) " \\"
}
file write anyname _newline _col(0) "\hline\hline"
file write anyname _newline _col(0) "\end{tabular}"
file write anyname _newline _col(0) "\end{table}"
file close anyname		

***Table 2 and 3***
*Running models
eststo a: ivregress 2sls  intent (participate=inter) if sample==1, robust cluster(cluster)
eststo b: ivregress 2sls intent (participate=inter) c.samfniveau i.klasse##i.gymnasium if sample==1, robust cluster(cluster)
eststo c: ivregress 2sls intent (participate=inter) koen i.alder  i.momeduc i.dadeduc c.samfniveau i.klasse##i.gymnasium , robust cluster(cluster)	

eststo d: ivregress 2sls  viden (participate=inter) if sample==1, robust cluster(cluster)
eststo e: ivregress 2sls viden (participate=inter) c.samfniveau i.klasse##i.gymnasium if sample==1, robust cluster(cluster)
eststo f: ivregress 2sls viden (participate=inter) koen i.alder  i.momeduc i.dadeduc c.samfniveau i.klasse##i.gymnasium , robust cluster(cluster)	

*writing tables
esttab a b c using  tab2.tex, replace se keep(_cons participate koen  samfniveau 2.alder 3.alder  ) ///
varlabel(_cons "Constant" participate "Participated" koen "Female (ref: Male)" samfniveau "Social science level"  2.age "19 years old (ref: 18)" 3.age "20 years old" ) /// 
nonotes stats(N r2 rmse, fmt(%9.2f %9.2f %9.2f)) star(* 0.05) b(%9.2f) indicate("Dummies for mother's educational level=2.momeduc" "Dummies for father's educational level=2.dadeduc", label("X")) ///
addnotes("Standard errors clustered on class-level in parentheses. All variables recoded to go between zero and one." "Variable participated instrumented in the first stage using a dummy indicating respondent was treated." "\sym{*} \(p<0.05\)")
		
esttab d e f using tab3.tex, se replace  keep(_cons participate koen  samfniveau 2.alder 3.alder  ) ///
varlabel(_cons "Constant" participate "Participated" koen "Female (ref: Male)" samfniveau "Social science level"  2.age "19 years old (ref: 18)" 3.age "20 years old" ) /// 
nonotes stats(N r2 rmse, fmt(%9.2f %9.2f %9.2f)) star(* 0.05) b(%9.2f) indicate("Dummies for mother's educational level=2.momeduc" "Dummies for father's educational level=2.dadeduc", label("X")) ///
addnotes("Standard errors clustered on class-level in parentheses. All variables recoded to go between zero and one." "Variable participated instrumented in the first stage using a dummy indicating respondent was treated." "\sym{*} \(p<0.05\)")

**Descriptive Statistics*
file open anyname using apdx.txt, write text replace
file write anyname  _newline  _col(0)  "\begin{table} [htbp] \centering \caption{Descriptive statistics}\begin{tabular}{l*{10}{c}}\hline\hline"
file write anyname _newline _col(0) "&2001 data & & &  & & &2002 data & & & \\ \hline"
file write anyname _newline _col(0) "&Mean & SD & n  \hline "
foreach x of varlist participate inter complier intent viden koen ss*  age* class* mom* dad*  {
su `x' if sample==1 , d
file write anyname _newline  _tab %9.2f  (r(mean)) " &" _tab %9.2f (r(sd)) " &" _tab %9.2f  (r(N)) " \\"
}
file write anyname _newline _col(0) "\hline\hline"
file write anyname _newline _col(0) "\end{tabular}"
file write anyname _newline _col(0) "\end{table}"
file close anyname

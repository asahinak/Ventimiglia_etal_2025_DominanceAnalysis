README: Dominance Classification

Overview
These MATLAB scripts classify pairwise dominance behavior from FlymatAll and FlyFeatures variables created following FlyTracker output. For each experimental condition, run the analysis in this order:
1.	Facing-angle analysis
2.	Lunge analysis
3.	Cross-metric classifier that integrates the facing-angle and lunge classifications
4.	
The scripts provide a reproducible framework to assist with classification; they are not intended to replace experimenter review. Disagreements between classifiers are flagged for inspection, and may require a final manual adjustment when the selected classification window does not represent the broader behavior of the pair.
Requirements and inputs:
•	MATLAB 2024 or newer
•	Corrected fly identities in paired sequential order (pair ={a,b} ordered linearly in FlymatAll as {1,2}, {3,4}…).
•	FlymatAll and FlyFeatures variables created from FlyTracker and JAABA lunge classification outputs.
Use the scripts corresponding to the experimental condition being analyzed. Before running them, check that the input files, recording frame rate, and analysis-window settings match that experiment. 
FlymatAll structure should contain:  {'movie’}, {‘fly' }, {'fps’}, {‘L_start’}, {‘L_end’},{‘L_startsm’}, {'L_endsm'}, {'L_binary’}, {'L_bouts’}, {‘L_dur’}, {‘L_binbouts' }, {‘L_bindur'}
FlyFeatures structure should contain: {'FacingAngle’}, {‘velocity'}, {‘Dist2Wall'}
 
Workflow
1. Facing-angle analysis
Run the condition-specific facing-angle script first. It calculates facing-angle distributions and assigns a facing-angle classification for each pair.
The facing-angle classification uses regional histogram enrichment in the facing and fleeing ranges, together with each fly’s mean facing angle relative to 1.5 rad. The center range may be shown in plots to aid visual inspection, but it is not itself a classification criterion.
Review the generated distributions and any flagged cases, especially when the classification is unclear or the facing-angle data appear noisy.
2. Lunge analysis
Run the corresponding lunge script. It quantifies lunges during the condition-specific dominance determination window and assigns a lunge-based classification.
The classification distinguishes “No Fighting,” “Low Lunging,” “Dominance”, and “No Dominance” cases according to the thresholds implemented in the relevant script.
3. Cross-metric classifier
Run the condition-specific classifier after both preceding analyses. It combines the facing-angle and lunge classifications, applies the integration rules, and flags disagreements for review.
The original flymatAll_Final retains the classification information, including “No Fighting” flags. The cleaned data object, flymatAll_Final_Cleaned, removes “No Fighting” and “Unclear” pairs and can be used for subsequent analyses.
Analysis windows
The dominance determination window depends on the experimental protocol. In general, the analysis uses a 10-minute window selected to match the stimulation or recording paradigm:
•	Pulsed CsChrimson: the final two 5-minute stimulation periods
•	Continuous CsChrimson: the final 10 minutes of stimulation
•	No stimulation: the final 10 minutes of the recording

Reviewing classifications
The classifiers are designed to help process large datasets consistently, not to eliminate experimenter judgment. In particular:
•	Disagreements are flagged so the pair’s facing-angle distributions and lunge behavior can be reviewed.
•	The analysis window may not always capture the broader behavioral context. For example, climbing on the chamber wall can reduce counted behaviors, and behavior near the end of an assay may not represent the preceding interaction.
•	In rare cases, the final call may be adjusted after reviewing behavior beyond the determination window. Record and document any manual adjustments.
•	For new experiments, stimulation paradigms, recording conditions, or genotypes, validate the window settings and classification rules against representative data. Some condition-specific adjustments may be needed.

See this reference for FlymatAll variable creation following FlyTracker and JAABA output:
Wohl, M., Ishii, K. & Asahina, K. Layered roles of fruitless isoforms in specification and function of male aggression-promoting neurons in Drosophila. eLife 9, e52702 (2020).

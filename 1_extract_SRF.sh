#!/bin/bash
#Written by Jing Xiang CHUNG on 23rd Aug 2021
#Please report bugs at jingxiang89@gmail.com
#Extract and prepare SRF files for sharing

#User's inputs/edit here if needed.
datadir='output'                #Model output directory.
odir='extracted_output'         #Directory to store the output of this script.
year_start='2010'               #Year start of model
year_end='2015'                 #Year end of model
indexbox='13,266,13,214'        #Remove buffer zone

#--------------------------------------------------------
#Variable list to process
thrvar_list='pr prc uas vas hfss hfls'  #Variables in 3-hourly
monvar_list='pr prc psl evspsbl huss zmla hfss hfls' #Variables in monthly

#--------------------------------------------------------
#Generate list of experiments ran
cat << EOF > srf.explist.csv
Experiment,Cumulus,PBL,Moisture
01,4,1,1
02,4,1,3
03,4,1,2
04,4,2,1
05,4,2,3
06,4,2,2
07,4,3,1
08,4,3,3
09,4,3,2
10,4,4,1
11,4,4,3
12,4,4,2
13,5,1,1
14,5,1,3
15,5,1,2
16,5,2,1
17,5,2,3
18,5,2,2
19,5,3,1
20,5,3,3
21,5,3,2
22,5,4,1
23,5,4,3
24,5,4,2
25,6,1,1
26,6,1,3
27,6,1,2
28,6,2,1
29,6,2,3
30,6,2,2
31,6,3,1
32,6,3,3
33,6,3,2
34,6,4,1
35,6,4,3
36,6,4,2
37,2,1,1
38,2,1,3
39,2,1,2
40,2,2,1
41,2,2,3
42,2,2,2
43,2,3,1
44,2,3,3
45,2,3,2
46,2,4,1
47,2,4,3
48,2,4,2

EOF

#--------------------------------------------------------
#Getting list of files
allfile_list=`ls ${datadir}/*SRF.??????????.nc`

#--------------------------------------------------------
#Check which experiment was ran
exp_setting=(`ncdump -h $(echo ${allfile_list} | cut -d " " -f 1) | grep -E cumulus_convection_scheme_lnd\|cumulus_convection_scheme_ocn\|boundary_layer_scheme\|moisture_scheme | sed 's/[^0-9]//g'`)

pbl=${exp_setting[0]}
[[ ${exp_setting[1]} -ne ${exp_setting[2]} ]] && cup=999 || cup=${exp_setting[1]}
moist=${exp_setting[3]}

linenum=`cat srf.explist.csv | cut -d "," -f 2- | grep -n "${cup},${pbl},${moist}" | cut -d ":" -f 1`
[[ ${linenum} != '' ]] && expnum=`sed -n ${linenum}p < srf.explist.csv | cut -d "," -f 1` || expnum='NA'
[[ ${expnum} == 'NA' ]] && echo "ERROR:Settings used for your simulation does not match the experiment list!" && exit
echo "Output from experiment ${expnum} detected, data extraction will proceed ..."
	rm srf.explist.csv

#--------------------------------------------------------
#Program starts

[[ ! -d ${odir} ]] && mkdir -p ${odir}

#3-hourly
for var in ${thrvar_list}; do

	echo "Processing 3-hourly variable ${var} ..."

	for ifile in ${allfile_list}; do
		ofiledate=`basename ${ifile} | cut -d "." -f 2`	
		cdo selvar,${var} ${ifile} ${odir}/${var}_exp${expnum}.${ofiledate}.srftmp1
	done

	for (( y=${year_start}; y<=${year_end}; y++ )); do

        	ifile_list=`ls ${odir}/${var}_exp${expnum}.${y}??????.srftmp1`
        	cdo -O mergetime ${ifile_list} ${odir}/${var}_exp${expnum}.${y}.srftmp2
                	rm -rf ${ifile_list}
	done

	cdo -O mergetime ${odir}/${var}_exp${expnum}.????.srftmp2 ${odir}/${var}_exp${expnum}.srftmp3
	        rm -rf ${odir}/${var}_exp${expnum}.????.srftmp2

	cdo setgridtype,lonlat -selindexbox,${indexbox} ${odir}/${var}_exp${expnum}.srftmp3 ${odir}/${var}_exp${expnum}_3hourly.nc
		rm -rf ${odir}/${var}_exp${expnum}.srftmp3

done

#Monthly
for var in ${monvar_list};do

	echo "Processing monthly variable ${var} ..."

	if [[ -f ${odir}/${var}_exp${expnum}_3hourly.nc ]]; then
		cdo monmean ${odir}/${var}_exp${expnum}_3hourly.nc ${odir}/${var}_exp${expnum}_monmean.nc
	else
	        for ifile in ${allfile_list}; do
        	        ofiledate=`basename ${ifile} | cut -d "." -f 2`
	                cdo selvar,${var} ${ifile} ${odir}/${var}_exp${expnum}.${ofiledate}.srftmp1
	        done

	        for (( y=${year_start}; y<=${year_end}; y++ )); do

	                ifile_list=`ls ${odir}/${var}_exp${expnum}.${y}??????.srftmp1`
	                cdo -O mergetime ${ifile_list} ${odir}/${var}_exp${expnum}.${y}.srftmp2
	                        rm -rf ${ifile_list}
	        done

	        cdo -O mergetime ${odir}/${var}_exp${expnum}.????.srftmp2 ${odir}/${var}_exp${expnum}.srftmp3
	                rm -rf ${odir}/${var}_exp${expnum}.????.srftmp2

	        cdo setgridtype,lonlat -selindexbox,${indexbox} -monmean ${odir}/${var}_exp${expnum}.srftmp3 ${odir}/${var}_exp${expnum}_monmean.nc
	                rm -rf ${odir}/${var}_exp${expnum}.srftmp3
	fi

done

echo "Job completed!"


#!/bin/bash
#Script for extracting ATM files for sharing among CORDEX SEA members
#Written by Jing Xiang CHUNG on 13/2/2025
#Any bug reports please contact jingxiang@umt.edu.my

#User's input
#1. List of variables wanted
var_list='ua850 va850 ta850 hus850 ua500 va500 ta500 ua200 va200 ta200'

#2. List of models to extract
model_list='EC-Earth3-Veg_historical_5km'

#3. Where you keep all the models data
data_dir='/mnt/umt_data01/Completed_Runs_5km_Part1'

#4. Year where model data starts
year_start='1990'

#5. Year where model data ends
year_end='2014'

#6. sigma2p binary and its location
sig2p='/storage/scratch/jxchung/RegCM/bin/sigma2pCLM45'

#7. delete sigma2p output after completion? (yes=1, no=0)
rmsig='1'

#---------------------------------------------------------------------------
#Script start
for model in ${model_list}; do

	#Folder where a single model output was kept
	fout_model="${data_dir}/${model}/*output*"

	[[ ! -d ${model} ]] && mkdir -p ${model}

	sigma_file_list=`ls ${fout_model}/*ATM*.nc`
	
	#Converting sigma levels to pressure levels
	echo "...converting files to pressure levels..."
	cd ${model}
	for sf in ${sigma_file_list}; do

		o_sf=`basename ${sf}`
		sf_date=`echo ${o_sf} | cut -d "." -f 2`

		echo "...working on ${sf_date}..."

		if [[ ! -f ${model}_ATM.${sf_date}_pressure.nc ]]; then
			${sig2p} ${sf}
			mv ${o_sf%.nc}_pressure.nc ${model}_ATM.${sf_date}_pressure.nc
		else
			echo "...pressure levels file exist, skipping conversion..."
		fi

	done
	cd ..

	for var in ${var_list}; do
	
		for (( y=${year_start}; y<=${year_end}; y++ )); do

			echo "Extracting variable ${var} from model ${model} for year ${y}..."

			ifile_list=`ls ${model}/${model}_ATM.${y}*_pressure.nc`
			
			for ifile in ${ifile_list}; do

				fdate=`basename ${ifile} | cut -d "." -f 2 | cut -d "_" -f 1`
				vvar=`echo ${var} | sed 's/[^A-Za-z]//g'`
				vlev=`echo ${var} | sed 's/[^0-9]//g'`

				cdo chname,${vvar},${var} -sellevel,${vlev} -selvar,${vvar} ${ifile} ${model}/${var}_${model}_${fdate}.nc

			done

			cdo -O mergetime ${model}/${var}_${model}_${y}??????.nc ${model}/${var}_${model}_${y}.nc
				rm ${model}/${var}_${model}_${y}??????.nc

		done

		echo "...merging up everything..."
		cdo -O mergetime ${model}/${var}_${model}_????.nc ${model}/${var}_${model}_${year_start}_${year_end}.nc
		cdo setgridtype,lonlat -daymean ${model}/${var}_${model}_${year_start}_${year_end}.nc ${model}/${var}_${model}_day_${year_start}0101_${year_end}1231.nc.tmp

		echo "...compressing file..."
		nccopy -d9 ${model}/${var}_${model}_day_${year_start}0101_${year_end}1231.nc.tmp ${model}/${var}_${model}_day_${year_start}0101_${year_end}1231.nc
			rm ${model}/${var}_${model}_????.nc ${model}/${var}_${model}_${year_start}_${year_end}.nc ${model}/${var}_${model}_day_${year_start}0101_${year_end}1231.nc.tmp

	done

	[[ ${rmsig} == '1' ]] && rm ${model}/${model}_ATM.*_pressure.nc

done

echo "Job completed!"


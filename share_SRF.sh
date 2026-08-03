#!/bin/bash
#Script for extracting SRF files for sharing among CORDEX SEA members
#Written by Jing Xiang CHUNG on 12/2/2025
#Any bug reports please contact jingxiang@umt.edu.my

#User's input
#1. List of variables wanted
var_list='tas pr huss hurs ps psl sfcWind uas vas'

#2. List of models to extract
model_list='EC-Earth3-Veg_historical_5km'

#3. Where you keep all the models data
data_dir='/mnt/umt_data01/Completed_Runs_5km_Part1'

#4. Year where model data starts
year_start='1990'

#5. Year where model data ends
year_end='2014'

#6. RegCM Output type (SRF? STS? RAD?)
otype='SRF'

#---------------------------------------------------------------------------
#Script start
for model in ${model_list}; do

        #Folder where a single model output was kept
        fout_model="${data_dir}/${model}/*output*"

	[[ ! -d ${model} ]] && mkdir -p ${model}

	for var in ${var_list}; do

		for (( y=${year_start}; y<=${year_end}; y++ )); do

			echo "Extracting variable ${var} from model ${model} for year ${y}..."

			ifile_list=`ls ${fout_model}/*${otype}.${y}*`
			
			for ifile in ${ifile_list}; do

				fdate=`basename ${ifile} | cut -d "." -f 2`
				cdo selvar,${var} ${ifile} ${model}/${var}_${model}_${fdate}.nc

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

done

echo "Job completed!"
#End of script


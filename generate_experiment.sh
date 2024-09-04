#!/bin/bash

# set some variables
export da_nx=8
export da_ny=20
export fc_nx=1
export fc_ny=2
export ensemble_size=80

# set up the main yaml file
# need to add in all the lines for forecast_configuration. Create a tmp file that will be put into the template
rm -f tmpfile
for (( i=1; i<=$ensemble_size; i++ )); do echo "  - {{ forecast_configuration_$i }}" >> tmpfile && export forecast_configuration_$i="testinput/forecast_mem_$i.yaml"; done
missing_lines=$(cat tmpfile)

awk -v addpattern="$missing_lines" '/Forecast configuration:/{print $0 "\n" addpattern;next}1' letkf-top.template > letkf-top-full.template
uw template render --input-file letkf-top-full.template --env --output-file letkf_experiment.yaml

mkdir -p testinput
if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do export run_dir=mem00$i && mkdir -p $run_dir/RESTART && export ensemble_num=$i && uw template render --input-file letkf_c96_forecast_ufs.template --env --output-file testinput/forecast_mem_$i.yaml; done
else
  for (( i=1; i<=9; i++ )); do export run_dir=mem00$i && mkdir -p $run_dir/RESTART && export ensemble_num=$i && uw template render --input-file letkf_c96_forecast_ufs.template --env --output-file testinput/forecast_mem_$i.yaml; done
  for (( i=10; i<=$ensemble_size; i++ )); do export run_dir=mem0$i && mkdir -p $run_dir/RESTART && export ensemble_num=$i && uw template render --input-file letkf_c96_forecast_ufs.template --env --output-file testinput/forecast_mem_$i.yaml; done
fi

# create links to the initial files in INPUT to add ens_xx
if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do for file in mem00$i/INPUT/*res.*; do new=`echo $file | sed "s/res./res.ens_0$i./g"` && ln -s -r $file $new ; done ; done
  for (( i=1; i<=$ensemble_size; i++ )); do for file in mem00$i/INPUT/*data.*; do new=`echo $file | sed "s/data./data.ens_0$i./g"` && ln -s -r $file $new ; done ; done
else
  for (( i=1; i<=9; i++ )); do for file in mem00$i/INPUT/*res.*; do new=`echo $file | sed "s/res./res.ens_0$i./g"` && ln -s -r $file $new ; done ; done
  for (( i=1; i<=9; i++ )); do for file in mem00$i/INPUT/*data.*; do new=`echo $file | sed "s/data./data.ens_0$i./g"` && ln -s -r $file $new ; done ; done
  for (( i=10; i<=$ensemble_size; i++ )); do for file in mem0$i/INPUT/*res.*; do new=`echo $file | sed "s/res./res.ens_$i./g"` && ln -s -r $file $new ; done ; done
  for (( i=10; i<=$ensemble_size; i++ )); do for file in mem0$i/INPUT/*data.*; do new=`echo $file | sed "s/data./data.ens_$i./g"` && ln -s -r $file $new ; done ; done
fi


#create the namelists
if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do run_dir=mem00$i && export iseed_skeb=$((i*3+100)) && export iseed_shum=$((i*3+101)) && export iseed_sppt=$((i*3+102)) && uw template render --input-file input.template --env --output-file $run_dir/input.nml; done
else
  for (( i=1; i<=9; i++ )); do run_dir=mem00$i && export iseed_skeb=$((i*3+100)) && export iseed_shum=$((i*3+101)) && export iseed_sppt=$((i*3+102)) && uw template render --input-file input.template --env --output-file $run_dir/input.nml; done
  for (( i=10; i<=$ensemble_size; i++ )); do run_dir=mem0$i && export iseed_skeb=$((i*3+100)) && export iseed_shum=$((i*3+101)) && export iseed_sppt=$((i*3+102)) && uw template render --input-file input.template --env --output-file $run_dir/input.nml; done
fi

#create ufs.configure files
if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do run_dir=mem00$i && export atm_procs=$((fc_nx*fc_ny*6-1)) && uw template render --input-file ufs.configure.template --env --output-file $run_dir/ufs.configure; done
else
  for (( i=1; i<=9; i++ )); do run_dir=mem00$i && export atm_procs=$((fc_nx*fc_ny*6-1)) && uw template render --input-file ufs.configure.template --env --output-file $run_dir/ufs.configure; done
  for (( i=10; i<=$ensemble_size; i++ )); do run_dir=mem0$i && export atm_procs=$((fc_nx*fc_ny*6-1)) && uw template render --input-file ufs.configure.template --env --output-file $run_dir/ufs.configure; done
fi

if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do ln -s -r c96_data/*  mem00$i; done
else
  for (( i=1; i<=9; i++ )); do ln -s -r c96_data/* mem00$i; done
  for (( i=10; i<=$ensemble_size; i++ )); do ln -s -r c96_data/* mem0$i; done
fi

if [[ $ensemble_size -le 9 ]]; then
  for (( i=1; i<=$ensemble_size; i++ )); do ENS_XX=ens_0$i uw file link --target-dir ./mem00$i/INPUT --config-file input-files.yaml files link; done
else
  for (( i=1; i<=9; i++ )); do ENS_XX=ens_0$i uw file link --target-dir ./mem00$i/INPUT --config-file input-files.yaml files link; done
  for (( i=10; i<=$ensemble_size; i++ )); do ENS_XX=ens_$i uw file link --target-dir ./mem0$i/INPUT --config-file input-files.yaml files link; done
fi



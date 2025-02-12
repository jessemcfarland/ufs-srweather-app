#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHdir/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; . $USHdir/preamble.sh; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that copies or fetches external model
input data from disk, HPSS, or a URL, and stages them to the
workflow-specified location so that they may be used to generate initial
or lateral boundary conditions for the FV3.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set up variables for call to retrieve_data.py
#
#-----------------------------------------------------------------------
#
set -x
if [ "${ICS_OR_LBCS}" = "ICS" ]; then
  if [ ${TIME_OFFSET_HRS} -eq 0 ] ; then
    anl_or_fcst="anl"
  else
    anl_or_fcst="fcst"
  fi
  fcst_hrs=${TIME_OFFSET_HRS}
  file_names=${EXTRN_MDL_FILES_ICS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] ; then
    file_type=$FV3GFS_FILE_FMT_ICS
  fi
  input_file_path=${EXTRN_MDL_SOURCE_BASEDIR_ICS:-$EXTRN_MDL_SYSBASEDIR_ICS}

elif [ "${ICS_OR_LBCS}" = "LBCS" ]; then
  anl_or_fcst="fcst"
  first_time=$((TIME_OFFSET_HRS + LBC_SPEC_INTVL_HRS))
  last_time=$((TIME_OFFSET_HRS + FCST_LEN_HRS))
  fcst_hrs="${first_time} ${last_time} ${LBC_SPEC_INTVL_HRS}"
  file_names=${EXTRN_MDL_FILES_LBCS[@]}
  if [ ${EXTRN_MDL_NAME} = FV3GFS ] ; then
    file_type=$FV3GFS_FILE_FMT_LBCS
  fi
  input_file_path=${EXTRN_MDL_SOURCE_BASEDIR_LBCS:-$EXTRN_MDL_SYSBASEDIR_LBCS}
fi

data_stores="${EXTRN_MDL_DATA_STORES}"

yyyymmddhh=${EXTRN_MDL_CDATE:0:10}
yyyy=${yyyymmddhh:0:4}
yyyymm=${yyyymmddhh:0:6}
yyyymmdd=${yyyymmddhh:0:8}
mm=${yyyymmddhh:4:2}
dd=${yyyymmddhh:6:2}
hh=${yyyymmddhh:8:2}


input_file_path=$(eval echo ${input_file_path})
#
#-----------------------------------------------------------------------
#
# Set up optional flags for calling retrieve_data.py
#
#-----------------------------------------------------------------------
#
additional_flags=""


if [ -n "${file_type:-}" ] ; then 
  additional_flags="$additional_flags \
  --file_type ${file_type}"
fi

if [ -n "${file_names:-}" ] ; then
  additional_flags="$additional_flags \
  --file_templates ${file_names[@]}"
fi

if [ -n "${input_file_path:-}" ] ; then
  data_stores="disk $data_stores"
  additional_flags="$additional_flags \
  --input_file_path ${input_file_path}"
fi

#
#-----------------------------------------------------------------------
#
# Call ush script to retrieve files
#
#-----------------------------------------------------------------------
#
if [ $RUN_ENVIR = "nco" ]; then
    EXTRN_DEFNS="${NET}.${cycle}.${EXTRN_MDL_NAME}.${ICS_OR_LBCS}.${EXTRN_MDL_VAR_DEFNS_FN}.sh"
else
    EXTRN_DEFNS="${EXTRN_MDL_VAR_DEFNS_FN}.sh"
fi
cmd="
python3 -u ${USHdir}/retrieve_data.py \
  --debug \
  --anl_or_fcst ${anl_or_fcst} \
  --config ${PARMdir}/data_locations.yml \
  --cycle_date ${EXTRN_MDL_CDATE} \
  --data_stores ${data_stores} \
  --external_model ${EXTRN_MDL_NAME} \
  --fcst_hrs ${fcst_hrs[@]} \
  --output_path ${EXTRN_MDL_STAGING_DIR} \
  --summary_file ${EXTRN_DEFNS} \
  $additional_flags"

$cmd || print_err_msg_exit "\
Call to retrieve_data.py failed with a non-zero exit status.

The command was:
${cmd}
"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1


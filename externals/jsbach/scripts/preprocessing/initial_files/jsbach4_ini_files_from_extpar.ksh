#!/bin/bash

# ICON-Land
#
# ---------------------------------------
# Copyright (C) 2013-2024, MPI-M, MPI-BGC
#
# Contact: icon-model.org
# Authors: AUTHORS.md
# See LICENSES/ for license information
# SPDX-License-Identifier: BSD-3-Clause
# ---------------------------------------

#-----------------------------------------------------------------------------
# Merge extpar output into jsbach4 boundary condition (bc) files
#
# The script is part of a script series to generate jsbach initial files
#   started by master script "create_jsbach_ini_files.sh"
#
# This script modifies
#   bc_land_frac:
#   - Generates lake, glacier and vegetation fractions from extpar output.
#
#   bc_land_phys:
#   - Calculates albedo, roughness length and forest fraction, as well as
#     monthly climatologies of LAI and vegetation fraction from  extpar data.
#
#   bc_land_soil:
#   - Calculates root depth from extpar data. Deprecated variable maxmoist
#     is adapted.
#   - Soil texture data from extpar (i.e. sand, silt and clay fractions, as
#     well as organic layer fraction) is added.
#
# First version by Thomas Raddatz, MPIM,       Sept. 2022
#
#  Veronika Gayler, MPIM,      April 2023
#      - Adaptations to work with master scipt create_icon-land_ini_files.sh
#      - Corrected netcdf attributes, additional comments
#-----------------------------------------------------------------------------
set -e

# file names and paths (exported from master script create_icon-land_ini_files.sh)
path_extpar=${extpar_dir:-/work/mj0060/m212070/test_extpar4jsbach/extpar4jsbach}
file_extpar=${extpar_file:-icon_extpar4jsbach_20230404.nc}
file_extpar=${file_extpar%.nc}

icon_grid=${icon_grid:-/pool/data/ICON/grids/public/mpim/0043/icon_grid_0043_R02B04_G.nc}

path_bc=${bc_file_dir}_from_gauss
path_bc_new=${bc_file_dir}_with_extpar
start_year=${start_year}
end_year=${end_year}
work_dir=${work_dir}

prog=$(basename $0)
clean_up=true  # Remove intermediate files

# Tools and commands
cdo="cdo -s"
ncatted="ncatted"
rm=/usr/bin/rm
cp=/usr/bin/cp
expr=/usr/bin/expr


# Information for history attribute
git_repo=$(git remote -v | head -1 | cut -f2 | cut -f1 -d' ')
git_rev=$(git rev-parse --short HEAD)
git_branch=$(git log --pretty='format:%h %D' --first-parent | grep HEAD | cut -f4 -d' ' | sed 's/,//')
history_att="$(date): Generated with $prog (${git_repo}:${git_branch} rev. ${git_rev}) by $(whoami)"

# Parameters
value_albedo_max=60. # maximum value of background albedo accepted [%]
value_albedo_min=6.  # minimum value of background albedo accepted [%]
fillvalue_albedo_glac=12.
fillvalue_albedo_coast=12.
lower_bound_NDVI_veg_fract=0.12
upper_bound_NDVI_veg_fract=0.92
upper_bound_veg_fract=0.98
fact_NDVI_veg_fract=1.225 # should be: upper_bound_veg_fract / (upper_bound_NDVI_veg_fract - lower_bound_NDVI_veg_fract)
lower_bound_NDVI_lai_clim=0.12
upper_bound_NDVI_lai_clim=0.8
upper_bound_lai_clim=6.
fact_NDVI_lai_clim=8.8235294 # should be: upper_bound_lai_clim / (upper_bound_NDVI_lai_clim - lower_bound_NDVI_lai_clim)
minimum_root_depth=0.15

min_fract=${min_fract:-0.001} # minimum land grid cell fraction other than 0.

year=${start_year}

[[ -d ${path_bc_new} ]] || mkdir -p ${path_bc_new}
[[ -d ${work_dir} ]]    || mkdir -p ${work_dir}
cd ${work_dir}
echo '------------------------------------------------------------------'
echo "${prog}: Working directory: $(pwd)"
echo "${prog}: Output  directory: ${path_bc_new}"
echo '------------------------------------------------------------------'
echo "${prog}: Generation of boundary condition files: start_year=${start_year}"

file_bc_frac=bc_land_frac_${year}
file_bc_phys=bc_land_phys_${year}
file_bc_soil=bc_land_soil_${year}

# copy boundary condition files and initial condition files
${cp} -p ${path_bc}/${file_bc_frac}.nc      ${file_bc_frac}_orig.nc
${cp} -p ${path_bc}/${file_bc_phys}.nc      ${file_bc_phys}_orig.nc
${cp} -p ${path_bc}/${file_bc_soil}.nc      ${file_bc_soil}_orig.nc

ln -fs ${path_extpar}/${file_extpar}.nc   ${file_extpar}.nc
# ----------------------------------------------------------------------------
#  1. bc fract files
# -----------------------------
# Modify lake fraction
# --------------------
# We use lake fractions from flake (extpar variable FR_LAKE), however the Caspian Sea is
# not counted as lake in this data set. Also other smaller water bodies in that region
# are missing. So lake fractions of Caspian Sea/Aral Lake area are replaced with
# Globcover data (extpar variable LU_CLASS_FRACTION, class 21).
#
# Select extpar field of lake fraction (from flake)
${cdo} selvar,FR_LAKE ${file_extpar}.nc ${file_extpar}_FR_LAKE.nc
# Select extpar field of lake fraction from Globcover
${cdo} -setlevel,0 -setgrid,${icon_grid} -sellevel,21 -selvar,LU_CLASS_FRACTION ${file_extpar}.nc ${file_extpar}_LU21.nc
#   => lake fractions for Caspian Sea and Aral Lake area, missing value elsewhere
${cdo} masklonlatbox,46.,62.,36.,48. ${file_extpar}_LU21.nc ${file_extpar}_LU_CLASS_FRACTION_lev21_casp.nc
# mask: 1 for Caspian Sea and Aral Lake, missing value elsewhere
${cdo} gtc,-1. ${file_extpar}_LU_CLASS_FRACTION_lev21_casp.nc ${file_extpar}_LU_CLASS_FRACTION_mask_casp.nc
# mask: 0 for Caspian Sea and Aral Lake area, 1 elsewhere
${cdo} subc,1. -setmisstoc,2. ${file_extpar}_LU_CLASS_FRACTION_mask_casp.nc ${file_extpar}_LU_CLASS_FRACTION_mask_mul_casp.nc
# lake fraction (from flake) excluding lakes in the Caspian Sea and Aral Lake area
${cdo} mul ${file_extpar}_FR_LAKE.nc ${file_extpar}_LU_CLASS_FRACTION_mask_mul_casp.nc ${file_extpar}_fr_lake_clean.nc
# add Caspian Sea and Aral Lake from Globcover to lake fractions from flake elsewhere
${cdo} add ${file_extpar}_fr_lake_clean.nc -setmisstoc,0. ${file_extpar}_LU_CLASS_FRACTION_lev21_casp.nc \
    ${file_extpar}_fr_lake_casp.nc

# In ICON-Land grid cells with ocean fraction cannot have a lake fraction. Thus lake
# fractions of coastal cells needs to be set to zero.

# Use the original bc_land_fract file to define a mask of land grid boxes without ocean
${cdo} -selvar,notsea ${file_bc_frac}_orig.nc notsea.nc
${cdo} gec,1. notsea.nc ${file_extpar}_fr_land_mask.nc
# Lake fraction just for grid boxes with no ocean ==> this is the new lake fraction
${cdo} chname,FR_LAKE,fract_lake -mul ${file_extpar}_fr_lake_casp.nc ${file_extpar}_fr_land_mask.nc \
      ${file_extpar}_fract_lake.nc
${cdo} chname,fract_lake,lake ${file_extpar}_fract_lake.nc ${file_extpar}_lake.nc

# Adapt the land fraction
# -----------------------
# Land fraction 'land' - relative to the grid cell
${cdo} chname,notsea,land -sub notsea.nc ${file_extpar}_lake.nc ${file_extpar}_land.nc
# Land fraction 'fract_land' - relative to the box tile, i.e. the part of the surface handled
# by ICON-Land (i.e. 'notsea'). It is the fraction that is not lake and is 1 over the ocean.
${cdo} chname,lake,fract_land -addc,1. -mulc,-1. ${file_extpar}_lake.nc ${file_extpar}_fract_land.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_LU_CLASS_FRACTION_lev21_casp.nc \
        ${file_extpar}_LU_CLASS_FRACTION_mask_casp.nc ${file_extpar}_LU_CLASS_FRACTION_mask_mul_casp.nc \
        ${file_extpar}_LU21.nc ${file_extpar}_FR_LAKE.nc ${file_extpar}_fr_lake_clean.nc ${file_extpar}_fr_lake_casp.nc \
        ${file_extpar}_fr_land_mask.nc
fi

# Modify glacier fraction
# -----------------------
# Select extpar field of glacier fraction (from Globcover, relative to the grid cell fraction)
# and convert it relative to the land fraction. We need an integer mask, also at coastal grid cells.
${cdo} div -selvar,ICE ${file_extpar}.nc -selvar,FR_LAND ${file_extpar}.nc ${file_extpar}_glac.nc
${cdo} setmisstoc,0 -gtc,0.5 ${file_extpar}_glac.nc glac.tmp
${cdo} setmisstoc,0 -ifthen -gtc,${min_fract} notsea.nc glac.tmp glac.nc

${cdo} chname,ICE,fract_glac glac.nc ${file_extpar}_fract_glac.nc
${cdo} chname,ICE,glac       glac.nc ${file_extpar}_glac.nc
${cdo}   -addc,1. -mulc,-1.  glac.nc ${file_extpar}_no-glac.nc

# Calculate new vegetation fraction (rel. to the land fraction, i.e. 1-glacier)
${cdo} chname,ICE,fract_veg ${file_extpar}_no-glac.nc ${file_extpar}_fract_veg.nc

# Do not change variables sea and notsea
${cdo} selvar,notsea ${file_bc_frac}_orig.nc ${file_extpar}_notsea.nc
${cdo} selvar,sea    ${file_bc_frac}_orig.nc ${file_extpar}_sea.nc
# Adapt remaining ${file_bc_frac} variables to new glacier mask
${cdo} mul ${file_bc_frac}_orig.nc ${file_extpar}_no-glac.nc ${file_bc_frac}_glac0.nc

# Replace original fractions in bc_frac file with the new variables from extpar
${cdo} -O merge ${file_extpar}_fract_glac.nc  ${file_extpar}_fract_lake.nc  \
                ${file_extpar}_fract_land.nc  ${file_extpar}_fract_veg.nc   \
                ${file_extpar}_land.nc        ${file_extpar}_lake.nc        \
                ${file_extpar}_glac.nc        ${file_extpar}_sea.nc         \
                ${file_extpar}_notsea.nc      ${file_extpar}_new.nc
${cdo} replace ${file_bc_frac}_glac0.nc ${file_extpar}_new.nc  ${file_bc_frac}_extpar.tmp

${cdo} --no_history setattribute,history="${history_att}" ${file_bc_frac}_extpar.tmp \
       ${path_bc_new}/${file_bc_frac}.nc

echo "${prog}:     ${file_bc_frac}.nc         done"

# Currently, only PFT fractions depend on the year
for (( year = ${start_year}; year <= ${end_year}; year++ )); do
  file_bc_frac_pfts=bc_land_frac_11pfts_${year}
  ${cdo} mul ${path_bc}/${file_bc_frac_pfts}.nc ${file_extpar}_no-glac.nc ${file_bc_frac_pfts}_glac0.nc
  ${cdo} replace ${file_bc_frac_pfts}_glac0.nc ${file_extpar}_new.nc  ${file_bc_frac_pfts}_extpar.tmp
  ${cdo} --no_history setattribute,history="${history_att}" ${file_bc_frac_pfts}_extpar.tmp \
         ${path_bc_new}/${file_bc_frac_pfts}.nc

  echo "${prog}:     ${file_bc_frac_pfts}.nc  done"

  if [[ ${clean_up} == true ]]; then
    ${rm} ${file_bc_frac_pfts}_extpar.tmp ${file_bc_frac_pfts}_glac0.nc
  fi
done

# Continue with first year
year=${start_year}

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_fract_glac.nc \
        ${file_extpar}_fract_veg.nc ${file_extpar}_lake.nc ${file_extpar}_land.nc\
        ${file_extpar}_fract_land.nc ${file_extpar}_fract_lake.nc \
        ${file_extpar}_notsea.nc ${file_extpar}_sea.nc notsea.nc glac.tmp glac.nc
  ${rm} ${file_bc_frac}_glac0.nc ${file_bc_frac}_extpar.tmp ${file_bc_frac}_orig.nc
fi

# ----------------------------------------------------------------------------
#  2. bc_soil file
# -----------------------------
# Soil texture
# ------------
# Add soil texture variables to bc_soil-file

# Upper 30 cm of the soil column
#--------------------------------
# Convert from percent to fraction and remove 'institution' attribute (i.e. DWD)
${cdo} mulc,0.01 -selvar,FR_SAND ${file_extpar}.nc ${file_extpar}_FR_SAND.nc
${ncatted} -a institution,global,d,c,sng           ${file_extpar}_FR_SAND.nc
${cdo} mulc,0.01 -selvar,FR_SILT ${file_extpar}.nc ${file_extpar}_FR_SILT.nc
${ncatted} -a institution,global,d,c,sng           ${file_extpar}_FR_SILT.nc
${cdo} mulc,0.01 -selvar,FR_CLAY ${file_extpar}.nc ${file_extpar}_FR_CLAY.nc
${ncatted} -a institution,global,d,c,sng           ${file_extpar}_FR_CLAY.nc

# Mask out grid cells where any of the texture variables is missing
${cdo} gec,0. ${file_extpar}_FR_SAND.nc ${file_extpar}_FR_SAND_MASK.nc
${cdo} gec,0. ${file_extpar}_FR_SILT.nc ${file_extpar}_FR_SILT_MASK.nc
${cdo} gec,0. ${file_extpar}_FR_CLAY.nc ${file_extpar}_FR_CLAY_MASK.nc
${cdo} -O ensmin \
       ${file_extpar}_FR_SAND_MASK.nc ${file_extpar}_FR_SILT_MASK.nc ${file_extpar}_FR_CLAY_MASK.nc \
       ${file_extpar}_SAND_SILT_CLAY_MASK.nc

# Apply this mask to the texture data
${cdo} mul ${file_extpar}_FR_SAND.nc ${file_extpar}_SAND_SILT_CLAY_MASK.nc ${file_extpar}_FR_SAND_0.nc
${cdo} mul ${file_extpar}_FR_SILT.nc ${file_extpar}_SAND_SILT_CLAY_MASK.nc ${file_extpar}_FR_SILT_0.nc
${cdo} mul ${file_extpar}_FR_CLAY.nc ${file_extpar}_SAND_SILT_CLAY_MASK.nc ${file_extpar}_FR_CLAY_0.nc

# Fill data gaps with 50 percent sand, 25 precent silt and 25 percent clay fraction
${cdo} add ${file_extpar}_FR_SAND_0.nc -mulc,-0.5  -addc,-1. ${file_extpar}_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_FR_SAND_CORRECTED.nc
${cdo} add ${file_extpar}_FR_SILT_0.nc -mulc,-0.25 -addc,-1. ${file_extpar}_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_FR_SILT_CORRECTED.nc
${cdo} add ${file_extpar}_FR_CLAY_0.nc -mulc,-0.25 -addc,-1. ${file_extpar}_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_FR_CLAY_CORRECTED.nc

# Deeper soil (below 30 cm)
#--------------------------
# Convert from percent to fraction and remove institution attribute (i.e. DWD)
${cdo} mulc,0.01 -selvar,SUB_FR_SAND ${file_extpar}.nc ${file_extpar}_SUB_FR_SAND.nc
${ncatted} -a institution,global,d,c,sng               ${file_extpar}_SUB_FR_SAND.nc
${cdo} mulc,0.01 -selvar,SUB_FR_SILT ${file_extpar}.nc ${file_extpar}_SUB_FR_SILT.nc
${ncatted} -a institution,global,d,c,sng               ${file_extpar}_SUB_FR_SILT.nc
${cdo} mulc,0.01 -selvar,SUB_FR_CLAY ${file_extpar}.nc ${file_extpar}_SUB_FR_CLAY.nc
${ncatted} -a institution,global,d,c,sng               ${file_extpar}_SUB_FR_CLAY.nc

# Mask out grid cells where any of the texture variables is missing
${cdo} gec,0. ${file_extpar}_SUB_FR_SAND.nc ${file_extpar}_SUB_FR_SAND_MASK.nc
${cdo} gec,0. ${file_extpar}_SUB_FR_SILT.nc ${file_extpar}_SUB_FR_SILT_MASK.nc
${cdo} gec,0. ${file_extpar}_SUB_FR_CLAY.nc ${file_extpar}_SUB_FR_CLAY_MASK.nc
${cdo} -O ensmin \
       ${file_extpar}_SUB_FR_SAND_MASK.nc ${file_extpar}_SUB_FR_SILT_MASK.nc ${file_extpar}_SUB_FR_CLAY_MASK.nc \
       ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc

# Apply this mask to the texture data
${cdo} mul ${file_extpar}_SUB_FR_SAND.nc ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc ${file_extpar}_SUB_FR_SAND_0.nc
${cdo} mul ${file_extpar}_SUB_FR_SILT.nc ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc ${file_extpar}_SUB_FR_SILT_0.nc
${cdo} mul ${file_extpar}_SUB_FR_CLAY.nc ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc ${file_extpar}_SUB_FR_CLAY_0.nc

# Fill data gaps with 50 percent sand, 25 precent silt and 25 percent clay fraction
${cdo} add ${file_extpar}_SUB_FR_SAND_0.nc -mulc,-0.5  -addc,-1. ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_SUB_FR_SAND_CORRECTED.nc
${cdo} add ${file_extpar}_SUB_FR_SILT_0.nc -mulc,-0.25 -addc,-1. ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_SUB_FR_SILT_CORRECTED.nc
${cdo} add ${file_extpar}_SUB_FR_CLAY_0.nc -mulc,-0.25 -addc,-1. ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc \
           ${file_extpar}_SUB_FR_CLAY_CORRECTED.nc

# Note: organic fractions are currently used from 0.5 deg data set derived from WISE data base
#       and not treated here.
# # Organic compounds
# #------------------
# # Convert from percent to fraction and replace missing data with a fraction of zero
# ${cdo} mulc,0.01 -selvar,FR_OC ${file_extpar}.nc ${file_extpar}_FR_OC.nc
# ${cdo} maxc,0. ${file_extpar}_FR_OC.nc   ${file_extpar}_FR_OC_CORRECTED.nc
# ${ncatted} -a institution,global,d,c,sng ${file_extpar}_FR_OC_CORRECTED.nc
#
# ${cdo} mulc,0.01 -selvar,SUB_FR_OC ${file_extpar}.nc ${file_extpar}_SUB_FR_OC.nc
# ${cdo} maxc,0. ${file_extpar}_SUB_FR_OC.nc ${file_extpar}_SUB_FR_OC_CORRECTED.nc
# ${ncatted} -a institution,global,d,c,sng   ${file_extpar}_SUB_FR_OC_CORRECTED.nc


# Set soil parameters to zero in glacier areas to avoid confusion
# ---------------------------
${cdo} ifnotthen ${file_extpar}_glac.nc ${file_bc_soil}_orig.nc ${file_bc_soil}_no-glac.nc
${cdo} setmisstoc,0 ${file_bc_soil}_no-glac.nc ${file_bc_soil}_glac0.nc
${cdo} ifthenelse ${file_extpar}_glac.nc ${file_bc_soil}_glac0.nc ${file_bc_soil}_orig.nc \
       ${file_bc_soil}_orig_glac0.nc

# Root depth
# -----------
# Use root depth from extpar and make sure, it is smaller than (original) soil depth.

# Select extpar field of root depth
${cdo} selvar,ROOTDP ${file_extpar}.nc ${file_extpar}_ROOTDP.nc
# Select soil depth from original bc soil file, set glacier values to 0.5
${cdo} selvar,soil_depth ${file_bc_soil}_orig_glac0.nc ${file_bc_soil}_soil_depth.tmp
${cdo} add ${file_bc_soil}_soil_depth.tmp -mulc,0.5 ${file_extpar}_glac.nc \
       ${file_bc_soil}_soil_depth.nc
# Limit extpar root depth to soil depth
${cdo} min ${file_extpar}_ROOTDP.nc ${file_bc_soil}_soil_depth.nc ${file_extpar}_ROOTDP_corrected.nc
# Set minimum root depth
${cdo} maxc,${minimum_root_depth} ${file_extpar}_ROOTDP_corrected.nc ${file_extpar}_ROOTDP_corrected2.nc
# Change variable name
${cdo} chname,ROOTDP,root_depth ${file_extpar}_ROOTDP_corrected2.nc ${file_extpar}_root_depth.nc

# Additionally calculate root depth from Gaussian grid data
# (TODO: should no longer be needed once extpar data is approved)
${cdo} selvar,root_depth ${file_bc_soil}_orig_glac0.nc ${file_bc_soil}_root_depth.nc
# Set glacier values to 0.15 (minimum value for root depth)
${cdo} add ${file_bc_soil}_root_depth.nc -mulc,0.15 ${file_extpar}_glac.nc \
       ${file_extpar}_root_depth.gauss.nc


# Maxmoist: water content of the rootzone at field capacity
# --------
# Note: maxmoist is no longer read from initial files in recent ICON-Land hydrology versions
# as it depends on soil texture and organic layer fractions. It is calculated at runtime
# from field capacity and root depth. For backward compatibility we re-calculate it here to
# be consistent with root depth.

# Select field capacity from original bc soil file
${cdo} selvar,soil_field_cap ${file_bc_soil}_orig_glac0.nc ${file_bc_soil}_soil_field_cap.nc
# Calculate maxmoist
${cdo} chname,soil_field_cap,maxmoist \
       -mul ${file_bc_soil}_soil_field_cap.nc ${file_extpar}_root_depth.nc \
       ${file_extpar}_maxmoist.nc
# Additionally calculate maxmoist based on Gaussian grid root depth
# (TODO: should no longer be needed once extpar data is approved)
${cdo} chname,soil_field_cap,maxmoist \
       -mul ${file_bc_soil}_soil_field_cap.nc ${file_extpar}_root_depth.gauss.nc \
       ${file_extpar}_maxmoist.gauss.nc


# Merge extpar soil texture data into the existing bc soil file and replace root_depth and maxmoist
#-------------------------
${cdo} -O merge ${file_extpar}_FR_SAND_CORRECTED.nc     \
                ${file_extpar}_FR_SILT_CORRECTED.nc     \
                ${file_extpar}_FR_CLAY_CORRECTED.nc     \
                ${file_extpar}_SUB_FR_SAND_CORRECTED.nc \
                ${file_extpar}_SUB_FR_SILT_CORRECTED.nc \
                ${file_extpar}_SUB_FR_CLAY_CORRECTED.nc   ${file_extpar}_texture.nc
${cdo} -O merge ${file_bc_soil}_orig_glac0.nc ${file_extpar}_texture.nc ${file_bc_soil}_extpar.tmp0
${cdo} replace  ${file_bc_soil}_extpar.tmp0 ${file_bc_soil}_soil_depth.nc ${file_bc_soil}_extpar.tmp
${cdo} -O merge ${file_extpar}_root_depth.nc \
                ${file_extpar}_maxmoist.nc   ${file_extpar}_new.nc
${cdo} replace  ${file_bc_soil}_extpar.tmp ${file_extpar}_new.nc ${file_bc_soil}_extpar.tmp1

${cdo} --no_history setattribute,history="${history_att}" ${file_bc_soil}_extpar.tmp1 \
       ${path_bc_new}/${file_bc_soil}.nc

echo "${prog}:     ${file_bc_soil}.nc         done"

# Additionaly generate a bc_land_soil file with original root_depth (and maxmoist)
# Todo: Check, if root depth from extpar also works with PFT usecase of jsbach
${cdo} -O merge ${file_extpar}_root_depth.gauss.nc \
                ${file_extpar}_maxmoist.gauss.nc   ${file_extpar}_new.gauss.nc
${cdo} replace  ${file_bc_soil}_extpar.tmp ${file_extpar}_new.gauss.nc ${file_bc_soil}_extpar_11pfts.tmp
${cdo} --no_history setattribute,history="${history_att}" ${file_bc_soil}_extpar_11pfts.tmp \
       ${path_bc_new}/${file_bc_soil%_*}_11pfts_${year}.nc
echo "${prog}:     ${file_bc_soil%_*}_11pfts_${year}.nc  done"

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_FR_SAND.nc ${file_extpar}_FR_CLAY.nc ${file_extpar}_FR_SILT.nc \
        ${file_extpar}_SUB_FR_SAND.nc ${file_extpar}_SUB_FR_SILT.nc ${file_extpar}_SUB_FR_CLAY.nc
  ${rm} ${file_extpar}_FR_SAND_MASK.nc ${file_extpar}_FR_SILT_MASK.nc ${file_extpar}_FR_CLAY_MASK.nc \
        ${file_extpar}_SUB_FR_SAND_MASK.nc ${file_extpar}_SUB_FR_SILT_MASK.nc ${file_extpar}_SUB_FR_CLAY_MASK.nc
  ${rm} ${file_extpar}_SAND_SILT_CLAY_MASK.nc ${file_extpar}_SUB_SAND_SILT_CLAY_MASK.nc
  ${rm} ${file_extpar}_FR_????_0.nc ${file_extpar}_SUB_FR_????_0.nc ${file_extpar}_FR_????_CORRECTED.nc \
        ${file_extpar}_SUB_FR_????_CORRECTED.nc
  ${rm} ${file_extpar}_ROOTDP.nc ${file_extpar}_ROOTDP_corrected.nc ${file_bc_soil}_root_depth.nc \
        ${file_extpar}_ROOTDP_corrected2.nc ${file_extpar}_root_depth.nc ${file_bc_soil}_soil_field_cap.nc \
        ${file_extpar}_maxmoist.nc ${file_extpar}_glac.nc ${file_bc_soil}_soil_depth.tmp ${file_bc_soil}_soil_depth.nc
  ${rm} ${file_extpar}_texture.nc ${file_extpar}_new.nc ${file_bc_soil}_extpar.tmp* ${file_bc_soil}_extpar_11pfts.tmp \
        ${file_bc_soil}_glac0.nc ${file_bc_soil}_no-glac.nc ${file_extpar}_no-glac.nc \
        ${file_extpar}_maxmoist.gauss.nc ${file_extpar}_root_depth.gauss.nc ${file_extpar}_new.gauss.nc
  ${rm} ${file_bc_soil}_orig.nc ${file_bc_soil}_orig_glac0.nc
fi

# ----------------------------------------------------------------------------
#  3. bc_phys file
# -----------------------------
# Roughness length
# ----------------
# Select extpar field of roughness length
${cdo} selvar,Z0 ${file_extpar}.nc ${file_extpar}_Z0.nc
# Change variable name
${cdo} chname,Z0,roughness_length ${file_extpar}_Z0.nc ${file_extpar}_roughness_length.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_Z0.nc
fi

# Albedo
# -------
# Remove very high albedo of incorrect glacier points
${cdo} selvar,ALB ${file_extpar}.nc ${file_extpar}_ALB.nc
${cdo} ltc,${value_albedo_max} ${file_extpar}_ALB.nc ${file_extpar}_ALB_mask_glac.nc
${cdo} mul ${file_extpar}_ALB.nc ${file_extpar}_ALB_mask_glac.nc ${file_extpar}_ALB_glac0.nc
${cdo} setmisstoc,${fillvalue_albedo_glac} -setctomiss,0. ${file_extpar}_ALB_glac0.nc ${file_extpar}_ALB_noglac.nc
# Remove very low albedo at the coast
${cdo} gtc,${value_albedo_min} ${file_extpar}_ALB_noglac.nc ${file_extpar}_ALB_noglac_mask_coast.nc
${cdo} mul ${file_extpar}_ALB_noglac.nc ${file_extpar}_ALB_noglac_mask_coast.nc ${file_extpar}_ALB_noglac_coast0.nc
${cdo} setmisstoc,${fillvalue_albedo_coast} -setctomiss,0. ${file_extpar}_ALB_noglac_coast0.nc ${file_extpar}_ALB_noglac_nocoast.nc
# Average in time (weighted by days per month) and divide by 100 ([% reflection] ==> [albedo])
${cdo} -divc,100. -yearmonmean ${file_extpar}_ALB_noglac_nocoast.nc ${file_extpar}_ALB_noglac_nocoast_mean.nc
# Change variable name
${cdo} chname,ALB,albedo ${file_extpar}_ALB_noglac_nocoast_mean.nc ${file_extpar}_albedo.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_ALB.nc ${file_extpar}_ALB_mask_glac.nc ${file_extpar}_ALB_glac0.nc \
  ${file_extpar}_ALB_noglac.nc ${file_extpar}_ALB_noglac_mask_coast.nc ${file_extpar}_ALB_noglac_coast0.nc \
  ${file_extpar}_ALB_noglac_nocoast.nc ${file_extpar}_ALB_noglac_nocoast_mean.nc
fi

# Forest fraction
# ---------------
# Decidiuous forest
${cdo} selvar,FOR_D ${file_extpar}.nc ${file_extpar}_FOR_D.nc
# Evergreen forest
${cdo} selvar,FOR_E ${file_extpar}.nc ${file_extpar}_FOR_E.nc
# All forest
${cdo} add ${file_extpar}_FOR_D.nc ${file_extpar}_FOR_E.nc ${file_extpar}_FOR.nc
${cdo} chname,FOR_D,forest_fract ${file_extpar}_FOR.nc ${file_extpar}_forest.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_FOR_D.nc ${file_extpar}_FOR_E.nc ${file_extpar}_FOR.nc
fi

# NDVI: Vegetation fraction
# -------------------------
${cdo} selvar,NDVI ${file_extpar}.nc ${file_extpar}_NDVI.nc
# NDVI ==> veg_fract
${cdo} gtc,${lower_bound_NDVI_veg_fract} ${file_extpar}_NDVI.nc ${file_extpar}_NDVI_l_mask.nc
${cdo} setmisstoc,${lower_bound_NDVI_veg_fract} -setctomiss,0. \
      -mul ${file_extpar}_NDVI.nc ${file_extpar}_NDVI_l_mask.nc  ${file_extpar}_NDVI_l_bound.nc
${cdo} ltc,${upper_bound_NDVI_veg_fract} ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_u_mask.nc
${cdo} setmisstoc,${upper_bound_NDVI_veg_fract} -setctomiss,0. \
      -mul ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_u_mask.nc  ${file_extpar}_NDVI_bound.nc
${cdo} subc,${lower_bound_NDVI_veg_fract} ${file_extpar}_NDVI_bound.nc ${file_extpar}_NDVI_zero.nc
${cdo} setctomiss,0. -gtc,0. ${file_extpar}_NDVI_zero.nc ${file_extpar}_NDVI_zero_mask.nc
${cdo} setmisstoc,0. -mul ${file_extpar}_NDVI_zero.nc ${file_extpar}_NDVI_zero_mask.nc ${file_extpar}_NDVI_no_neg.nc
${cdo} mulc,${fact_NDVI_veg_fract} ${file_extpar}_NDVI_no_neg.nc ${file_extpar}_NDVI_veg_fract.nc
${cdo} chname,NDVI,veg_fract ${file_extpar}_NDVI_veg_fract.nc ${file_extpar}_veg_fract.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_NDVI_l_mask.nc ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_u_mask.nc \
        ${file_extpar}_NDVI_bound.nc ${file_extpar}_NDVI_veg_fract.nc ${file_extpar}_NDVI_zero.nc \
        ${file_extpar}_NDVI_zero_mask.nc ${file_extpar}_NDVI_no_neg.nc
fi

# NDVI: LAI climatology
# ---------------------
${cdo} gtc,${lower_bound_NDVI_lai_clim} ${file_extpar}_NDVI.nc ${file_extpar}_NDVI_l_mask.nc
${cdo} setmisstoc,${lower_bound_NDVI_lai_clim} -setctomiss,0. \
      -mul ${file_extpar}_NDVI.nc ${file_extpar}_NDVI_l_mask.nc  ${file_extpar}_NDVI_l_bound.nc
${cdo} ltc,${upper_bound_NDVI_lai_clim} ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_u_mask.nc
${cdo} setmisstoc,${upper_bound_NDVI_lai_clim} -setctomiss,0. \
      -mul ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_u_mask.nc  ${file_extpar}_NDVI_bound.nc
${cdo} subc,${lower_bound_NDVI_lai_clim} ${file_extpar}_NDVI_bound.nc ${file_extpar}_NDVI_zero.nc
${cdo} setctomiss,0. -gtc,0. ${file_extpar}_NDVI_zero.nc ${file_extpar}_NDVI_zero_mask.nc
${cdo} setmisstoc,0. -mul ${file_extpar}_NDVI_zero.nc ${file_extpar}_NDVI_zero_mask.nc ${file_extpar}_NDVI_no_neg.nc
${cdo} mulc,${fact_NDVI_lai_clim} ${file_extpar}_NDVI_no_neg.nc ${file_extpar}_NDVI_lai_clim.nc
${cdo} chname,NDVI,lai_clim ${file_extpar}_NDVI_lai_clim.nc ${file_extpar}_lai_clim.nc

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_NDVI.nc ${file_extpar}_NDVI_bound.nc ${file_extpar}_NDVI_lai_clim.nc \
        ${file_extpar}_NDVI_l_bound.nc ${file_extpar}_NDVI_l_mask.nc ${file_extpar}_NDVI_no_neg.nc \
        ${file_extpar}_NDVI_u_mask.nc ${file_extpar}_NDVI_zero_mask.nc ${file_extpar}_NDVI_zero.nc
fi

# Replace new variables from extpar with original fractions in bc_frac file
${cdo} -O merge ${file_extpar}_roughness_length.nc ${file_extpar}_albedo.nc ${file_extpar}_forest.nc \
                ${file_extpar}_new.nc
${cdo} replace ${file_bc_phys}_orig.nc ${file_extpar}_new.nc ${file_bc_phys}_extpar.tmp
${cdo} -O merge ${file_extpar}_veg_fract.nc ${file_extpar}_lai_clim.nc  \
                ${file_extpar}_new_clim.nc
${cdo} replace ${file_bc_phys}_extpar.tmp ${file_extpar}_new_clim.nc  ${file_bc_phys}_extpar.tmp1

${cdo} --no_history setattribute,history="${history_att}" ${file_bc_phys}_extpar.tmp1 \
       ${path_bc_new}/${file_bc_phys}.nc

echo "${prog}:     ${file_bc_phys}.nc         done"

# Clean up
if [[ ${clean_up} == true ]]; then
  ${rm} ${file_extpar}_roughness_length.nc ${file_extpar}_albedo.nc ${file_extpar}_forest.nc \
        ${file_extpar}_veg_fract.nc ${file_extpar}_lai_clim.nc ${file_extpar}_new.nc ${file_extpar}_new_clim.nc \
        ${file_bc_phys}_extpar.tmp ${file_bc_phys}_extpar.tmp1 ${file_bc_phys}_orig.nc
fi

if [[ ${clean_up} == true ]]; then
 ${rm} ${file_extpar}.nc
 cd ..
 rmdir ${work_dir}
fi

echo "${prog}:  done"
echo "------------------------------------------------------------------"

exit 0
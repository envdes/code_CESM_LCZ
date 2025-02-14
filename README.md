# code_CESM_LCZ

## Introduction

This repository is supplementary to the manuscript "**Enhancing Global-Scale Urban Land Cover Representation Using Local Climate Zones in the Community Earth System Model**".

The objectives of this project are:

- Modify CESM source code to incorporate built LCZ representation in a modular way;
- Validate model performance with the new LCZ scheme using [Urban-PLUMBER](https://urban-plumber.github.io/) data;
- Examine model sensitivity to LCZ urban parameters.



## Scripts and data

### [1_code_modification](./1_code_modification)

The standard source code comes from [CTSM](https://github.com/ESCOMP/CTSM), with the release tag: [ctsm5.2.005](https://github.com/ESCOMP/CTSM/tree/ctsm5.2.005). See modified code lines labeled with **!YS**.

- Add a new command `use_lcz` to the namelist for case build:
  - [‎bld/namelist_files/namelist_definition_ctsm.xml](./1_code_modification/bld/namelist_files/namelist_definition_ctsm.xml)

- Apply `use_lcz` to determine land cover classification:
  - [src/main/landunit_varcon.F90](./1_code_modification/src/main/landunit_varcon.F90)
  - [src/main/initGridCellsMod.F90](./1_code_modification/src/main/initGridCellsMod.F90)
  - [src/main/subgridMod.F90](./1_code_modification/src/main/subgridMod.F90)
- Define LCZ classes:
  - [src/main/LandunitType.F90](./1_code_modification/src/main/LandunitType.F90)
- Modify the PIO process for a time-varying urban variable `T_BUILDING_MAX`:
  - [src/cpl/share_esmf/UrbanTimeVarType.F90](./1_code_modification/src/cpl/share_esmf/UrbanTimeVarType.F90)
  - [src/cpl/mct/UrbanTimeVarType.F90](./1_code_modification/src/cpl/mct/UrbanTimeVarType.F90)

- Modify subgrid-level:

  - [src/dyn_subgrid/dynInitColumnsMod.F90](./1_code_modification/src/dyn_subgrid/dynInitColumnsMod.F90)

- Apply `use_lcz` when controlling model set-up:

  - [src/main/clm_varctl.F90](./1_code_modification/src/main/clm_varctl.F90)

  - [src/main/controlMod.F90](./1_code_modification/src/main/controlMod.F90)

## [2_simulation_output_analysis](./2_simulation_output_analysis)

The scripts listed below are used for processing simulation output and visualization

| Num. | Subject                                                      | Simulation                      | Output data process                                          | Visualization                                                |
| ---- | ------------------------------------------------------------ | ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 2.1  | [Flux variations at the UK-KingsCollege site](./2_simulation_output_analysis/2.1_KingsCollege_site) | CNTL, WRF_LCZ, LI_LCZ           | Use [Export.ipynb](./2_simulation_output_analysis/2.1_KingsCollege_site/Export.ipynb) to get [export_uk_kingscollege_df.csv](2_simulation_output_analysis/2.1_KingsCollege_site/export_uk_kingscollege_df.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.1_KingsCollege_site/Figure.ipynb) |
| 2.2  | [Taylor diagram over all flux sites](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site) | CNTL, WRF_LCZ, LI_LCZ           | Use [Export.ipynb](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site/Export.ipynb) to get [results4taylor.csv](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site/results4taylor.csv) | [Figure.ipynb](././2_simulation_output_analysis/2.2_Taylor_diagram_over_site/Figure.ipynb) |
| 2.3  | [Overall model performance](./2_simulation_output_analysis/2.3_overall_model_performance) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ | Use [Export_ahf.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Export_ahf.ipynb) and [Export_flux.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Export_flux.ipynb) to get [ahf.csv](././2_simulation_output_analysis/2.3_overall_model_performance/data_for_figure/ahf.csv) and [flux.csv](././2_simulation_output_analysis/2.3_overall_model_performance/data_for_figure/flux.csv), respectively | [Figure.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Figure.ipynb) |
| 2.4  | [Model sensitivity to parameters](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters) | BASE, SENS                      | Use [Export.ipynb](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/Export.ipynb) to get [result.csv](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/result.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/Figure.ipynb) |
| 2.5  | [Variations in anthropogenic heat flux](./2_simulation_output_analysis/2.5_variations_in_ahf) | BASE, SENS                      | Use [Export.ipynb](./2_simulation_output_analysis/2.5_variations_in_ahf/Export.ipynb) to get [ahf.csv](./2_simulation_output_analysis/2.5_variations_in_ahf/ahf.csv) and [qh.csv](./2_simulation_output_analysis/2.5_variations_in_ahf/qh.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.5_variations_in_ahf/Figure.ipynb) |

## [3_illustration](./3_illustration)

The figures listed below are used to illustrate details of implementing built LCZ in CLMU.

| Subject                                                      | Visualization                                   |
| ------------------------------------------------------------ | ----------------------------------------------- |
| CLM5 representation hierarchy with default and LCZ classes   | [Figure](./3_illustration/clm5.pdf)             |
| A modular way of incorporating LCZ alongside the default scheme | [Figure](./3_illustration/use_lcz.pdf)          |
| Future directions                                            | [Figure](./3_illustration/future_direction.pdf) |

## [4_supplimentary_information](./4_supplimentary_information)

The scripts listed below are used to show supplementary information such as input data and output variations over sites.

| Num. | Subject                                                      | Simulation                       | Output data process                                          | Visualization                                                |
| ---- | ------------------------------------------------------------ | -------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 4.1  | [Flux tower locations](./4_supplimentary_information/4.1_flux_tower_locations) | NA                               | NA                                                           | [Figure.ipynb](./4_supplimentary_information/4.1_flux_tower_locations/Figure.ipynb) |
| 4.2  | [Sensible heat flux over sites](./4_supplimentary_information/4.2_sensible_heat_flux) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ  | Use *csv from [output](./4_supplimentary_information/4.2_flux_varaibles_over_sites/output) | [Figure.ipynb](./4_supplimentary_information/4.2_sensible_heat_flux/Figure.ipynb) |
| 4.3  | [Momentum flux sensitivity to roughness length](./4_supplimentary_information/4.3_momemtum_flux_sensitivity) | BASE, SENS1, SENS2, SENS3, SENS4 | Use [Export.ipynb](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/Export.ipynb) to get [result.csv](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/result.csv) | [Figure.ipynb](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/Figure.ipynb) |
| 4.4  | [Flux variables over sites](./4_supplimentary_information/4.4_flux_varaibles_over_sites) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ  | Use [Export.ipynb](./4_supplimentary_information/4.4_flux_varaibles_over_sites/Export.ipynb) to get *csv stored in [output](./4_supplimentary_information/4.4_flux_varaibles_over_sites/output/) | [Figure.ipynb](./4_supplimentary_information/4.4_flux_varaibles_over_sites/Figure.ipynb) |

## [5_generate_LCZ_inputs](./5_generate_LCZ_inputs)

The scripts listed below are used to generate LCZ-based land surface inputs for simulations. **Note:** For LCZ simulations, we set **nlevurb = 5**. 

| Num. | Simulation | Input data process                                           |
| ---- | ---------- | ------------------------------------------------------------ |
| 5.1  | WRF_LCZ    | [WRF_LCZ.ipynb](./5_generate_LCZ_inputs/5.1_WRF_LCZ/WRF_LCZ.ipynb) |
| 5.2  | LI_LCZ     | [LI_LCZ.ipynb](./5_generate_LCZ_inputs/5.2_LI_LCZ/LI_LCZ.ipynb) |
| 5.3  | CESM_LCZ   | [CESM_LCZ.ipynb](./5_generate_LCZ_inputs/5.3_CESM_LCZ/CESM_LCZ.ipynb) |
| 5.4  | BASE       | [BASE.ipynb](./5_generate_LCZ_inputs/5.4_BASE/BASE.ipynb)    |
| 5.5  | SENS       | [SENS.ipynb](./5_generate_LCZ_inputs/5.5_SENS/SENS.ipynb)    |

## [6_sourcemods_for_UrbanPLUMBER](./6_sourcemods_for_UrbanPLUMBER)

The scripts listed below modify source code to use several parameters provided by Urban-PLUMBER. Lines between **!KO** are modified by [K. W. O.](https://staff.ucar.edu/users/oleson) while **!YS** by [Y. S.](https://github.com/YuanSun-UoM).

- Modifiy the `nlevurb`:
  - [clm_varpar.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/clm_varpar.F90)
- Add a new parameter `wall_to_plan_area_ratio`:
  - [LandunitType.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/LandunitType.F90)
  - [UrbanParamsType.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/UrbanParamsType.F90)
- Determine air conditioning adoption:
  - [UrbanTimeVarType.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/UrbanTimeVarType.F90)
- Other:
  - [SurfaceAlbedoMod.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/SurfaceAlbedoMod.F90)
  - [WaterStateType.F90](./6_sourcemods_for_UrbanPLUMBER/SourceMods/src.clm/WaterStateType.F90) 

## Acknowledgments

- We dedicate this work to the memory of Dr. Jason Ching, whose groundbreaking contributions and inspiring vision laid the foundation for this research. His legacy continues to guide and inspire us. 
- This work used the [ARCHER2 UK National Supercomputing Service](https://www.archer2.ac.uk) and [JASMIN, the UK’s collaborative data analysis environment](https://www.jasmin.ac.uk/). This work was supported by the Natural Environment Research Council, UK.
- The authors would like to acknowledge the assistance of Research IT and the use of the HPC Pool and Computational Shared Facility at The University of Manchester. The support of [Dr. Douglas Lowe](https://github.com/douglowe) and Christopher Grave from Research IT at The University of Manchester is gratefully acknowledged. 
- We thank Prof. David M. Schultz for his comments on an earlier version of the manuscript.
- Additionally, we appreciate the assistance of Dr. Congyuan Li at the National University of Defense Technology in China.
- [Z. Z.](https://github.com/zhonghua-zheng) appreciates the support provided by the academic start-up funds from the Department of Earth and Environmental Sciences at The University of Manchester.
- [Y. S.](https://github.com/YuanSun-UoM) is supported by the PhD studentship of Zhonghua Zheng's academic start-up funds.
- Contributions from [K. W. O.](https://staff.ucar.edu/users/oleson) are based upon work supported by the NSF National Center for Atmospheric Research, which is a major facility sponsored by the U.S. National Science Foundation under Cooperative Agreement No. 1852977.
- Contributions from [M. D.](https://github.com/matthiasdemuzere) are supported by the European Union’s HORIZON Research and Innovation Actions under grant agreement No. 101137851, project [CARMINE (Climate-Resilient Development Pathways in Metropolitan Regions of Europe)](https://www.carmine-project.eu/).
- L. Z. acknowledges the support of the US National Science Foundation (CAREER award grant no. 2145362).
- The authors declare no conflict of interest.
# code_CESM_LCZ
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14883318.svg)](https://doi.org/10.5281/zenodo.14883318)
## Introduction

This repository is supplementary to the paper "Sun, Y., Oleson, K. W., Zhao, L., Mills, G., He, C., Demuzere, M., Topping, D. O., Zhang, N., & Zheng, Z. (2025). Enhancing Global-Scale Urban Land Cover Representation Using Local Climate Zones in the Community Earth System Model. *Journal of Advances in Modeling Earth Systems*, 17(11), e2025MS004934. [https://doi.org/10.1029/2025MS004934](https://doi.org/10.1029/2025MS004934)". A related dataset is open access at: [https://doi.org/10.6084/m9.figshare.30665966](https://doi.org/10.6084/m9.figshare.30665966).

The objectives of this project are:

- Modify the CESM source code to incorporate built LCZ representation in a modular way;
- Validate model performance with the new LCZ scheme using [Urban-PLUMBER](https://urban-plumber.github.io/) data;
- Examine model sensitivity to LCZ urban parameters.



## Scripts and data

### [1_code_modification](./1_code_modification)

The standard source code comes from [CTSM](https://github.com/ESCOMP/CTSM), with the release tag: [ctsm5.2.005](https://github.com/ESCOMP/CTSM/tree/ctsm5.2.005). See modified code lines labeled with **!YS**.

- Add a new command `use_lcz,` to the namelist for case build:
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

| Num. | Subject                                                      | Simulations                     | Output data process                                          | Visualization                                                |
| ---- | ------------------------------------------------------------ | ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 2.1  | [Flux variations at the UK-KingsCollege site](./2_simulation_output_analysis/2.1_KingsCollege_site) | CNTL, WRF_LCZ, LI_LCZ           | Use [Export.ipynb](./2_simulation_output_analysis/2.1_KingsCollege_site/Export.ipynb) to get [export_uk_kingscollege_df.csv](2_simulation_output_analysis/2.1_KingsCollege_site/data_for_figure/export_uk_kingscollege_df.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.1_KingsCollege_site/Figure.ipynb) |
| 2.2  | [Taylor diagram over all flux sites](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site) | CNTL, WRF_LCZ, LI_LCZ           | Use [Export.ipynb](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site/Export.ipynb) to get [results4taylor.csv](./2_simulation_output_analysis/2.2_Taylor_diagram_over_site/data_for_figure/results4taylor.csv) | [Figure.ipynb](././2_simulation_output_analysis/2.2_Taylor_diagram_over_site/Figure.ipynb) |
| 2.3  | [Overall model performance](./2_simulation_output_analysis/2.3_overall_model_performance) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ | Use [Export_ahf.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Export_ahf.ipynb) and [Export_flux.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Export_flux.ipynb) to get [ahf.csv](././2_simulation_output_analysis/2.3_overall_model_performance/data_for_figure/ahf.csv) and [flux.csv](././2_simulation_output_analysis/2.3_overall_model_performance/data_for_figure/flux.csv), respectively | [Figure.ipynb](./2_simulation_output_analysis/2.3_overall_model_performance/Figure.ipynb) |
| 2.4  | [Model sensitivity to parameters](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters) | BASE, SENS                      | Use [Export.ipynb](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/Export.ipynb) to get [result.csv](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/data_for_figure/result.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.4_model_sensitivity_to_parameters/Figure.ipynb) |
| 2.5  | [Variations in anthropogenic heat flux](./2_simulation_output_analysis/2.5_variations_in_ahf) | BASE, SENS                      | Use [Export.ipynb](./2_simulation_output_analysis/2.5_variations_in_ahf/Export.ipynb) to get [ahf.csv](./2_simulation_output_analysis/2.5_variations_in_ahf/data_for_figure/ahf.csv) and [qh.csv](./2_simulation_output_analysis/2.5_variations_in_ahf/data_for_figure/qh.csv) | [Figure.ipynb](./2_simulation_output_analysis/2.5_variations_in_ahf/Figure.ipynb) |

- CNTL: simulation using CLM5.0 default surface data.
- WRF_LCZ: simulation using LCZ-based urban parameters from [WRF's default look-up table](https://github.com/wrf-model/WRF/blob/master/run/URBPARM_LCZ.TBL).
- LI_LCZ: simulation using LCZ-based urban parameters from [Li et al. (2023)](https://doi.org/10.1029/2023JD038883).
- BASE: simulation using LCZ-based urban parameters created by the authors, mixing WRF's and LI's LCZ tables.
- SENS: simulation using surface input with parameter perturbation.

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
| 4.2  | [Sensible heat flux over sites](./4_supplimentary_information/4.2_sensible_heat_flux) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ  | Use *csv from [output](./4_supplimentary_information/4.4_flux_varaibles_over_sites/output/) | [Figure.ipynb](./4_supplimentary_information/4.2_sensible_heat_flux/Figure.ipynb) |
| 4.3  | [Momentum flux sensitivity to roughness length](./4_supplimentary_information/4.3_momemtum_flux_sensitivity) | BASE, SENS1, SENS2, SENS3, SENS4 | Use [Export.ipynb](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/Export.ipynb) to get [result.csv](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/data_for_figure/result.csv) | [Figure.ipynb](./4_supplimentary_information/4.3_momemtum_flux_sensitivity/Figure.ipynb) |
| 4.4  | [Flux variables over sites](./4_supplimentary_information/4.4_flux_varaibles_over_sites) | CNTL, WRF_LCZ, LI_LCZ, CESM_LCZ  | Use [Export.ipynb](./4_supplimentary_information/4.4_flux_varaibles_over_sites/Export.ipynb) to get *csv stored in [output](./4_supplimentary_information/4.4_flux_varaibles_over_sites/output/) | [Figure.ipynb](./4_supplimentary_information/4.4_flux_varaibles_over_sites/Figure.ipynb) |

## [5_generate_LCZ_inputs](./5_generate_LCZ_inputs)

The scripts listed below are used to generate LCZ-based land surface inputs for simulations. **Note:** For LCZ simulations, we set **nlevurb = 5**. 

| Num. | Simulations | Input data process                                           |
| ---- | ----------- | ------------------------------------------------------------ |
| 5.1  | WRF_LCZ     | [WRF_LCZ.ipynb](./5_generate_LCZ_inputs/5.1_WRF_LCZ/WRF_LCZ.ipynb) |
| 5.2  | LI_LCZ      | [LI_LCZ.ipynb](./5_generate_LCZ_inputs/5.2_LI_LCZ/LI_LCZ.ipynb) |
| 5.3  | CESM_LCZ    | [CESM_LCZ.ipynb](./5_generate_LCZ_inputs/5.3_CESM_LCZ/CESM_LCZ.ipynb) |
| 5.4  | BASE        | [BASE.ipynb](./5_generate_LCZ_inputs/5.4_BASE/BASE.ipynb)    |
| 5.5  | SENS        | [SENS.ipynb](./5_generate_LCZ_inputs/5.5_SENS/SENS.ipynb)    |

## [6_sourcemods](./6_sourcemods)

- [SourceMods_for_UrbanPLUMBER](./6_sourcemods/SourceMods_for_UrbanPLUMBER/): modified CLM5.0 code for participating Urban-PLUMBER.
- [SourceMods_def](./6_sourcemods/SourceMods_def): modified CTSM5.2.X code for default surface input.
- [SourceMods_lcz](./6_sourcemods/SourceMods_lcz): modified CTSM5.2.X code for LCZ-based surface input.
- [SourceMods_roughness_sensitivity_S1](./6_sourcemods/SourceMods_roughness_sensitivity_S1/): modified CTSM5.2.X code for [CLMU’s default method of roughness length calculation](https://github.com/ESCOMP/CTSM/blob/master/src/biogeophys/UrbanParamsType.F90).
- [SourceMods_roughness_sensitivity_S2](./6_sourcemods/SourceMods_roughness_sensitivity_S2): modified CTSM5.2.X code for using [Kanda et al. (2013)](https://doi.org/10.1007/s10546-013-9818-x)’s method.
- [SouceMods_roughness_sensitivity_S3](./6_sourcemods/SourceMods_roughness_sensitivity_S3): modified CTSM5.2.X code for using [Kent et al. (2017)](https://doi.org/10.1016/j.jweia.2017.07.016)'s method.

The scripts listed below modify the source code to use several parameters provided by Urban-PLUMBER. Lines between **!KO** are modified by [K. W. O.](https://staff.ucar.edu/users/oleson) while **!YS** by [Y. S.](https://github.com/YuanSun-UoM).

```fortran
!YS
FORTRAN CODE MODIFICATION
!YS
```

- Modifiy the `nlevurb`:
  - [clm_varpar.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/clm_varpar.F90)
- Add a new parameter `wall_to_plan_area_ratio`:
  - [LandunitType.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/LandunitType.F90)
  - [UrbanParamsType.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/UrbanParamsType.F90)
- Determine air conditioning adoption:
  - [UrbanTimeVarType.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/UrbanTimeVarType.F90)
- Other:
  - [SurfaceAlbedoMod.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/SurfaceAlbedoMod.F90)
  - [WaterStateType.F90](./6_sourcemods/SourceMods_for_UrbanPLUMBER/src.clm/WaterStateType.F90) 

## Acknowledgments

- We dedicate this work to the memory of Dr. Jason Ching, whose groundbreaking contributions and inspiring vision laid the foundation for this research. His legacy continues to guide and inspire us.
- This work was supported by the Natural Environment Research Council [grant number UKRI1294].
- This work used the [ARCHER2 UK National Supercomputing Service](https://www.archer2.ac.uk) and [JASMIN, the UK’s collaborative data analysis environment](https://www.jasmin.ac.uk/). 
- The authors would like to acknowledge the assistance of Research IT and the use of the HPC Pool and Computational Shared Facility at The University of Manchester. The support of [Dr. Douglas Lowe](https://github.com/douglowe) and Christopher Grave from Research IT at The University of Manchester is gratefully acknowledged. 
- We thank Prof. David M. Schultz for his comments on an earlier version of the manuscript.
- Additionally, we appreciate the assistance of Dr. Congyuan Li.
- [Z.Z.](https://github.com/zhonghua-zheng) appreciates the support provided by the academic start-up funds from the Department of Earth and Environmental Sciences at The University of Manchester.
- [Y.S.](https://github.com/YuanSun-UoM) is supported by the PhD studentship of [Z.Z.](https://github.com/zhonghua-zheng)'s academic start-up funds.
- NSF National Center for Atmospheric Research is a major facility sponsored by the U.S. National Science Foundation under Cooperative Agreement No. 1852977.
- Contributions from [M.D.](https://github.com/matthiasdemuzere) are supported by the European Union’s HORIZON Research and Innovation Actions under grant agreement No. 101137851, project [CARMINE (Climate-Resilient Development Pathways in Metropolitan Regions of Europe)](https://www.carmine-project.eu/).
- L.Z. acknowledges the support of the U.S. National Science Foundation (CAREER award grant no. 2145362).
- N.Z. acknowledges the support of the National Natural Science Foundation of China (NSFC grant no. U2342221).
- We gratefully thank three anonymous reviewers for their constructive comments that substantially improved the manuscript.
- The authors declare no conflict of interest.

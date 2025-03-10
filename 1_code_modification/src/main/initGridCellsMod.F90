module initGridCellsMod

  !-----------------------------------------------------------------------
  ! !DESCRIPTION:
  ! Initializes sub-grid mapping for each land grid cell. This module handles the high-
  ! level logic that determines how the subgrid structure is set up in a CLM run. It
  ! makes use of lower-level routines in initSubgridMod.
  !
  ! TODO(wjs, 2015-12-08) Much of the logic here duplicates (in some sense) logic in
  ! subgridMod. The duplication should probably be extracted into routines shared between
  ! these modules (or the two modules should be combined into one).
  !
  ! !USES:
#include "shr_assert.h"
  use shr_kind_mod   , only : r8 => shr_kind_r8
  use shr_log_mod    , only : errMsg => shr_log_errMsg
  use spmdMod        , only : masterproc,iam
  use abortutils     , only : endrun
  use clm_varctl     , only : iulog, use_fates, use_fates_sp
  use clm_varcon     , only : namep, namec, namel, nameg
  use decompMod      , only : bounds_type
  use GridcellType   , only : grc                
  use LandunitType   , only : lun                
  use ColumnType     , only : col                
  use PatchType      , only : patch                
  use initSubgridMod , only : clm_ptrs_compdown, clm_ptrs_check
  use initSubgridMod , only : add_landunit, add_column, add_patch
  use glcBehaviorMod , only : glc_behavior_type
  !
  ! !PUBLIC TYPES:
  implicit none
  private
  !
  ! !PUBLIC MEMBER FUNCTIONS:
  public initGridcells ! initialize sub-grid gridcell mapping 
  !
  ! !PRIVATE MEMBER FUNCTIONS:
  private set_landunit_veg_compete
  private set_landunit_wet_lake
  private set_landunit_ice
  private set_landunit_crop_noncompete
  private set_landunit_urban

  character(len=*), parameter, private :: sourcefile = &
       __FILE__
  !-----------------------------------------------------------------------

contains

  !------------------------------------------------------------------------
  subroutine initGridcells(bounds_clump, glc_behavior)
    !
    ! !DESCRIPTION: 
    ! Initialize sub-grid mapping and allocates space for derived type hierarchy.
    ! For each land gridcell determine landunit, column and patch properties.
    !
    ! !USES
    use domainMod         , only : ldomain
    use subgridWeightsMod , only : compute_higher_order_weights
    use landunit_varcon   , only : istsoil, istwet, istdlak, istice
    use landunit_varcon   , only : isturb_tbd, isturb_hd, isturb_md, istcrop
    use clm_varctl        , only : use_fates
    use shr_const_mod     , only : SHR_CONST_PI
!YS
    use clm_varctl        , only : use_lcz
    use landunit_varcon   , only : isturb_lcz1,isturb_lcz2,isturb_lcz3,isturb_lcz4,&
                                   isturb_lcz5,isturb_lcz6,isturb_lcz7,isturb_lcz8,&
                                   isturb_lcz9,isturb_lcz10
!YS                                       
    !
    ! !ARGUMENTS:
    type(bounds_type)      , intent(in) :: bounds_clump
    type(glc_behavior_type), intent(in) :: glc_behavior
    !
    ! !LOCAL VARIABLES:
    integer :: nc,li,ci,pi,gdc      ! indices
    !------------------------------------------------------------------------

    ! Notes about how this routine is arranged, and its implications for the arrangement
    ! of 1-d vectors in memory: 
    ! 
    ! (1) There is an outer loop over clumps; this results in all of a clump's points (at
    !     the gridcell, landunit, column & patch level) being contiguous. This is important
    !     for the use of begg:endg, etc., and also for performance.
    !
    ! (2) Next, there is a section for each landunit, with the loop over grid cells
    !     happening separately for each landunit. This means that, within a given clump,
    !     points with the same landunit are grouped together (this is true at the
    !     landunit, column and patch levels). Thus, different landunits for a given grid
    !     cell are separated in memory. This improves performance in the many parts of
    !     the code that operate over a single landunit, or two similar landunits. 
    !
    ! Example: landunit-level array: For a processor with 2 clumps, each of which has 2
    ! grid cells, each of which has 3 landunits, the layout of a landunit-level array
    ! looks like the following:
    !
    ! Array index:   1   2   3   4   5   6   7   8   9  10  11  12
    ! ------------------------------------------------------------
    ! Clump index:   1   1   1   1   1   1   2   2   2   2   2   2
    ! Gridcell:      1   2   1   2   1   2   3   4   3   4   3   4
    ! Landunit type: 1   1   2   2   3   3   1   1   2   2   3   3
    !
    ! Example: patch-level array: For a processor with 1 clump, which has 2 grid cells, each
    ! of which has 2 landunits, each of which has 3 patchs, the layout of a patch-level array
    ! looks like the following:
    !
    ! Array index:   1   2   3   4   5   6   7   8   9  10  11  12
    ! ------------------------------------------------------------
    ! Gridcell:      1   1   1   2   2   2   1   1   1   2   2   2
    ! Landunit type: 1   1   1   1   1   1   2   2   2   2   2   2
    ! Patch type:    1   2   3   1   2   3   1   2   3   1   2   3
    !
    ! So note that clump index is most slowly varying, followed by landunit type,
    ! followed by gridcell, followed by column and patch type.
    ! 
    ! Cohort layout
    ! Array index:   1   2   3   4   5   6   7   8   9  10  11  12
    ! ------------------------------------------------------------
    ! Gridcell:      1   1   1   1   2   2   2   2   3   3   3   3
    ! Column:        1   1   2   2   3   3   4   4   5   5   6   6   
    ! Cohort:        1   2   1   2   1   2   1   2   1   2   1   2

    ! For each land gridcell on global grid determine landunit, column and patch properties
    
    li = bounds_clump%begl-1
    ci = bounds_clump%begc-1
    pi = bounds_clump%begp-1

    ! Determine naturally vegetated landunit
    do gdc = bounds_clump%begg,bounds_clump%endg
       call set_landunit_veg_compete(               &
            ltype=istsoil, gi=gdc, li=li, ci=ci, pi=pi)
    end do

    ! Determine crop landunit
    do gdc = bounds_clump%begg,bounds_clump%endg
       call set_landunit_crop_noncompete(           &
            ltype=istcrop, gi=gdc, li=li, ci=ci, pi=pi)
    end do

    ! Determine urban tall building district landunit
!YS    do gdc = bounds_clump%begg,bounds_clump%endg
!YS       call set_landunit_urban( &
!YS            ltype=isturb_tbd, gi=gdc, li=li, ci=ci, pi=pi)

!YS    end do
!YS
    if (.not. use_lcz) then
       ! Determine urban tall building district landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
            ltype=isturb_tbd, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
            ltype=isturb_hd, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
            ltype=isturb_md, gi=gdc, li=li, ci=ci, pi=pi)
       end do 
    else if (use_lcz) then
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz1, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ2 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz2, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ3 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz3, gi=gdc, li=li, ci=ci, pi=pi)
       end do

          ! Determine urban LCZ4 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz4, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ5 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
         call set_landunit_urban( &
                  ltype=isturb_lcz5, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ6 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz6, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ7 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz7, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ8 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz8, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ9 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz9, gi=gdc, li=li, ci=ci, pi=pi)
       end do

       ! Determine urban LCZ10 landunit
       do gdc = bounds_clump%begg,bounds_clump%endg
          call set_landunit_urban( &
                  ltype=isturb_lcz10, gi=gdc, li=li, ci=ci, pi=pi)
       end do
    end if       
!YS
    ! Determine urban high density landunit
!YS    do gdc = bounds_clump%begg,bounds_clump%endg
!YS      call set_landunit_urban( &
!YS           ltype=isturb_hd, gi=gdc, li=li, ci=ci, pi=pi)
!YS    end do

    ! Determine urban medium density landunit
!YS    do gdc = bounds_clump%begg,bounds_clump%endg
!YS       call set_landunit_urban( &
!YS            ltype=isturb_md, gi=gdc, li=li, ci=ci, pi=pi)
!YS    end do

    ! Determine lake, wetland and glacier landunits 
    do gdc = bounds_clump%begg,bounds_clump%endg
       call set_landunit_wet_lake(              &
            ltype=istdlak, gi=gdc, li=li, ci=ci, pi=pi)
    end do

    do gdc = bounds_clump%begg,bounds_clump%endg
       call set_landunit_wet_lake(              &
            ltype=istwet, gi=gdc, li=li, ci=ci, pi=pi)
    end do

    do gdc = bounds_clump%begg,bounds_clump%endg
       call set_landunit_ice( &
            glc_behavior = glc_behavior, &
            ltype=istice, gi=gdc, li=li, ci=ci, pi=pi)
    end do

    ! Ensure that we have set the expected number of patchs, cols and landunits for this clump
    SHR_ASSERT_FL(li == bounds_clump%endl, sourcefile, __LINE__)
    SHR_ASSERT_FL(ci == bounds_clump%endc, sourcefile, __LINE__)
    SHR_ASSERT_FL(pi == bounds_clump%endp, sourcefile, __LINE__)

    ! Set some other gridcell-level variables

    do gdc = bounds_clump%begg,bounds_clump%endg
       grc%area(gdc)   = ldomain%area(gdc)
       grc%latdeg(gdc) = ldomain%latc(gdc) 
       grc%londeg(gdc) = ldomain%lonc(gdc) 
       grc%lat(gdc)    = grc%latdeg(gdc) * SHR_CONST_PI/180._r8  
       grc%lon(gdc)    = grc%londeg(gdc) * SHR_CONST_PI/180._r8
    enddo

    ! Fill in subgrid datatypes

    call clm_ptrs_compdown(bounds_clump)

    ! By putting this check within the loop over clumps, we ensure that (for example)
    ! if a clump is responsible for landunit L, then that same clump is also
    ! responsible for all columns and patchs in L.
    call clm_ptrs_check(bounds_clump)

    ! Set patch%wtlunit, patch%wtgcell and col%wtgcell
    call compute_higher_order_weights(bounds_clump)

  end subroutine initGridcells

  !------------------------------------------------------------------------
  subroutine set_landunit_veg_compete (ltype, gi, li, ci, pi)
    !
    ! !DESCRIPTION: 
    ! Initialize vegetated landunit with competition
    !
    ! !USES
    use clm_instur, only : wt_lunit, wt_nat_patch
    use subgridMod, only : subgrid_get_info_natveg, natveg_patch_exists
    use clm_varpar, only : natpft_lb, natpft_ub, natpft_size
    !
    ! !ARGUMENTS:
    integer , intent(in)    :: ltype             ! landunit type
    integer , intent(in)    :: gi                ! gridcell index
    integer , intent(inout) :: li                ! landunit index
    integer , intent(inout) :: ci                ! column index
    integer , intent(inout) :: pi                ! patch index
    !
    ! !LOCAL VARIABLES:
    integer  :: m, ci2                           ! index
    integer  :: npatches                         ! number of patches in landunit
    integer  :: ncols
    integer  :: nlunits
    integer  :: npatches_added                   ! number of patches actually added
    integer  :: ncols_added                      ! number of columns actually added
    integer  :: nlunits_added                    ! number of landunits actually added
    real(r8) :: wtlunit2gcell                    ! landunit weight in gridcell
    real(r8) :: wtcol2lunit                      ! column weight in landunit
    real(r8) :: p_wt                             ! patch weight (0-1)
    !------------------------------------------------------------------------

    ! Set decomposition properties

    call subgrid_get_info_natveg(gi, &
          npatches=npatches, ncols=ncols, nlunits=nlunits)
    wtlunit2gcell = wt_lunit(gi, ltype)

    nlunits_added = 0
    ncols_added = 0
    npatches_added = 0

    if (nlunits > 0) then
       call add_landunit(li=li, gi=gi, ltype=ltype, wtgcell=wtlunit2gcell)
       nlunits_added = nlunits_added + 1

       ! Potentially create multiple columns (e.g., for hillslope hydrology), but each
       ! with the same PFT breakdown.
       !
       ! Set column weight arbitrarily for now. If we have multiple columns because we're
       ! using hillslope hydrology, then col%wtlunit will be modified in InitHillslope.
       wtcol2lunit = 1.0_r8/real(ncols,r8)
       do ci2 = 1,ncols
          call add_column(ci=ci, li=li, ctype=1, wtlunit=wtcol2lunit)
          ncols_added = ncols_added + 1

          ! For FATES: the total number of patches may not match what is in the surface
          ! file, and therefor the weighting can't be used. The weightings in
          ! wt_nat_patch may be meaningful (like with fixed biogeography), but they
          ! they need a mapping table to connect to the allocated patches (in fates)
          ! so the wt_nat_patch array is not applicable to these area weights
          ! A subsequent call, via the clmfates interface will update these weights
          ! by using said mapping table

          do m = natpft_lb,natpft_ub
             if (natveg_patch_exists(gi, m)) then
                if(use_fates .and. .not.use_fates_sp)then
                   p_wt = 1.0_r8/real(natpft_size,r8)
                else
                   p_wt = wt_nat_patch(gi,m)
                end if
                call add_patch(pi=pi, ci=ci, ptype=m, wtcol=p_wt)
                npatches_added = npatches_added + 1
             end if
          end do
       end do
    end if

    SHR_ASSERT_FL(nlunits_added == nlunits, sourcefile, __LINE__)
    SHR_ASSERT_FL(ncols_added == ncols, sourcefile, __LINE__)
    SHR_ASSERT_FL(npatches_added == npatches, sourcefile, __LINE__)

  end subroutine set_landunit_veg_compete


  !------------------------------------------------------------------------
  subroutine set_landunit_wet_lake (ltype, gi, li, ci, pi)
    !
    ! !DESCRIPTION:
    ! Initialize wetland and lake landunits
    !
    ! !USES
    use clm_instur      , only : wt_lunit
    use landunit_varcon , only : istwet, istdlak
    use subgridMod      , only : subgrid_get_info_wetland, subgrid_get_info_lake
    use pftconMod       , only : noveg

    !
    ! !ARGUMENTS:
    integer , intent(in)    :: ltype             ! landunit type
    integer , intent(in)    :: gi                ! gridcell index
    integer , intent(inout) :: li                ! landunit index
    integer , intent(inout) :: ci                ! column index
    integer , intent(inout) :: pi                ! patch index
    !
    ! !LOCAL VARIABLES:
    integer  :: npatches                         ! number of pfts in landunit
    integer  :: ncols
    integer  :: nlunits
    real(r8) :: wtlunit2gcell                    ! landunit weight in gridcell
    !------------------------------------------------------------------------

    ! Set decomposition properties

    if (ltype == istwet) then
       call subgrid_get_info_wetland(gi, &
            npatches=npatches, ncols=ncols, nlunits=nlunits)
    else if (ltype == istdlak) then
       call subgrid_get_info_lake(gi, &
            npatches=npatches, ncols=ncols, nlunits=nlunits)
    else
       write(iulog,*)' set_landunit_wet_lake: ltype of ',ltype,' not valid'
       write(iulog,*)' only istwet and istdlak ltypes are valid'
       call endrun(msg=errMsg(sourcefile, __LINE__))
    end if

    wtlunit2gcell = wt_lunit(gi, ltype)

    if (npatches > 0) then

       if (npatches /= 1) then
          write(iulog,*)' set_landunit_wet_lake: compete landunit must'// &
               ' have one patch '
          write(iulog,*)' current value of npatches=',npatches
          call endrun(msg=errMsg(sourcefile, __LINE__))
       end if

       ! Currently assume that each landunit only has only one column 
       ! and that each column has its own pft
       
       call add_landunit(li=li, gi=gi, ltype=ltype, wtgcell=wtlunit2gcell)
       call add_column(ci=ci, li=li, ctype=ltype, wtlunit=1.0_r8)
       call add_patch(pi=pi, ci=ci, ptype=noveg, wtcol=1.0_r8)

    endif       ! npatches > 0       

  end subroutine set_landunit_wet_lake

  !-----------------------------------------------------------------------
  subroutine set_landunit_ice(glc_behavior, ltype, gi, li, ci, pi)
    !
    ! !DESCRIPTION:
    ! Initialize glacier landunits
    !
    ! !USES:
    use clm_varpar      , only : maxpatch_glc
    use clm_instur      , only : wt_lunit, wt_glc_mec
    use landunit_varcon , only : istice
    use column_varcon   , only : ice_class_to_col_itype
    use subgridMod      , only : subgrid_get_info_glacier_mec
    use pftconMod       , only : noveg
    !
    ! !ARGUMENTS:
    type(glc_behavior_type), intent(in) :: glc_behavior
    integer , intent(in)    :: ltype             ! landunit type
    integer , intent(in)    :: gi                ! gridcell index
    integer , intent(inout) :: li                ! landunit index
    integer , intent(inout) :: ci                ! column index
    integer , intent(inout) :: pi                ! patch index
    !
    ! !LOCAL VARIABLES:
    integer  :: m                                ! index
    integer  :: npatches      ! number of patches in landunit
    integer  :: ncols
    integer  :: nlunits
    logical  :: col_exists
    real(r8) :: wtlunit2gcell ! weight relative to gridcell of landunit
    real(r8) :: wtcol2lunit   ! col weight in landunit
    logical  :: type_is_dynamic

    ! We don't have a true atm_topo value at the point of this call, so arbitrarily use
    ! 0. This will put glc in elevation class 1 in some places where it should
    ! actually be in a higher elevation class, but that will be adjusted in the run loop
    ! (or upon reading the restart file).
    real(r8), parameter :: atm_topo = 0._r8

    character(len=*), parameter :: subname = 'set_landunit_ice'
    !-----------------------------------------------------------------------

    SHR_ASSERT_FL(ltype == istice, sourcefile, __LINE__)

    call subgrid_get_info_glacier_mec(gi, atm_topo, glc_behavior, &
         npatches=npatches, ncols=ncols, nlunits=nlunits)

    if (nlunits == 1) then
       wtlunit2gcell = wt_lunit(gi, ltype)
       call add_landunit(li=li, gi=gi, ltype=ltype, wtgcell=wtlunit2gcell)

       ! Determine column and properties
       ! (Each column has its own pft)
       !
       ! For grid cells where the glc behavior indicates a need for virtual columns
       ! (i.e., zero-weight columns that are nevertheless active), make sure all the
       ! elevations classes are populated, even if some have zero fractional area.
       ! This ensures that the ice sheet component, glc, will receive a surface mass
       ! balance in each elevation class wherever the SMB is needed.
       
       type_is_dynamic = glc_behavior%cols_have_dynamic_type(gi)
       do m = 1, maxpatch_glc
          call glc_behavior%glc_col_exists(gi = gi, elev_class = m, atm_topo = atm_topo, &
               exists = col_exists, col_wt_lunit = wtcol2lunit)
          if (col_exists) then
             call add_column(ci=ci, li=li, ctype=ice_class_to_col_itype(m), &
                  wtlunit=wtcol2lunit, type_is_dynamic=type_is_dynamic)
             call add_patch(pi=pi, ci=ci, ptype=noveg, wtcol=1.0_r8)
          endif
       enddo

    else if (nlunits /= 0) then
       call endrun(msg=subname//' ERROR: expect 0 or 1 landunits')
    end if

  end subroutine set_landunit_ice

  !------------------------------------------------------------------------

  subroutine set_landunit_crop_noncompete (ltype, gi, li, ci, pi)
    !
    ! !DESCRIPTION: 
    ! Initialize crop landunit without competition
    !
    ! Note about the ltype input argument: This provides the value for this landunit index
    ! (i.e., the crop landunit index). This may differ from the landunit's 'itype' value,
    ! since itype is istsoil if we are running with create_crop_landunit but for
    ! an older surface dataset that 
    !
    ! !USES
    use clm_instur      , only : wt_lunit, wt_cft
    use landunit_varcon , only : istcrop, istsoil
    use subgridMod      , only : subgrid_get_info_crop, crop_patch_exists
    use clm_varpar      , only : cft_lb, cft_ub
    use clm_varctl      , only : create_crop_landunit
    !
    ! !ARGUMENTS:
    integer , intent(in)    :: ltype             ! landunit type
    integer , intent(in)    :: gi                ! gridcell index
    integer , intent(inout) :: li                ! landunit index
    integer , intent(inout) :: ci                ! column index
    integer , intent(inout) :: pi                ! patch index
    !
    ! !LOCAL VARIABLES:
    integer  :: my_ltype                         ! landunit type for crops
    integer  :: cft                              ! crop functional type index
    integer  :: npatches                         ! number of pfts in landunit
    integer  :: ncols
    integer  :: nlunits
    integer  :: npatches_added                   ! number of patches actually added
    integer  :: ncols_added                      ! number of columns actually added
    integer  :: nlunits_added                    ! number of landunits actually added
    real(r8) :: wtlunit2gcell                    ! landunit weight in gridcell
    !------------------------------------------------------------------------

    ! Set decomposition properties

    call subgrid_get_info_crop(gi, &
         npatches=npatches, ncols=ncols, nlunits=nlunits)
    wtlunit2gcell = wt_lunit(gi, ltype)

    nlunits_added = 0
    ncols_added = 0
    npatches_added = 0

    if (nlunits > 0) then

       ! Note that we cannot simply use the 'ltype' argument to set itype here,
       ! because ltype will always indicate istcrop
       if ( create_crop_landunit )then
          my_ltype = ltype    ! Will always be istcrop
          if ( ltype /= istcrop )then
             write(iulog,*)' create_crop_landunit on and ltype is not istcrop: ', ltype
             call endrun(msg=errMsg(sourcefile, __LINE__))
          end if
       else
          my_ltype = istsoil
       end if

       call add_landunit(li=li, gi=gi, ltype=my_ltype, wtgcell=wtlunit2gcell)
       nlunits_added = nlunits_added + 1
       
       ! Set column and patch properties for this landunit 
       ! (each column has its own pft)

       do cft = cft_lb, cft_ub
          if (crop_patch_exists(gi, cft)) then
             call add_column(ci=ci, li=li, ctype=((istcrop*100) + cft), wtlunit=wt_cft(gi,cft))
             ncols_added = ncols_added + 1
             call add_patch(pi=pi, ci=ci, ptype=cft, wtcol=1.0_r8)
             npatches_added = npatches_added + 1
          end if
       end do

    end if

    SHR_ASSERT_FL(nlunits_added == nlunits, sourcefile, __LINE__)
    SHR_ASSERT_FL(ncols_added == ncols, sourcefile, __LINE__)
    SHR_ASSERT_FL(npatches_added == npatches, sourcefile, __LINE__)

  end subroutine set_landunit_crop_noncompete

  !------------------------------------------------------------------------------

  subroutine set_landunit_urban (ltype, gi, li, ci, pi)
    !
    ! !DESCRIPTION: 
    ! Initialize urban landunits
    !
    ! !USES
    use column_varcon   , only : icol_roof, icol_sunwall, icol_shadewall
    use column_varcon   , only : icol_road_perv, icol_road_imperv
    use landunit_varcon , only : isturb_tbd, isturb_hd, isturb_md, isturb_MIN
    use clm_varpar      , only : maxpatch_urb
    use clm_instur      , only : wt_lunit
    use subgridMod      , only : subgrid_get_info_urban_tbd, subgrid_get_info_urban_hd
    use subgridMod      , only : subgrid_get_info_urban_md
    use UrbanParamsType , only : urbinp
    use pftconMod       , only : noveg
!YS  
    use clm_varctl      , only : use_lcz
    use landunit_varcon , only : isturb_lcz1, isturb_lcz2, isturb_lcz3, &
                                 isturb_lcz4, isturb_lcz5, isturb_lcz6, &
                                 isturb_lcz7, isturb_lcz8, isturb_lcz9, &
                                 isturb_lcz10
    use subgridMod      , only : subgrid_get_info_urban_lcz1, subgrid_get_info_urban_lcz2, &
                                 subgrid_get_info_urban_lcz3, subgrid_get_info_urban_lcz4, &
                                 subgrid_get_info_urban_lcz5, subgrid_get_info_urban_lcz6, &
                                 subgrid_get_info_urban_lcz7, subgrid_get_info_urban_lcz8, &
                                 subgrid_get_info_urban_lcz9, subgrid_get_info_urban_lcz10 
!YS                                     
    !
    ! !ARGUMENTS:
    integer , intent(in)    :: ltype             ! landunit type
    integer , intent(in)    :: gi                ! gridcell index
    integer , intent(inout) :: li                ! landunit index
    integer , intent(inout) :: ci                ! column index
    integer , intent(inout) :: pi                ! patch index
    !
    ! !LOCAL VARIABLES:
    integer  :: m             ! index
    integer  :: n             ! urban density type index
    integer  :: ctype         ! column type
    integer  :: npatches      ! number of pfts in landunit
    integer  :: ncols
    integer  :: nlunits
    real(r8) :: wtlunit2gcell ! weight relative to gridcell of landunit
    real(r8) :: wtcol2lunit   ! weight of column with respect to landunit
    real(r8) :: wtlunit_roof  ! weight of roof with respect to landunit
    real(r8) :: wtroad_perv   ! weight of pervious road column with respect to total road
    integer  :: ier           ! error status 
    !------------------------------------------------------------------------

    ! Set decomposition properties, and set variables specific to urban density type

!YS    select case (ltype)
!YS    case (isturb_tbd)
!YS       call subgrid_get_info_urban_tbd(gi, &
!YS            npatches=npatches, ncols=ncols, nlunits=nlunits)
!YS    case (isturb_hd)
!YS       call subgrid_get_info_urban_hd(gi, &
!YS            npatches=npatches, ncols=ncols, nlunits=nlunits)
!YS    case (isturb_md)
!YS       call subgrid_get_info_urban_md(gi, &
!YS            npatches=npatches, ncols=ncols, nlunits=nlunits)
!YS   case default
!YS       write(iulog,*)' set_landunit_urban: unknown ltype: ', ltype
!YS       call endrun(msg=errMsg(sourcefile, __LINE__))
!YS   end select
!YS
    if (.not. use_lcz) then
       select case (ltype)
       case (isturb_tbd)
            call subgrid_get_info_urban_tbd(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_hd)
            call subgrid_get_info_urban_hd(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_md)
            call subgrid_get_info_urban_md(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case default
            write(iulog,*)' set_landunit_urban: unknown ltype: ', ltype
            call endrun(msg=errMsg(sourcefile, __LINE__))
       end select
    else if (use_lcz) then
       select case (ltype)
       case (isturb_lcz1)
            call subgrid_get_info_urban_lcz1(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz2)
            call subgrid_get_info_urban_lcz2(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz3)
            call subgrid_get_info_urban_lcz3(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz4)
            call subgrid_get_info_urban_lcz4(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz5)
            call subgrid_get_info_urban_lcz5(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz6)
            call subgrid_get_info_urban_lcz6(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits) 
       case (isturb_lcz7)
            call subgrid_get_info_urban_lcz7(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz8)
            call subgrid_get_info_urban_lcz8(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz9)
            call subgrid_get_info_urban_lcz9(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)
       case (isturb_lcz10)
            call subgrid_get_info_urban_lcz10(gi, &
                 npatches=npatches, ncols=ncols, nlunits=nlunits)                               
       case default
            write(iulog,*)' set_landunit_urban: unknown ltype: ', ltype
            call endrun(msg=errMsg(sourcefile, __LINE__))
       end select
    end if
!YS    
    if (npatches > 0) then

       wtlunit2gcell = wt_lunit(gi, ltype)

       n = ltype - isturb_MIN + 1
       wtlunit_roof = urbinp%wtlunit_roof(gi,n)
       wtroad_perv  = urbinp%wtroad_perv(gi,n)

       call add_landunit(li=li, gi=gi, ltype=ltype, wtgcell=wtlunit2gcell)

       ! Loop through columns for this landunit and set the column and patch properties
       ! For the urban landunits it is assumed that each column has its own pft
       
       do m = 1, maxpatch_urb
          
          if (m == 1) then
             ctype = icol_roof
             wtcol2lunit = wtlunit_roof
          else if (m == 2) then
             ctype = icol_sunwall
             wtcol2lunit = (1. - wtlunit_roof)/3
          else if (m == 3) then
             ctype = icol_shadewall
             wtcol2lunit = (1. - wtlunit_roof)/3
          else if (m == 4) then
             ctype = icol_road_imperv
             wtcol2lunit = ((1. - wtlunit_roof)/3) * (1.-wtroad_perv)
          else if (m == 5) then
             ctype = icol_road_perv
             wtcol2lunit = ((1. - wtlunit_roof)/3) * (wtroad_perv)
          end if

          call add_column(ci=ci, li=li, ctype=ctype, wtlunit=wtcol2lunit)

          call add_patch(pi=pi, ci=ci, ptype=noveg, wtcol=1.0_r8)

       end do   ! end of loop through urban columns-pfts
    end if

  end subroutine set_landunit_urban

end module initGridCellsMod

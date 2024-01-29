!> Contains constants for the phenology processes
!>
!> ICON-Land
!>
!> ---------------------------------------
!> Copyright (C) 2013-2024, MPI-M, MPI-BGC
!>
!> Contact: icon-model.org
!> Authors: AUTHORS.md
!> See LICENSES/ for license information
!> SPDX-License-Identifier: BSD-3-Clause
!> ---------------------------------------
!>
MODULE mo_pheno_constants
#ifndef __NO_JSBACH__

  USE mo_kind, ONLY: wp

  IMPLICIT NONE
  PUBLIC

  ! List of phenology types
  ! evergreen   (EG)
  ! summergreen (SG)
  ! raingreen   (RG)
  ! grasses     (GRS)
  ! crops       (CRP)

  ! --- public types used for parameters -----------------------------------------------------------------------------------------

  ! R: nicht mehr notwendig laut Christian:
  !   TYPE t_bounds  !! For saving parameter boundary values
  !      LOGICAL   ::  exists = .FALSE.  ! indicates whether a boundary value exists
  !      REAL(dp)  ::  value  =  NaN     ! the boundary value if it exists
  !   END TYPE t_bounds
  !  PUBLIC :: t_bounds

  !   TYPE rdata_type  ! To have a real value of a variable, its name and possible upper and lower range together. Should be set by
  !                    ! routine set_rdata().
  !      REAL(dp)          :: v =  NaN   ! the value of the variable
  !      CHARACTER(len=32) :: n =  ""    ! the name of the variable
  ! ! R: nicht mehr notwendig laut Christian    TYPE(t_bounds) :: uBound        ! the upper bound
  ! ! R: nicht mehr notwendig laut Christian    TYPE(t_bounds) :: lBound        ! the lower bound
  !      CHARACTER(len=32) :: units =""  ! the physical units of the stored values
  !   END TYPE rdata_type
  ! !  PUBLIC :: rdata_type

  !> Collects parameters that apply to all phenology types
  TYPE t_GeneralParams
    REAL(wp) :: &
      & LAI_negligible =1.0e-05_wp, & ! [-] Below this value an LAI is considered to be zero.
      & laiSeed = 0.40_wp,          & ! [-] Seed value used for the LAI to have a non-zero starting value
                                      ! whenever the vegetation starts growing.
      & wilt_point = 0.35_wp          ! [-] Critical fraction of soil water bucket level: below this value
                                      !  growth of grasses, raingreens and crops stops (wilting point).
  END TYPE t_GeneralParams

  !> Parameters that are common to the evergreen and raingreen phenology type
  TYPE t_EG_SG_common_param
    REAL(wp) :: &
      & tau_pseudo_soil = 10.0_wp, & ! [days] Characteristic time for the memory loss for computing the pseudo
                                     ! soil temperature from air temperature [days] (see subroutine
                                     ! "update_pseudo_soil_temp")
      & max_chill_days = 365.0_wp    ! [days] This is an upper limit for the number of chill days
                                     ! (field chill_days(:)).
                                     ! It prevents the number of chill days to grow beyond any limit in regions
                                     ! where the temperature is permanently below the alternation_temp (i.e.
                                     ! especially in polar regions)
  END TYPE t_EG_SG_common_param

  !> Parameters applying to the evergreen phenology type only
  TYPE t_evergreen_param
    REAL(wp) :: &
      & alternation_temp = 4.0_wp,        & ! [Celsius] Critical temperature of the alternating model, above
                                            ! which temperature contributes to the heat sum, and below which
                                            ! days are considered as chilling days (see subroutine 
                                            ! "update_growth_phase")
      & heat_sum_min = 10.0_wp,           & ! [degree days] Minimum value of critical heat sum [degree days]
                                            ! (see "update_growth_phase")
      & heat_sum_range = 1.5e+02_wp,      & ! [degree days] Range of critical heat sum [degree days]
                                            ! (see "update_growth_phase")
      & chill_decay_const = 1.5e+01_wp,   & ! [days] Number of chill days at which chilling influence on critical
                                            ! heat sum drops to 1/e (see "update_growth_phase")
      & growthPhaseLength = 60.0_wp,      & ! [days]Length of growth phase
      & shedRate_vegetative = 8.0e-04_wp, & ! [1/days] Leaf shedding rate of evergreen during vegetative phase
      & growthRate = 1.5e-02_wp             ! [1/days] Fract. of NPP maximally allocated to leaves during growth
  END TYPE t_evergreen_param

  !> Parameters applying to the summergreen phenology type only
  TYPE t_summergreen_param
    REAL(wp) :: &
      & alternation_temp = 4.0_wp,      & ! [Celsius] Critical temperature of the alternating model, above which
                                          ! temperature contributes to the heat sum, and below which days are
                                          ! considered as chilling days (see subroutine "update_growth_phase")
      & heat_sum_min = 30.0_wp,         & ! [Degree days] Minimum value of critical heat sum
                                          ! (see "update_growth_phase")
      & heat_sum_range = 2.0e+02_wp,    & ! [Degree days] Range of critical heat sum (see "update_growth_phase")
      & chill_decay_const = 2.5e+01_wp, & ! [days] Number of chill days at which chilling influence on critical
                                          ! heat sum drops to 1/e (see "update_growth_phase")
      & growthPhaseLength = 60._wp,     & ! [days] Length of growth phase [years]
      & autumn_event_temp = 10._wp,     & ! [Celcius] Critical pseudo-soil-temperature that determines the autumn
                                          ! event, i.e. the date at which rest phase begins
                                          ! (see "update_growth_phase")
      & shedRate_veget = 4.0e-03_wp,    & ! [1/days] Leaf shedding rate of summergreen (SG) during the vegetative
                                          ! phase
      & shedRate_rest = 1.0e-01_wp,     & ! [1/days]Leaf shedding rate of summergreen (SG) during the rest phase
      & growthRate = 8.7195e-02_wp,     & ! [1/days]Fraction of NPP maximally allocated to leaves during growth
      & maxLength_gvPhase = 270._wp,    & ! [days] Number of days that growth plus vegetative phase maximally can
                                          ! have. This parameter is introduced for technical reasons to assure
                                          ! that the next growth pahse is not missed.
      & minLength_gvPhase = 90._wp        ! [days] 60 = growthPhaseLength  + 30 ! Number of days that growth plus
                                          ! vegetative phase minimally should last. This parameter is introduced 
                                          ! to prevent leaf shedding when early after the growth phase there is a
                                          ! cold snap.
  END TYPE t_summergreen_param

  !> Parameters applying to the raingreen phenology type only
  TYPE t_raingreen_param
    REAL(wp) :: &
      & shedRate_drySeason = 1.20e-01_wp,  & ! [1/days] Leaf shedding rate (fast) in dry season
      & shedRate_aging = 5.0e-03_wp,       & ! [1/days] Minimal leaf shedding rate by leaf aging (inverse leaf
                                             ! longevity)
      & growthRate = 8.0e-02_wp,           & ! [1/days] Growth rate (only active during wet season; modified by
                                             ! leaf shedding)
      & bucketFill_critical = 6.50e-01_wp, & ! [fraction] If bucket filling drops below this value, the shedding
                                             ! rate is increased
                                             ! so that plant growth is reduced until it gets zero at the wilting
                                             ! point
      & bucketFill_leafout = 4.00e-01_wp     ! [fraction] The critical bucket filling at which plant start
                                             ! growing leaves (>= wiltingt point)
  END TYPE t_raingreen_param

  !> Parameters applying to the grass phenology type only
  TYPE t_grass_param
    REAL(wp) :: &
      &  crit_temp = 4.0_wp,            & ! [Celsius] Critical temperature for growth of grasses: Below this
                                          ! temperature growth of grasses stops.
      &  shedRate_growth = 1.50e-02_wp, & ! [1/days] Leaf shedding rate in the growth phase when growth
                                          ! conditions are not so good
      &  growthRate = 9.e-02_wp,        & ! [1/days] Growth rate for good climate conditions
      &  shedRate_drySeason = 1.5e-02_wp  ! [1/days] Leaf shedding rate in dry season
  END TYPE t_grass_param

  !> Parameters applying to the crop phenology only
  TYPE t_crop_param
    REAL(wp) :: &
      & crit_temp = 10.0_wp,          & ! [Celsius] Critical temperature for growth of crops: Below this
                                        ! temperature growth of crops stops.
      & gdd_temp = 6.0_wp,            & ! [Celsius] Critical (base) temperature for counting growing degree days
                                        ! (i.e. heat sum) of crops
      & sproud = 0.37_wp,             & ! [-] Critical fraction of soil water bucket level for setting LAI to
                                        ! the seed value
      & heat_sum_harvest = 1300.0_wp, & ! [Degree days] Heat sum (degree days) at which crops are harvested
      & shedRate_growth = 0.03333_wp, & ! [1/days] Leaf shedding rate in the growth phase
      & shedRate_rest = 0.1428_wp,    & ! [1/days] Shed rate for cold season of crops
      & leafAlloc_fract = 0.8_wp        ! [-] Fraction of NPP maximally allocated to leaves during growth
  END TYPE t_crop_param

  !> Parameters only required in case of l_forestRegrowth = true -- TODO-JN discuss with KIM
  TYPE t_forestRegrowth_param
    REAL(wp) :: &
      & m2toha = 10000._wp,           & ! TODO-JN: this is a more general constant -> move to somewhere else?
      & kgCtokg = 2._wp,              & ! TODO-JN: same
      & min_c   = 1._wp,              & ! JN: minimum C in wood and veg biomass for the maxLAI calculation
      & min_zero = 1.e-8_wp,          & ! TODO-JN: describe
      & log_maxind = 9.5_wp,          & ! TODO-JN: describe
      & min_maxLAI = 0.5_wp             ! TODO-JN: describe + why not "PhenoParam%all%laiSeed"?
  END TYPE t_forestRegrowth_param

  !> Collects all parameters in a single structure
  TYPE t_PhenologyParameters
    TYPE(t_GeneralParams)        :: all         ! Parameters common to all phenology types
    TYPE(t_EG_SG_common_param)   :: EG_SG       ! Parameters common to evergreen (EG) and summergreen (SG) phenology type
    TYPE(t_evergreen_param)      :: EG          ! Parameters applying to the evergreen (EG) phenology type only
    TYPE(t_summergreen_param)    :: SG          ! Parameters applying to the summergreen (SG) phenology type only
    TYPE(t_raingreen_param)      :: RG          ! Parameters applying to the raingreen (RG) phenology type only
    TYPE(t_grass_param)          :: GRS         ! Parameters applying to the grass (GRS) phenology type only
    TYPE(t_crop_param)           :: CRP         ! Parameters applying to the crop (CRP) phenology type only
    TYPE(t_forestRegrowth_param) :: FR          ! Parameters only required in case of l_forestRegrowth = true
    ! TYPE(rdata_type), POINTER     :: memory(:)  => NULL() ! pointer to serial array containing the parameter values physically
    ! logical                       :: initialized =.FALSE. ! .true. indicates that phenology parameters have been initialized.
  END TYPE t_PhenologyParameters

  TYPE(t_PhenologyParameters), SAVE :: PhenoParam

  !$ACC DECLARE CREATE(PhenoParam%all, PhenoParam%EG_SG, PhenoParam%EG) &
  !$ACC   CREATE(PhenoParam%SG, PhenoParam%RG, PhenoParam%GRS) &
  !$ACC   CREATE(PhenoParam%CRP, PhenoParam%FR, PhenoParam)

  !! quincy
  REAL(wp), SAVE ::   & 
      gdd_t_air_threshold             !< temperature threshold for the accumulation of growing degree days [deg K]

  !< some useful numbers for easy identification of photosynthetic pathways and growth forms
  !! 
  INTEGER, PARAMETER ::                     &
      ievergreen              = 1         , &
      isummergreen            = 2         , &
      iraingreen              = 3         , &
      iperennial              = 4

  CHARACTER(len=*), PARAMETER, PRIVATE :: modname = 'mo_pheno_constants'

CONTAINS

  !-----------------------------------------------------------------------------------------------------
  !> initialize constants used in the phenology process
  !! called by jsbach_setup_models()
  !-----------------------------------------------------------------------------------------------------
  SUBROUTINE init_pheno_constants

    USE mo_jsb_physical_constants, ONLY: tmelt  

    CHARACTER(len=*), PARAMETER :: routine = modname//':init_pheno_constants'

    gdd_t_air_threshold       = 5.0_wp + tmelt            !< ... citation

  END SUBROUTINE init_pheno_constants

#endif
END MODULE mo_pheno_constants

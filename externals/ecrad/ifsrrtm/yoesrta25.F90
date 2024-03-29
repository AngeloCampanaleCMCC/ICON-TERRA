! This file has been modified for the use in ICON

MODULE YOESRTA25

USE PARKIND1  ,ONLY : JPIM     ,JPRB,JPRD

IMPLICIT NONE

PUBLIC

SAVE

!     -----------------------------------------------------------------
!*    ** *YOESRTA25* - SRTM COEFFICIENTS FOR INTERVAL 25
!     BAND 25: 16000-22650 cm-1 (low - H2O; high - nothing)
!     -----------------------------------------------------------------

INTEGER(KIND=JPIM), PARAMETER :: JPG = 16, NG25 = 16

REAL(KIND=JPRB) :: KA(5,13,JPG) 
REAL(KIND=JPRD) :: KA_D(5,13,JPG) 
REAL(KIND=JPRB) :: SFLUXREF(JPG)
REAL(KIND=JPRB) :: RAYL(JPG), ABSO3A(JPG), ABSO3B(JPG)
INTEGER(KIND=JPIM) :: LAYREFFR

REAL(KIND=JPRB) :: KAC(5,13,NG25) ,ABSA(65,NG25)
REAL(KIND=JPRB) :: SFLUXREFC(NG25)
REAL(KIND=JPRB) :: RAYLC(NG25), ABSO3AC(NG25), ABSO3BC(NG25)

!EQUIVALENCE (KA(1,1,1),ABSA(1,1))
EQUIVALENCE (KAC(1,1,1),ABSA(1,1))

!$ACC DECLARE CREATE(KAC, ABSA, SFLUXREFC, RAYLC, ABSO3AC, ABSO3BC)

!     -----------------------------------------------------------------
!        * E.C.M.W.F. PHYSICS PACKAGE ** RRTM SW RADIATION **

!     J.-J. MORCRETTE       E.C.M.W.F.      02/10/29
!     M. J. IACONO          AER             12/09/03

!  NAME     TYPE     PURPOSE
!  ----   : ----   : ---------------------------------------------------
! KA      : REAL     absorption coefficient of major absorber
! SFLUXREF: REAL     Incident solar radiation in the spectral interval
! RAYL    : REAL     Rayleigh scattering parameter
! ABSO3A  : REAL     O3 absorption coefficient in first part of band
! ABSO3B  : REAL     O3 absorption coefficient in second part of band
! LAYREFFR: INTEGER  reference level for the transition
! KAC     : REAL     Reduced g-point array for KA
!SFLUXREFC: REAL     Reduced g-point array for SFLUXREF
! RAYLC   : REAL     Reduced g-point array for RAYL
! ABSO3AC : REAL     Reduced g-point array for ABSO3A
! ABSO3BC : REAL     Reduced g-point array for ABSO3B
!     -----------------------------------------------------------------
END MODULE YOESRTA25


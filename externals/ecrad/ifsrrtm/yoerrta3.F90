! This file has been modified for the use in ICON

MODULE YOERRTA3

USE PARKIND1  ,ONLY : JPIM     ,JPRB

IMPLICIT NONE

PUBLIC

SAVE

!     -----------------------------------------------------------------
!*    ** *YOERRTA3* - RRTM COEFFICIENTS FOR INTERVAL 3
!     BAND 3:  500-630 cm-1 (low - H2O,CO2; high - H2O,CO2)
!     -----------------------------------------------------------------

INTEGER(KIND=JPIM), PARAMETER :: NG3  = 16

REAL(KIND=JPRB) :: FRACREFA(NG3,9) ,FRACREFB(NG3,5)

REAL(KIND=JPRB) :: KA_MN2O(9,19,NG3), KB_MN2O(5,19,NG3)
REAL(KIND=JPRB) :: KA(9,5,13,NG3)  ,ABSA(585,NG3)
REAL(KIND=JPRB) :: KB(5,5,13:59,NG3),ABSB(1175,NG3)
REAL(KIND=JPRB) :: SELFREF(10,NG3)
REAL(KIND=JPRB) :: FORREF(4,NG3)

EQUIVALENCE (KA(1,1,1,1),ABSA(1,1)),(KB(1,1,13,1),ABSB(1,1))

!$ACC DECLARE CREATE(FRACREFA, FRACREFB, KA_MN2O, KB_MN2O, KA, ABSA, KB, ABSB, &
!$ACC                SELFREF, FORREF)

!     ------------------------------------------------------------------
!        * E.C.M.W.F. PHYSICS PACKAGE ** RRTM LW RADIATION **

!     J.-J. MORCRETTE       E.C.M.W.F.      98/07/14

!  NAME     TYPE     PURPOSE
!  ----   : ----   : ---------------------------------------------------
! ABSA    : REAL     absorption coefficient of major absorber for M reference tropospheric 
!                    pressures and N reference tropospheric temperatures 
! ABSB    : REAL     absorption coefficient of secondary absorber for M reference stratospheric
!                    pressures and N reference stratospheric temperatures 
! ABSN2OA : REAL     absorption coefficient for tropospheric N2O
! ABSN2OB : REAL     absorption coefficient for stratospheric N2O
! CO2REF  : REAL     refrence CO2 profile
! ETAREF  : REAL     reference eta scale [0,1]
! FRACREFA: REAL     distance from r and T reference tabulated points (troposphere)
! FRACREFB: REAL     distance from r and T reference tabulated points (stratosphere)
! H2OREF  : REAL     reference H2O profile
! KA      : REAL     absorption coefficient of major absorber (equiv. to ABSA)   
! KB      : REAL     absorption coefficient of secondary absorber (equiv. to ABSB)   
! N2OREF  : REAL     reference N2O profile
! SELFREF : REAL     self broadening coefficient for water vapour
! STRRAT  : REAL     weighting factor for the transition between tropospheric 
!                    and stratospheric computations
!     -----------------------------------------------------------------
END MODULE YOERRTA3

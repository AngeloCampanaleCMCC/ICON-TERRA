! This file has been modified for the use in ICON

MODULE YOERRTA1

USE PARKIND1  ,ONLY : JPIM     ,JPRB

IMPLICIT NONE

PUBLIC

SAVE

!     -----------------------------------------------------------------
!*    ** *YOERRTA1* - RRTM COEFFICIENTS FOR INTERVAL 1
!     BAND 1:  10-250 cm-1 (low - H2O; high - H2O)
!     ABozzo may 2013 update to last version of rrtmg
!     band 1:  10-350 cm-1
!     -----------------------------------------------------------------

INTEGER(KIND=JPIM), PARAMETER :: NG1  = 10

REAL(KIND=JPRB) :: FRACREFA(NG1)  , FRACREFB(NG1)
REAL(KIND=JPRB) :: KA(5,13,NG1)   , ABSA(65,NG1)
REAL(KIND=JPRB) :: KB(5,13:59,NG1), ABSB(235,NG1)
REAL(KIND=JPRB) :: KA_MN2(19,NG1) , KB_MN2(19,NG1)
REAL(KIND=JPRB) :: SELFREF(10,NG1), FORREF(4,NG1)

EQUIVALENCE (KA(1,1,1),ABSA(1,1)), (KB(1,13,1),ABSB(1,1))

!$ACC DECLARE CREATE(FRACREFA, FRACREFB, KA, ABSA, KB, ABSB, KA_MN2, KB_MN2, &
!$ACC                SELFREF, FORREF)

!     -----------------------------------------------------------------
!        * E.C.M.W.F. PHYSICS PACKAGE ** RRTM LW RADIATION **

!     J.-J. MORCRETTE       E.C.M.W.F.      98/07/14

!  NAME     TYPE     PURPOSE
!  ----   : ----   : ---------------------------------------------------
! ABSA    : REAL     absorption coefficient of major absorber for M reference tropospheric 
!                    pressures and N reference tropospheric temperatures
! ABSB    : REAL     absorption coefficient of secondary absorber for M reference stratospheric
!                    pressures and N reference stratospheric temperatures 
! FRACREFA: REAL     distance from r and T reference tabulated points (troposphere)
! FRACREFB: REAL     distance from r and T reference tabulated points (stratosphere)
! FORREF  : REAL     foreign broadening coefficient for water vapour
! KA      : REAL     absorption coefficient of major absorber    
! KB      : REAL     absorption coefficient of secondary absorber    
! SELFREF : REAL     self broadening coefficient for water vapour
!     -----------------------------------------------------------------
END MODULE YOERRTA1

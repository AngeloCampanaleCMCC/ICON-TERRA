! This file has been modified for the use in ICON

MODULE YOERRTRF

USE PARKIND1  ,ONLY : JPRB

IMPLICIT NONE

PUBLIC

SAVE

!     -----------------------------------------------------------------
!*    ** *YOERRTRF* - RRTM REFERENCE ATMOSPHERE
!     -----------------------------------------------------------------

REAL(KIND=JPRB) , DIMENSION(59) :: PREF
REAL(KIND=JPRB) , DIMENSION(59) :: PREFLOG
REAL(KIND=JPRB) , DIMENSION(59) :: TREF
REAL(KIND=JPRB)  :: CHI_MLS(7,59)

!$ACC DECLARE CREATE(PREF, PREFLOG, TREF, CHI_MLS)

!     -----------------------------------------------------------------
!        * E.C.M.W.F. PHYSICS PACKAGE ** RRTM LW RADIATION **

!     J.-J. MORCRETTE       E.C.M.W.F.      98/01/15

!  NAME     TYPE     PURPOSE
!  ----  :  ----   : ---------------------------------------------------
! PREF   :  REAL    
! PREFLOG: REAL
! TREF   : REAL
!     -----------------------------------------------------------------
END MODULE YOERRTRF

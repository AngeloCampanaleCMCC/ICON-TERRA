#ifdef RS6K
@PROCESS HOT(NOVECTOR) NOSTRICT
#endif
SUBROUTINE SRTM_SPCVRT_MCICA &
 & ( KIDIA   , KFDIA   , KLEV    , KSW    , KCOLS  , PONEMINUS, &
 &   PALBD   , PALBP, &
 &   PFRCL   , PTAUC   , PASYC  , POMGC  , PTAUA    , PASYA   , POMGA , PRMU0, &
 &   KLAYTROP,&
 &   PCOLCH4  , PCOLCO2 , PCOLH2O , PCOLMOL  , PCOLO2 , PCOLO3 ,&
 &   PFORFAC , PFORFRAC , KINDFOR , PSELFFAC, PSELFFRAC, KINDSELF ,&
 &   PFAC00  , PFAC01   , PFAC10  , PFAC11 ,&
 &   KJP     , KJT      , KJT1 ,&
 !-- output arrays 
 &   PBBFD   , PBBFU    , PBBCD, PBBCU, PFUVF, PFUVC, PPARF, PPARCF, PSUDU, &
 &   PBBFDIR , PBBCDIR  , PSwDiffuseBand     , PSwDirectBand )


!**** *SRTM_SPCVRT* - SPECTRAL LOOP TO COMPUTE THE SHORTWAVE RADIATION FLUXES.

!     PURPOSE.
!     --------

!          THIS ROUTINE COMPUTES THE TWO-STREAM METHOD OF BARKER

!**   INTERFACE.
!     ----------

!          *SRTM_SPCVRT_MCICA* IS CALLED FROM *SRTM_SRTM_224GP*

!        IMPLICIT ARGUMENTS :
!        --------------------

!     ==== INPUTS ===
!     ==== OUTPUTS ===

!     METHOD.
!     -------

!     EXTERNALS.
!     ----------

!          *SWVRTQDR*

!     REFERENCE.
!     ----------

!        SEE RADIATION'S PART OF THE ECMWF RESEARCH DEPARTMENT
!        DOCUMENTATION
!     AUTHOR.
!     -------
!        from Howard Barker
!        JEAN-JACQUES MORCRETTE  *ECMWF*

!     MODIFICATIONS.
!     --------------
!        ORIGINAL : 03-02-27
!        M.Hamrud      01-Oct-2003 CY28 Cleaning
!        JJMorcrette   20050110 McICA version
!        JJMorcrette   20070614 bug-fix for solar duration
!        JJMorcrette   20070831 UV-B surface flux
!        D.Salmond  31-Oct-2007 Vector version in the style of RRTM from Meteo France & NEC
!        JJMorcrette/MJIacono 20080724 Look-up table replacing exponential
!        JJMorcrette   20091201 Total and clear-sky downward direct flux
!        RJHogan       20140627 Store downwelling surface fluxes in each band
!     ------------------------------------------------------------------

USE PARKIND1 , ONLY : JPIM, JPRB
USE ecradhook  , ONLY : LHOOK, DR_HOOK
USE PARSRTM  , ONLY : JPB1, JPB2
USE YOESRTM  , ONLY : JPGPT
USE YOESRTWN , ONLY : NGC, NMPSRTM
USE YOERDI   , ONLY : REPCLC
USE YOESRTAB , ONLY : BPADE, TRANS, RODLOW, RTBLINT
USE YOERAD   , ONLY : NSW, LApproxSwUpdate

IMPLICIT NONE

!     ------------------------------------------------------------------

!*       0.1   ARGUMENTS
!              ---------

INTEGER(KIND=JPIM),INTENT(IN)    :: KSW
INTEGER(KIND=JPIM),INTENT(IN)    :: KCOLS
INTEGER(KIND=JPIM),INTENT(IN)    :: KIDIA, KFDIA
INTEGER(KIND=JPIM),INTENT(IN)    :: KLEV
REAL(KIND=JPRB)   ,INTENT(IN)    :: PONEMINUS(KIDIA:KFDIA)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PALBD(KIDIA:KFDIA,KSW) 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PALBP(KIDIA:KFDIA,KSW) 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFRCL(KIDIA:KFDIA,KCOLS,KLEV)  ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: PTAUC(KIDIA:KFDIA,KLEV,KCOLS)  ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: PASYC(KIDIA:KFDIA,KLEV,KCOLS)  ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: POMGC(KIDIA:KFDIA,KLEV,KCOLS)  ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: PTAUA(KIDIA:KFDIA,KLEV,KSW)    ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: PASYA(KIDIA:KFDIA,KLEV,KSW)    ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: POMGA(KIDIA:KFDIA,KLEV,KSW)    ! bottom to top
REAL(KIND=JPRB)   ,INTENT(IN)    :: PRMU0(KIDIA:KFDIA)
INTEGER(KIND=JPIM),INTENT(IN)    :: KLAYTROP(KIDIA:KFDIA)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLCH4(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLCO2(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLH2O(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLMOL(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLO2(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCOLO3(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFORFAC(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFORFRAC(KIDIA:KFDIA,KLEV)
INTEGER(KIND=JPIM),INTENT(IN)    :: KINDFOR(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PSELFFAC(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PSELFFRAC(KIDIA:KFDIA,KLEV)
INTEGER(KIND=JPIM),INTENT(IN)    :: KINDSELF(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFAC00(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFAC01(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFAC10(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(IN)    :: PFAC11(KIDIA:KFDIA,KLEV)
INTEGER(KIND=JPIM),INTENT(IN)    :: KJP(KIDIA:KFDIA,KLEV)
INTEGER(KIND=JPIM),INTENT(IN)    :: KJT(KIDIA:KFDIA,KLEV)
INTEGER(KIND=JPIM),INTENT(IN)    :: KJT1(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBFD(KIDIA:KFDIA,KLEV+1) 
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBFU(KIDIA:KFDIA,KLEV+1) 
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBCD(KIDIA:KFDIA,KLEV+1) 
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBCU(KIDIA:KFDIA,KLEV+1) 
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFUVF(KIDIA:KFDIA), PFUVC(KIDIA:KFDIA)
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PPARF(KIDIA:KFDIA), PPARCF(KIDIA:KFDIA)
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PSUDU(KIDIA:KFDIA)
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBFDIR(KIDIA:KFDIA,KLEV+1)
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PBBCDIR(KIDIA:KFDIA,KLEV+1)

! Surface diffuse and direct downwelling shortwave flux in each
! shortwave albedo band, used in RADINTG to update the surface fluxes
! accounting for high-resolution albedo information
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PSwDiffuseBand(KIDIA:KFDIA,NSW)
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PSwDirectBand(KIDIA:KFDIA,NSW)

!     ------------------------------------------------------------------

!              ------------

LOGICAL :: LLRTCHK(KIDIA:KFDIA,KLEV)

REAL(KIND=JPRB) :: &
 & ZCLEAR(KIDIA:KFDIA)      , ZCLOUD(KIDIA:KFDIA)       &
 & , ZDBT(KIDIA:KFDIA,KLEV+1) &
 & , ZGCC(KIDIA:KFDIA,KLEV)   , ZGCO(KIDIA:KFDIA,KLEV)     &
 & , ZOMCC(KIDIA:KFDIA,KLEV)  , ZOMCO(KIDIA:KFDIA,KLEV)    &
 & , ZRDND(KIDIA:KFDIA,KLEV+1), ZRDNDC(KIDIA:KFDIA,KLEV+1)&
 & , ZREF(KIDIA:KFDIA,KLEV+1) , ZREFC(KIDIA:KFDIA,KLEV+1) , ZREFO(KIDIA:KFDIA,KLEV+1)  &
 & , ZREFD(KIDIA:KFDIA,KLEV+1), ZREFDC(KIDIA:KFDIA,KLEV+1), ZREFDO(KIDIA:KFDIA,KLEV+1) &
 & , ZRUP(KIDIA:KFDIA,KLEV+1) , ZRUPD(KIDIA:KFDIA,KLEV+1) &
 & , ZRUPC(KIDIA:KFDIA,KLEV+1), ZRUPDC(KIDIA:KFDIA,KLEV+1)&
 & , ZTAUC(KIDIA:KFDIA,KLEV)  , ZTAUO(KIDIA:KFDIA,KLEV)    &
 & , ZTDBT(KIDIA:KFDIA,KLEV+1) &
 & , ZTRA(KIDIA:KFDIA,KLEV+1) , ZTRAC(KIDIA:KFDIA,KLEV+1) , ZTRAO(KIDIA:KFDIA,KLEV+1)  &
 & , ZTRAD(KIDIA:KFDIA,KLEV+1), ZTRADC(KIDIA:KFDIA,KLEV+1), ZTRADO(KIDIA:KFDIA,KLEV+1)   
REAL(KIND=JPRB) :: &
 & ZDBTC(KIDIA:KFDIA,KLEV+1), ZTDBTC(KIDIA:KFDIA,KLEV+1), ZINCFLX(KIDIA:KFDIA,JPGPT)  &
 & ,  ZINCF14(KIDIA:KFDIA,14)   , ZINCTOT(KIDIA:KFDIA)   

INTEGER(KIND=JPIM) :: IB1, IB2, IBM, IGT, IKL, IW(KIDIA:KFDIA), JB, JG, JK, I_KMODTS, JL, IC, ICOUNT

! An index for the 6 bands used in the original albedo data rather
! than the 14 RRTM bands
INTEGER(KIND=JPIM) :: JB_ALBEDO

INTEGER(KIND=JPIM) :: INDEX(KIDIA:KFDIA)

REAL(KIND=JPRB) :: ZDBTMC(KIDIA:KFDIA), ZDBTMO(KIDIA:KFDIA), ZF(KIDIA:KFDIA)
! REAL(KIND=JPRB) :: ZARG1(KIDIA:KFDIA), ZARG2(KIDIA:KFDIA)
REAL(KIND=JPRB) :: ZINCFLUX(KIDIA:KFDIA), ZWF(KIDIA:KFDIA)
REAL(KIND=JPRB) :: ZCOEFVS

!-- Output of SRTM_TAUMOLn routines

REAL(KIND=JPRB) :: ZTAUG(KIDIA:KFDIA,KLEV,16), ZTAUR(KIDIA:KFDIA,KLEV,16), ZSFLXZEN(KIDIA:KFDIA,16)

!-- Output of SRTM_VRTQDR routine
REAL(KIND=JPRB) :: &
 & ZCD(KIDIA:KFDIA,KLEV+1,JPGPT), ZCU(KIDIA:KFDIA,KLEV+1,JPGPT) &
 & ,  ZFD(KIDIA:KFDIA,KLEV+1,JPGPT), ZFU(KIDIA:KFDIA,KLEV+1,JPGPT)  

REAL(KIND=JPRB) :: ZTAU, ZPAO, ZPTO
REAL(KIND=JPRB) :: ZPAOJ(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB) :: ZPTOJ(KIDIA:KFDIA,KLEV)
REAL(KIND=JPRB) :: ZRMU0D(KIDIA:KFDIA) 
 
!--  Use of exponential look-up table
REAL(KIND=JPRB) :: ZE1, ZE2, ZTBLIND
INTEGER(KIND=JPIM) :: ITIND

REAL(KIND=JPRB) :: ZHOOK_HANDLE


#include "srtm_taumol16.intfb.h"
#include "srtm_taumol17.intfb.h"
#include "srtm_taumol18.intfb.h"
#include "srtm_taumol19.intfb.h"
#include "srtm_taumol20.intfb.h"
#include "srtm_taumol21.intfb.h"
#include "srtm_taumol22.intfb.h"
#include "srtm_taumol23.intfb.h"
#include "srtm_taumol24.intfb.h"
#include "srtm_taumol25.intfb.h"
#include "srtm_taumol26.intfb.h"
#include "srtm_taumol27.intfb.h"
#include "srtm_taumol28.intfb.h"
#include "srtm_taumol29.intfb.h"
#include "srtm_reftra.intfb.h"
#include "srtm_vrtqdr.intfb.h"
!     ------------------------------------------------------------------
ASSOCIATE(NFLEVG=>KLEV)
IF (LHOOK) CALL DR_HOOK('SRTM_SPCVRT_MCICA',0,ZHOOK_HANDLE)

!-- Two-stream model 1: Eddington, 2: PIFM, Zdunkowski et al., 3: discrete ordinates

IB1=JPB1
IB2=JPB2

IC=0
DO JL = KIDIA, KFDIA
  IF (PRMU0(JL) > 0.0_JPRB) THEN
    IC=IC+1
    INDEX(IC)=JL
    IW(JL)=0
    ZINCFLUX(JL)=0.0_JPRB
    ZINCTOT(JL)=0.0_JPRB
    PFUVF(JL) = 0.0_JPRB
    PFUVC(JL) = 0.0_JPRB
    PPARF(JL) = 0.0_JPRB
    PPARCF(JL)= 0.0_JPRB
  ENDIF
ENDDO
ICOUNT=IC
IF(ICOUNT==0)THEN
  IF (LHOOK) CALL DR_HOOK('SRTM_SPCVRT_MCICA',1,ZHOOK_HANDLE)
  RETURN
ENDIF

! Since the stored shortwave downwelling fluxes in bands are
! accumulated over the g-points within that band, they need to be
! initialized here
IF (LApproxSwUpdate) THEN
  DO JB_ALBEDO = 1,NSW
    DO JL = KIDIA, KFDIA
      PSwDiffuseBand(JL,JB_ALBEDO) = 0.0_JPRB
      PSwDirectBand (JL,JB_ALBEDO) = 0.0_JPRB
    ENDDO
  ENDDO
ENDIF


!-- fraction of visible (to 0.69 um) in interval 0.6250-0.7782 um
ZCOEFVS = 0.42425_JPRB

JB=IB1-1
DO JB = IB1, IB2
  DO IC=1,ICOUNT
    JL=INDEX(IC)
    IBM = JB-15
    IGT = NGC(IBM)
    ZINCF14(JL,IBM)=0.0_JPRB
  ENDDO

  !-- for each band, computes the gaseous and Rayleigh optical thickness 
  !  for all g-points within the band

  IF (JB == 16) THEN
    CALL SRTM_TAUMOL16 &
     & ( KIDIA   , KFDIA    , KLEV    ,&
     &   PFAC00  , PFAC01   , PFAC10   , PFAC11   ,&
     &   KJP     , KJT      , KJT1     , PONEMINUS,&
     &   PCOLH2O , PCOLCH4  , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC , PSELFFRAC, KINDSELF, PFORFAC  , PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG    , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 17) THEN
    CALL SRTM_TAUMOL17 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLCO2 , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 18) THEN
    CALL SRTM_TAUMOL18 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLCH4 , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 19) THEN
    CALL SRTM_TAUMOL19 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLCO2 , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 20) THEN
    CALL SRTM_TAUMOL20 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     ,&
     &   PCOLH2O , PCOLCH4 , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 21) THEN
    CALL SRTM_TAUMOL21 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLCO2 , PCOLMOL  ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 22) THEN
    CALL SRTM_TAUMOL22 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLMOL , PCOLO2   ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 23) THEN
    CALL SRTM_TAUMOL23 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     ,&
     &   PCOLH2O , PCOLMOL ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 24) THEN
    CALL SRTM_TAUMOL24 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     , PONEMINUS ,&
     &   PCOLH2O , PCOLMOL , PCOLO2   , PCOLO3 ,&
     &   KLAYTROP, PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 25) THEN
    !--- visible 16000-22650 cm-1   0.4415 - 0.6250 um
    CALL SRTM_TAUMOL25 &
     & ( KIDIA    , KFDIA   , KLEV     ,&
     &   PFAC00   , PFAC01  , PFAC10 , PFAC11 ,&
     &   KJP      , KJT     , KJT1   ,&
     &   PCOLH2O  , PCOLMOL , PCOLO3 ,&
     &   KLAYTROP ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR   , PRMU0     &
     & )  

  ELSEIF (JB == 26) THEN
    !--- UV-A 22650-29000 cm-1   0.3448 - 0.4415 um
    CALL SRTM_TAUMOL26 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PCOLMOL ,KLAYTROP,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 27) THEN
    !--- UV-B 29000-38000 cm-1   0.2632 - 0.3448 um
    CALL SRTM_TAUMOL27 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP     , KJT     , KJT1     ,&
     &   PCOLMOL , PCOLO3 ,&
     &   KLAYTROP ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ELSEIF (JB == 28) THEN
    !--- UV-C 38000-50000 cm-1   0.2000 - 0.2632 um
    CALL SRTM_TAUMOL28 &
     & ( KIDIA   , KFDIA   , KLEV    ,&
     &   PFAC00  , PFAC01  , PFAC10 , PFAC11 ,&
     &   KJP     , KJT     , KJT1   , PONEMINUS ,&
     &   PCOLMOL , PCOLO2  , PCOLO3 ,&
     &   KLAYTROP ,&
     &   ZSFLXZEN, ZTAUG   , ZTAUR  , PRMU0     &
     & )  

  ELSEIF (JB == 29) THEN
    CALL SRTM_TAUMOL29 &
     & ( KIDIA    , KFDIA   , KLEV     ,&
     &   PFAC00   , PFAC01  , PFAC10   , PFAC11 ,&
     &   KJP      , KJT     , KJT1     ,&
     &   PCOLH2O  , PCOLCO2 , PCOLMOL  ,&
     &   KLAYTROP , PSELFFAC, PSELFFRAC, KINDSELF  , PFORFAC, PFORFRAC, KINDFOR ,&
     &   ZSFLXZEN , ZTAUG   , ZTAUR    , PRMU0     &
     & )  

  ENDIF
   
!J---Start---
  DO JK=1,KLEV
    IKL=KLEV+1-JK
    DO IC=1,ICOUNT
      JL=INDEX(IC)
      ZPAOJ(JL,JK) = PASYA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)
      ZPTOJ(JL,JK) = PTAUA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)
    ENDDO
  ENDDO
!J---End---

  DO JG=1,IGT
    DO IC=1,ICOUNT
      JL=INDEX(IC)
      IW(JL)=IW(JL)+1

      ZINCFLX(JL,IW(JL)) =ZSFLXZEN(JL,JG)*PRMU0(JL)
      ZINCFLUX(JL)    =ZINCFLUX(JL)+ZSFLXZEN(JL,JG)*PRMU0(JL)           
      ZINCTOT(JL)     =ZINCTOT(JL)+ZSFLXZEN(JL,JG)
      ZINCF14(JL,IBM)=ZINCF14(JL,IBM)+ZSFLXZEN(JL,JG)

      !-- CALL to compute layer reflectances and transmittances for direct 
      !  and diffuse sources, first clear then cloudy.
      !   Use direct/parallel albedo for direct radiation and diffuse albedo
      !   otherwise.

      ! ZREFC(JK)  direct albedo for clear
      ! ZREFO(JK)  direct albedo for cloud
      ! ZREFDC(JK) diffuse albedo for clear
      ! ZREFDO(JK) diffuse albedo for cloud
      ! ZTRAC(JK)  direct transmittance for clear
      ! ZTRAO(JK)  direct transmittance for cloudy
      ! ZTRADC(JK) diffuse transmittance for clear
      ! ZTRADO(JK) diffuse transmittance for cloudy

      ! ZREF(JK)   direct reflectance
      ! ZREFD(JK)  diffuse reflectance
      ! ZTRA(JK)   direct transmittance
      ! ZTRAD(JK)  diffuse transmittance

      ! ZDBTC(JK)  clear direct beam transmittance
      ! ZDBTO(JK)  cloudy direct beam transmittance
      ! ZDBT(JK)   layer mean direct beam transmittance
      ! ZTDBT(JK)  total direct beam transmittance at levels

      !-- clear-sky    
      !----- TOA direct beam    
      ZTDBTC(JL,1)=1._JPRB
      !----- surface values
      ZDBTC(JL,KLEV+1) =0.0_JPRB
      ZTRAC(JL,KLEV+1) =0.0_JPRB
      ZTRADC(JL,KLEV+1)=0.0_JPRB
      ZREFC(JL,KLEV+1) =PALBP(JL,IBM)
      ZREFDC(JL,KLEV+1)=PALBD(JL,IBM)
      ZRUPC(JL,KLEV+1) =PALBP(JL,IBM)
      ZRUPDC(JL,KLEV+1)=PALBD(JL,IBM)

      !-- total sky    
      !----- TOA direct beam    
      ZTDBT(JL,1)=1._JPRB
      !----- surface values
      ZDBT(JL,KLEV+1) =0.0_JPRB
      ZTRA(JL,KLEV+1) =0.0_JPRB
      ZTRAD(JL,KLEV+1)=0.0_JPRB
      ZREF(JL,KLEV+1) =PALBP(JL,IBM)
      ZREFD(JL,KLEV+1)=PALBD(JL,IBM)
      ZRUP(JL,KLEV+1) =PALBP(JL,IBM)
      ZRUPD(JL,KLEV+1)=PALBD(JL,IBM)
    ENDDO


    !-- NB: a two-stream calculations from top to bottom, but RRTM_SW quantities 
    !       are given bottom to top (argh!)
    !       Inputs for clouds and aerosols are bottom to top as inputs

!    DO JK=1,KLEV
!      IKL=KLEV+1-JK
!      WRITE(NULOUT,8001) IBM,JG,IKL,(PTAUA(INDEX(IC),IKL,IBM),IC=1,ICOUNT)
8001  format(1X,'McICA_SW',3I5,30E12.5)
!    ENDDO



    DO JK=1,KLEV
      IKL=KLEV+1-JK
      DO IC=1,ICOUNT
        JL=INDEX(IC)
        !-- clear-sky optical parameters      
        LLRTCHK(JL,JK)=.TRUE.
        !-- clear-sky optical parameters including aerosols
!J      ZTAUC(JL,JK) = ZTAUR(JL,IKL,JG) + ZTAUG(JL,IKL,JG) + PTAUA(JL,IKL,IBM)
!J      ZOMCC(JL,JK) = ZTAUR(JL,IKL,JG)*1.0_JPRB + PTAUA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)
!J      ZGCC(JL,JK) = PASYA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)*PTAUA(JL,IKL,IBM) / ZOMCC(JL,JK)
!J      ZOMCC(JL,JK) = ZOMCC(JL,JK) / ZTAUC(JL,JK)
!J    ENDDO
!J  ENDDO
!J  DO JK=1,KLEV
!J    IKL=KLEV+1-JK
!J    DO IC=1,ICOUNT
!J      JL=INDEX(IC)
!J      !-- total sky optical parameters        
!J      ZTAUO(JL,JK) = ZTAUR(JL,IKL,JG) + ZTAUG(JL,IKL,JG) + PTAUA(JL,IKL,IBM) + PTAUC(JL,IKL,IW(JL))
!J      ZOMCO(JL,JK) = PTAUA(JL,IKL,IBM)*POMGA(JL,IKL,IBM) + PTAUC(JL,IKL,IW(JL))*POMGC(JL,IKL,IW(JL)) &
!J       & + ZTAUR(JL,IKL,JG)*1.0_JPRB  
!J      ZGCO(JL,JK) = (PTAUC(JL,IKL,IW(JL))*POMGC(JL,IKL,IW(JL))*PASYC(JL,IKL,IW(JL))  &
!J       & +  PTAUA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)*PASYA(JL,IKL,IBM)) &
!J       & /  ZOMCO(JL,JK)  
!J      ZOMCO(JL,JK) = ZOMCO(JL,JK) / ZTAUO(JL,JK)

        ZTAU = ZTAUR(JL,IKL,JG) + ZTAUG(JL,IKL,JG)
!       ZPAO = PASYA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)
!       ZPTO = PTAUA(JL,IKL,IBM)*POMGA(JL,IKL,IBM)
        ZPAO = ZPAOJ(JL,JK)
        ZPTO = ZPTOJ(JL,JK)
        ZTAUC(JL,JK) = ZTAU + PTAUA(JL,IKL,IBM)
        ZOMCC(JL,JK) = ZTAUR(JL,IKL,JG) + ZPTO
        ZGCC(JL,JK) = ZPAO*PTAUA(JL,IKL,IBM) / ZOMCC(JL,JK)
        ZOMCC(JL,JK) = ZOMCC(JL,JK) / ZTAUC(JL,JK)
        !-- total sky optical parameters        
        ZTAUO(JL,JK) = ZTAU + PTAUA(JL,IKL,IBM) + PTAUC(JL,IKL,IW(JL))
        ZOMCO(JL,JK) = ZPTO + PTAUC(JL,IKL,IW(JL))*POMGC(JL,IKL,IW(JL)) + ZTAUR(JL,IKL,JG)  
        ZGCO(JL,JK) = (PTAUC(JL,IKL,IW(JL))*POMGC(JL,IKL,IW(JL))*PASYC(JL,IKL,IW(JL))  &
         & +  PTAUA(JL,IKL,IBM)*ZPAO) /  ZOMCO(JL,JK)  
        ZOMCO(JL,JK) = ZOMCO(JL,JK) / ZTAUO(JL,JK)
      ENDDO
    ENDDO

    !-- Delta scaling for clear-sky / aerosol optical quantities
    DO  JK=1,KLEV
      DO IC=1,ICOUNT
        JL=INDEX(IC)
        ZF(JL)=ZGCC(JL,JK)*ZGCC(JL,JK)
        ZWF(JL)=ZOMCC(JL,JK)*ZF(JL)
        ZTAUC(JL,JK)=(1._JPRB-ZWF(JL))*ZTAUC(JL,JK)
        ZOMCC(JL,JK)=(ZOMCC(JL,JK)-ZWF(JL))/(1.0_JPRB-ZWF(JL))
        ZGCC(JL,JK)=(ZGCC(JL,JK)-ZF(JL))/(1.0_JPRB-ZF(JL))
      ENDDO
    ENDDO

    CALL SRTM_REFTRA ( KIDIA, KFDIA, KLEV, I_KMODTS ,&
     &   LLRTCHK, ZGCC  , PRMU0, ZTAUC , ZOMCC ,&
     &   ZREFC  , ZREFDC, ZTRAC, ZTRADC )  

    !-- Delta scaling for cloudy quantities
    DO JK=1,KLEV
      IKL=KLEV+1-JK
      DO IC=1,ICOUNT
        JL=INDEX(IC)
        LLRTCHK(JL,JK)=.FALSE.
        ZF(JL)=ZGCO(JL,JK)*ZGCO(JL,JK)
        ZWF(JL)=ZOMCO(JL,JK)*ZF(JL)
        ZTAUO(JL,JK)=(1._JPRB-ZWF(JL))*ZTAUO(JL,JK)
        ZOMCO(JL,JK)=(ZOMCO(JL,JK)-ZWF(JL))/(1._JPRB-ZWF(JL))
        ZGCO(JL,JK)=(ZGCO(JL,JK)-ZF(JL))/(1._JPRB-ZF(JL))
        LLRTCHK(JL,JK)=(PFRCL(JL,IW(JL),IKL) > REPCLC)
      ENDDO
    ENDDO

    CALL SRTM_REFTRA ( KIDIA, KFDIA, KLEV, I_KMODTS ,&
     &   LLRTCHK, ZGCO  , PRMU0, ZTAUO , ZOMCO ,&
     &   ZREFO , ZREFDO, ZTRAO, ZTRADO )  

!J---Start---
    DO IC=1,ICOUNT
      JL=INDEX(IC)
      ZRMU0D(JL)=1.0_JPRB/PRMU0(JL)
    ENDDO 
!J---End---

    DO JK=1,KLEV
      IKL=KLEV+1-JK 
      DO IC=1,ICOUNT
        JL=INDEX(IC)
        !-- combine clear and cloudy contributions for total sky

        ZCLEAR(JL)   = 1.0_JPRB - PFRCL(JL,IW(JL),IKL)
        ZCLOUD(JL)   = PFRCL(JL,IW(JL),IKL)

        ZREF(JL,JK) = ZCLEAR(JL)*ZREFC(JL,JK) + ZCLOUD(JL)*ZREFO(JL,JK)
        ZREFD(JL,JK)= ZCLEAR(JL)*ZREFDC(JL,JK)+ ZCLOUD(JL)*ZREFDO(JL,JK)
        ZTRA(JL,JK) = ZCLEAR(JL)*ZTRAC(JL,JK) + ZCLOUD(JL)*ZTRAO(JL,JK)
        ZTRAD(JL,JK)= ZCLEAR(JL)*ZTRADC(JL,JK)+ ZCLOUD(JL)*ZTRADO(JL,JK)

        !-- direct beam transmittance        
!        ZARG1(JL)      = MIN( 200._JPRB, ZTAUC(JL,JK)/PRMU0(JL) )
!        ZARG2(JL)      = MIN( 200._JPRB, ZTAUO(JL,JK)/PRMU0(JL) )
!        ZDBTMC(JL)     = EXP(-ZARG1(JL) )
!        ZDBTMO(JL)     = EXP(-ZARG2(JL) )

!-- Use exponential look-up table for transmittance, or expansion of exponential for 
!   low optical thickness
!J      ZE1 = ZTAUC(JL,JK)/PRMU0(JL)
        ZE1 = ZTAUC(JL,JK)*ZRMU0D(JL)
        IF (ZE1 <= RODLOW) THEN
          ZDBTMC(JL) = 1._JPRB - ZE1 + 0.5_JPRB*ZE1*ZE1
        ELSE
          ZTBLIND = ZE1 / (BPADE+ZE1)
          ITIND = RTBLINT * ZTBLIND + 0.5_JPRB
          ZDBTMC(JL) = TRANS(ITIND)
        ENDIF

!J      ZE2 = ZTAUO(JL,JK)/PRMU0(JL)
        ZE2 = ZTAUO(JL,JK)*ZRMU0D(JL)
        IF (ZE2 <= RODLOW) THEN
          ZDBTMO(JL) = 1._JPRB - ZE2 + 0.5_JPRB*ZE2*ZE2
        ELSE
          ZTBLIND = ZE2 / (BPADE+ZE2)
          ITIND = RTBLINT * ZTBLIND + 0.5_JPRB
          ZDBTMO(JL) = TRANS(ITIND)
        ENDIF
!---

        ZDBT(JL,JK)   = ZCLEAR(JL)*ZDBTMC(JL)+ZCLOUD(JL)*ZDBTMO(JL)
        ZTDBT(JL,JK+1)= ZDBT(JL,JK)*ZTDBT(JL,JK)

        !-- clear-sky        
        ZDBTC(JL,JK)   =ZDBTMC(JL)
        ZTDBTC(JL,JK+1)=ZDBTC(JL,JK)*ZTDBTC(JL,JK)

      ENDDO
    ENDDO

    !-- vertical quadrature producing clear-sky fluxes

    !    print *,'SRTM_SPCVRT after 3 before SRTM_VRTQDR clear'

    CALL SRTM_VRTQDR ( KIDIA, KFDIA, KLEV, IW ,&
     &   ZREFC, ZREFDC, ZTRAC , ZTRADC ,&
     &   ZDBTC, ZRDNDC, ZRUPC , ZRUPDC, ZTDBTC ,&
     &   ZCD  , ZCU   , PRMU0 )  

    !-- vertical quadrature producing cloudy fluxes

    CALL SRTM_VRTQDR ( KIDIA, KFDIA, KLEV, IW ,&
     &   ZREF , ZREFD , ZTRA , ZTRAD ,&
     &   ZDBT , ZRDND , ZRUP , ZRUPD , ZTDBT ,&
     &   ZFD  , ZFU   , PRMU0)  

    !-- up and down-welling fluxes at levels
    DO JK=1,KLEV+1
      DO IC=1,ICOUNT
        JL=INDEX(IC)
        !-- accumulation of spectral fluxes          
        PBBFU(JL,JK) = PBBFU(JL,JK) + ZINCFLX(JL,IW(JL))*ZFU(JL,JK,IW(JL))
        PBBFD(JL,JK) = PBBFD(JL,JK) + ZINCFLX(JL,IW(JL))*ZFD(JL,JK,IW(JL))
        PBBCU(JL,JK) = PBBCU(JL,JK) + ZINCFLX(JL,IW(JL))*ZCU(JL,JK,IW(JL))
        PBBCD(JL,JK) = PBBCD(JL,JK) + ZINCFLX(JL,IW(JL))*ZCD(JL,JK,IW(JL))

        PBBFDIR(JL,JK)=PBBFDIR(JL,JK)+ZINCFLX(JL,IW(JL))*ZTDBT (JL,JK)
        PBBCDIR(JL,JK)=PBBCDIR(JL,JK)+ZINCFLX(JL,IW(JL))*ZTDBTC(JL,JK)

      ENDDO
    ENDDO
    DO IC=1,ICOUNT
      JL=INDEX(IC)
      IF ( JB >= 26 .AND. JB <= 28 ) THEN
        PFUVF(JL) = PFUVF(JL) + ZINCFLX(JL,IW(JL))*ZFD(JL,KLEV+1,IW(JL))
        PFUVC(JL) = PFUVC(JL) + ZINCFLX(JL,IW(JL))*ZCD(JL,KLEV+1,IW(JL))
      ENDIF
      IF ( JB == 23) THEN
        PPARF(JL) = PPARF(JL)+ ZINCFLX(JL,IW(JL))*ZFD(JL,KLEV+1,IW(JL))*ZCOEFVS
        PPARCF(JL)=PPARCF(JL)+ ZINCFLX(JL,IW(JL))*ZCD(JL,KLEV+1,IW(JL))*ZCOEFVS 
      ENDIF
      IF ( JB == 24) THEN
        PPARF(JL) = PPARF(JL)+ ZINCFLX(JL,IW(JL))*ZFD(JL,KLEV+1,IW(JL))
        PPARCF(JL)=PPARCF(JL)+ ZINCFLX(JL,IW(JL))*ZCD(JL,KLEV+1,IW(JL))
      ENDIF
      PSUDU(JL) = PSUDU(JL)  + ZINCFLX(JL,IW(JL))*ZTDBT(JL,KLEV+1)
    ENDDO

    ! Store the shortwave downwelling fluxes in each band
    IF (LApproxSwUpdate) THEN
      JB_ALBEDO = NMPSRTM(JB-IB1+1)
      DO IC = 1,ICOUNT
        JL = INDEX(IC)
        PSwDiffuseBand(JL,JB_ALBEDO)= PSwDiffuseBand(JL,JB_ALBEDO) &
             & + ZINCFLX(JL,IW(JL)) * (ZFD(JL, KLEV+1, IW(JL))-ZTDBT(JL,KLEV+1))
        PSwDirectBand(JL,JB_ALBEDO) = PSwDirectBand(JL,JB_ALBEDO) &
             & + ZINCFLX(JL,IW(JL)) * ZTDBT(JL,KLEV+1)
      ENDDO
    ENDIF

  ENDDO
  !-- end loop on JG

ENDDO
!-- end loop on JB

!     ------------------------------------------------------------------
IF (LHOOK) CALL DR_HOOK('SRTM_SPCVRT_MCICA',1,ZHOOK_HANDLE)
END ASSOCIATE
END SUBROUTINE SRTM_SPCVRT_MCICA

! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
! Linear Algebra Data and Routines File
!
!
! ICON
!
! ---------------------------------------------------------------
! Copyright (C) 2004-2024, DWD, MPI-M, DKRZ, KIT, ETH, MeteoSwiss
! Contact information: icon-model.org
!
! See AUTHORS.TXT for a list of authors
! See LICENSES/ for license information
! SPDX-License-Identifier: GPL-3.0-only  
! ---------------------------------------------------------------

MODULE messy_mecca_kpp_linearalgebra 
  USE mo_kind,                 ONLY: dp

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP 
 USE mo_kind,                 ONLY: dp

  IMPLICIT NONE 
  PUBLIC

CONTAINS


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! SPARSE_UTIL - SPARSE utility functions
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppDecomp( JVS, IER )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Sparse LU factorization
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER  :: IER
      REAL(kind=dp) :: JVS(LU_NONZERO), W(NVAR), a
      INTEGER  :: k, kk, j, jj

      a = 0. ! mz_rs_20050606
      IER = 0
      DO k=1,NVAR
        ! mz_rs_20050606: don't check if real value == 0
        ! IF ( JVS( LU_DIAG(k) ) .EQ. 0. ) THEN
        IF ( ABS(JVS(LU_DIAG(k))) < TINY(a) ) THEN
            IER = k
            RETURN
        END IF
        DO kk = LU_CROW(k), LU_CROW(k+1)-1
              W( LU_ICOL(kk) ) = JVS(kk)
        END DO
        DO kk = LU_CROW(k), LU_DIAG(k)-1
            j = LU_ICOL(kk)
            a = -W(j) / JVS( LU_DIAG(j) )
            W(j) = -a
            DO jj = LU_DIAG(j)+1, LU_CROW(j+1)-1
               W( LU_ICOL(jj) ) = W( LU_ICOL(jj) ) + a*JVS(jj)
            END DO
         END DO
         DO kk = LU_CROW(k), LU_CROW(k+1)-1
            JVS(kk) = W( LU_ICOL(kk) )
         END DO
      END DO
      
END SUBROUTINE KppDecomp


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppDecompCmplx( JVS, IER )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Sparse LU factorization, complex
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER        :: IER
      complex :: JVS(LU_NONZERO), W(NVAR), a
      REAL(kind=dp)  :: b = 0.0
      INTEGER        :: k, kk, j, jj

      IER = 0
      DO k=1,NVAR
        IF ( ABS(JVS(LU_DIAG(k))) < TINY(b) ) THEN
            IER = k
            RETURN
        END IF
        DO kk = LU_CROW(k), LU_CROW(k+1)-1
              W( LU_ICOL(kk) ) = JVS(kk)
        END DO
        DO kk = LU_CROW(k), LU_DIAG(k)-1
            j = LU_ICOL(kk)
            a = -W(j) / JVS( LU_DIAG(j) )
            W(j) = -a
            DO jj = LU_DIAG(j)+1, LU_CROW(j+1)-1
               W( LU_ICOL(jj) ) = W( LU_ICOL(jj) ) + a*JVS(jj)
            END DO
         END DO
         DO kk = LU_CROW(k), LU_CROW(k+1)-1
            JVS(kk) = W( LU_ICOL(kk) )
         END DO
      END DO
      
END SUBROUTINE KppDecompCmplx


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppDecompCmplxR( JVSR, JVSI, IER )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!    Sparse LU factorization, complex
!   (Real and Imaginary parts are used instead of complex data type)     
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER       :: IER
      REAL(kind=dp) :: JVSR(LU_NONZERO), JVSI(LU_NONZERO) 
      REAL(kind=dp) :: WR(NVAR), WI(NVAR), ar, ai, den
      INTEGER       :: k, kk, j, jj

      IER = 0
      ar  = 0.0
      DO k=1,NVAR
        IF (  ( ABS(JVSR(LU_DIAG(k))) < TINY(ar) ) .AND. &
              ( ABS(JVSI(LU_DIAG(k))) < TINY(ar) ) )  THEN
            IER = k
            RETURN
        END IF
        DO kk = LU_CROW(k), LU_CROW(k+1)-1
              WR( LU_ICOL(kk) ) = JVSR(kk)
              WI( LU_ICOL(kk) ) = JVSI(kk)
        END DO
        DO kk = LU_CROW(k), LU_DIAG(k)-1
            j = LU_ICOL(kk)
            den = JVSR(LU_DIAG(j))**2 + JVSI(LU_DIAG(j))**2
            ar = -(WR(j)*JVSR(LU_DIAG(j)) + WI(j)*JVSI(LU_DIAG(j)))/den
            ai = -(WI(j)*JVSR(LU_DIAG(j)) - WR(j)*JVSI(LU_DIAG(j)))/den
            WR(j) = -ar
            WI(j) = -ai
            DO jj = LU_DIAG(j)+1, LU_CROW(j+1)-1
               WR( LU_ICOL(jj) ) = WR( LU_ICOL(jj) ) + ar*JVSR(jj) - ai*JVSI(jj)
               WI( LU_ICOL(jj) ) = WI( LU_ICOL(jj) ) + ar*JVSI(jj) + ai*JVSR(jj)
            END DO
         END DO
         DO kk = LU_CROW(k), LU_CROW(k+1)-1
            JVSR(kk) = WR( LU_ICOL(kk) )
            JVSI(kk) = WI( LU_ICOL(kk) )
         END DO
      END DO

END SUBROUTINE KppDecompCmplxR


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveIndirect( JVS, X )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Sparse solve subroutine using indirect addressing
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER  :: i, j
      REAL(kind=dp) :: JVS(LU_NONZERO), X(NVAR), sum

      DO i=1,NVAR
         DO j = LU_CROW(i), LU_DIAG(i)-1 
             X(i) = X(i) - JVS(j)*X(LU_ICOL(j));
         END DO  
      END DO

      DO i=NVAR,1,-1
        sum = X(i);
        DO j = LU_DIAG(i)+1, LU_CROW(i+1)-1
          sum = sum - JVS(j)*X(LU_ICOL(j));
        END DO
        X(i) = sum/JVS(LU_DIAG(i));
      END DO
      
END SUBROUTINE KppSolveIndirect


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveTRIndirect( JVS, X )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Complex sparse solve transpose subroutine using indirect addressing
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER       :: i, j
      REAL(kind=dp) :: JVS(LU_NONZERO), X(NVAR)

      DO i=1,NVAR
        X(i) = X(i)/JVS(LU_DIAG(i))
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_DIAG(i)+1,LU_CROW(i+1)-1
          X(LU_ICOL(j)) = X(LU_ICOL(j))-JVS(j)*X(i)
        END DO
      END DO

      DO i=NVAR, 1, -1
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_CROW(i),LU_DIAG(i)-1
          X(LU_ICOL(j)) = X(LU_ICOL(j))-JVS(j)*X(i)
        END DO
      END DO
      
END SUBROUTINE KppSolveTRIndirect


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveCmplx( JVS, X )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Complex sparse solve subroutine using indirect addressing
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER        :: i, j
      complex :: JVS(LU_NONZERO), X(NVAR), sum

      DO i=1,NVAR
         DO j = LU_CROW(i), LU_DIAG(i)-1 
             X(i) = X(i) - JVS(j)*X(LU_ICOL(j));
         END DO  
      END DO

      DO i=NVAR,1,-1
        sum = X(i);
        DO j = LU_DIAG(i)+1, LU_CROW(i+1)-1
          sum = sum - JVS(j)*X(LU_ICOL(j));
        END DO
        X(i) = sum/JVS(LU_DIAG(i));
      END DO
      
END SUBROUTINE KppSolveCmplx

! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveCmplxR( JVSR, JVSI, XR, XI )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!   Complex sparse solve subroutine using indirect addressing
!   (Real and Imaginary parts are used instead of complex data type)     
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER       ::  i, j
      REAL(kind=dp) ::  JVSR(LU_NONZERO), JVSI(LU_NONZERO), XR(NVAR), XI(NVAR), sumr, sumi, den

      DO i=1,NVAR
         DO j = LU_CROW(i), LU_DIAG(i)-1 
             XR(i) = XR(i) - (JVSR(j)*XR(LU_ICOL(j)) - JVSI(j)*XI(LU_ICOL(j)))
             XI(i) = XI(i) - (JVSR(j)*XI(LU_ICOL(j)) + JVSI(j)*XR(LU_ICOL(j)))
         END DO  
      END DO

      DO i=NVAR,1,-1
        sumr = XR(i); sumi = XI(i)
        DO j = LU_DIAG(i)+1, LU_CROW(i+1)-1
            sumr = sumr - (JVSR(j)*XR(LU_ICOL(j)) - JVSI(j)*XI(LU_ICOL(j)))
            sumi = sumi - (JVSR(j)*XI(LU_ICOL(j)) + JVSI(j)*XR(LU_ICOL(j)))
        END DO
        den   = JVSR(LU_DIAG(i))**2 + JVSI(LU_DIAG(i))**2
        XR(i) = (sumr*JVSR(LU_DIAG(i)) + sumi*JVSI(LU_DIAG(i)))/den
        XI(i) = (sumi*JVSR(LU_DIAG(i)) - sumr*JVSI(LU_DIAG(i)))/den
      END DO
      
END SUBROUTINE KppSolveCmplxR


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveTRCmplx( JVS, X )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!        Complex sparse solve transpose subroutine using indirect addressing
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER        :: i, j
      complex :: JVS(LU_NONZERO), X(NVAR)

      DO i=1,NVAR
        X(i) = X(i)/JVS(LU_DIAG(i))
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_DIAG(i)+1,LU_CROW(i+1)-1
          X(LU_ICOL(j)) = X(LU_ICOL(j))-JVS(j)*X(i)
        END DO
      END DO

      DO i=NVAR, 1, -1
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_CROW(i),LU_DIAG(i)-1
          X(LU_ICOL(j)) = X(LU_ICOL(j))-JVS(j)*X(i)
        END DO
      END DO
      
END SUBROUTINE KppSolveTRCmplx


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUBROUTINE KppSolveTRCmplxR( JVSR, JVSI, XR, XI )
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!   Complex sparse solve transpose subroutine using indirect addressing
!   (Real and Imaginary parts are used instead of complex data type)     
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  USE messy_mecca_kpp_parameters
  USE messy_mecca_kpp_JacobianSP

      INTEGER       ::  i, j
      REAL(kind=dp) ::  JVSR(LU_NONZERO), JVSI(LU_NONZERO), XR(NVAR), XI(NVAR), den

      DO i=1,NVAR
        den   = JVSR(LU_DIAG(i))**2 + JVSI(LU_DIAG(i))**2
        XR(i) = (XR(i)*JVSR(LU_DIAG(i)) + XI(i)*JVSI(LU_DIAG(i)))/den
        XI(i) = (XI(i)*JVSR(LU_DIAG(i)) - XR(i)*JVSI(LU_DIAG(i)))/den
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_DIAG(i)+1,LU_CROW(i+1)-1
          XR(LU_ICOL(j)) = XR(LU_ICOL(j))-(JVSR(j)*XR(i) - JVSI(j)*XI(i))
          XI(LU_ICOL(j)) = XI(LU_ICOL(j))-(JVSI(j)*XR(i) + JVSR(j)*XI(i))
        END DO
      END DO

      DO i=NVAR, 1, -1
        ! subtract all nonzero elements in row i of JVS from X
        DO j=LU_CROW(i),LU_DIAG(i)-1
          XR(LU_ICOL(j)) = XR(LU_ICOL(j))-(JVSR(j)*XR(i) - JVSI(j)*XI(i))
          XI(LU_ICOL(j)) = XI(LU_ICOL(j))-(JVSI(j)*XR(i) + JVSR(j)*XI(i))
        END DO
      END DO
      
END SUBROUTINE KppSolveTRCmplxR


!
! Next few commented subroutines perform sparse big linear algebra
!
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!SUBROUTINE KppDecompBig( JVS, IP, IER )
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!        Sparse LU factorization
!!        for the Runge Kutta (3n)x(3n) linear system
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!  USE messy_mecca_kpp_parameters
!  USE messy_mecca_kpp_JacobianSP
!
!      INTEGER  :: IP3(3), IER, IP(3,NVAR)
!      REAL(kind=dp) :: JVS(3,3,LU_NONZERO), W(3,3,NVAR), a(3,3), E(3,3)
!      INTEGER  :: k, kk, j, jj
!
!      a = 0.0d0
!      IER = 0
!      DO k=1,NVAR
!        DO kk = LU_CROW(k), LU_CROW(k+1)-1
!              W( 1:3,1:3,LU_ICOL(kk) ) = JVS(1:3,1:3,kk)
!        END DO
!        DO kk = LU_CROW(k), LU_DIAG(k)-1
!            j = LU_ICOL(kk)
!            E(1:3,1:3) = JVS( 1:3,1:3,LU_DIAG(j) )
!            ! CALL DGETRF(3,3,E,3,IP3,IER) 
!            CALL FAC3(E,IP3,IER)
!            IF ( IER /= 0 )  RETURN
!            ! a = W(j) / JVS( LU_DIAG(j) )
!            a(1:3,1:3) = W( 1:3,1:3,j )
!            ! CALL DGETRS ('N',3,3,E,3,IP3,a,3,IER) 
!            CALL SOL3('N',E,IP3,a(1,1))
!            CALL SOL3('N',E,IP3,a(1,2))
!            CALL SOL3('N',E,IP3,a(1,3))
!            W(1:3,1:3,j) = a(1:3,1:3)
!            DO jj = LU_DIAG(j)+1, LU_CROW(j+1)-1
!               W( 1:3,1:3,LU_ICOL(jj) ) = W( 1:3,1:3,LU_ICOL(jj) ) &
!                        - MATMUL( a(1:3,1:3) , JVS(1:3,1:3,jj) )
!            END DO
!         END DO
!         DO kk = LU_CROW(k), LU_CROW(k+1)-1
!            JVS(1:3,1:3,kk) = W( 1:3,1:3,LU_ICOL(kk) )
!         END DO
!      END DO
!
!      DO k=1,NVAR
!         ! CALL WGEFA(JVS(1,1,LU_DIAG(k)),3,3,IP(1,k),IER)
!         ! CALL DGETRF(3,3,JVS(1,1,LU_DIAG(k)),3,IP(1,k),IER)
!         CALL FAC3(JVS(1,1,LU_DIAG(k)),IP(1,k),IER)
!         IF ( IER /= 0 )  RETURN
!      END DO 
!      
!END SUBROUTINE KppDecompBig
!
!
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!SUBROUTINE KppSolveBig( JVS, IP, X )
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!        Sparse solve subroutine using indirect addressing
!!        for the Runge Kutta (3n)x(3n) linear system
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!  USE messy_mecca_kpp_parameters
!  USE messy_mecca_kpp_JacobianSP
!
!      INTEGER  :: i, j, k, m, IP3(3), IP(3,NVAR), IER
!      REAL(kind=dp) :: JVS(3,3,LU_NONZERO), X(3,NVAR), sum(3)
!
!      DO i=1,NVAR
!        DO j = LU_CROW(i), LU_DIAG(i)-1 
!          !X(1:3,i) = X(1:3,i) - MATMUL(JVS(1:3,1:3,j),X(1:3,LU_ICOL(j)));
!          DO k=1,3
!            DO m=1,3
!              X(k,i) = X(k,i) - JVS(k,m,j)*X(m,LU_ICOL(j))
!            END DO
!          END DO
!        END DO  
!      END DO
!
!      DO i=NVAR,1,-1
!        sum(1:3) = X(1:3,i);
!        DO j = LU_DIAG(i)+1, LU_CROW(i+1)-1
!          !sum(1:3) = sum(1:3) - MATMUL(JVS(1:3,1:3,j),X(1:3,LU_ICOL(j)));
!          DO k=1,3
!            DO m=1,3
!              sum(k) = sum(k) - JVS(k,m,j)*X(m,LU_ICOL(j))
!            END DO
!          END DO
!        END DO
!        ! X(i) = sum/JVS(LU_DIAG(i));
!        ! CALL DGETRS ('N',3,1,JVS(1:3,1:3,LU_DIAG(i)),3,IP(1,i),sum,3,0) 
!        ! CALL WGESL('N',JVS(1,1,LU_DIAG(i)),3,3,IP(1,i),sum)
!        CALL SOL3('N',JVS(1,1,LU_DIAG(i)),IP(1,i),sum)
!        X(1:3,i) = sum(1:3)
!      END DO
!      
!END SUBROUTINE KppSolveBig
!
!
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!SUBROUTINE KppSolveBigTR( JVS, IP, X )
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!        Big sparse transpose solve using indirect addressing
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!  USE messy_mecca_kpp_parameters
!  USE messy_mecca_kpp_JacobianSP
!
!      INTEGER       :: i, j, k, m, IP(3,NVAR)
!      REAL(kind=dp) :: JVS(3,3,LU_NONZERO), X(3,NVAR)
!
!      DO i=1,NVAR
!        ! X(i) = X(i)/JVS(LU_DIAG(i))
!        CALL SOL3('T',JVS(1,1,LU_DIAG(i)),IP(1,i),X(1,i))
!        DO j=LU_DIAG(i)+1,LU_CROW(i+1)-1
!         !X(1:3,LU_ICOL(j)) = X(1:3,LU_ICOL(j)) &
!          !    - MATMUL( TRANSPOSE(JVS(1:3,1:3,j)), X(1:3,i) )
!          DO k=1,3
!            DO m=1,3
!              X(k,LU_ICOL(j)) = X(k,LU_ICOL(j)) - JVS(m,k,j)*X(m,i)
!            END DO
!          END DO
!       END DO
!      END DO
!
!      DO i=NVAR, 1, -1
!        DO j=LU_CROW(i),LU_DIAG(i)-1
!         !X(1:3,LU_ICOL(j)) = X(1:3,LU_ICOL(j)) &
!          !   - MATMUL( TRANSPOSE(JVS(1:3,1:3,j)), X(1:3,i) )
!          DO k=1,3
!            DO m=1,3
!              X(k,LU_ICOL(j)) = X(k,LU_ICOL(j)) - JVS(m,k,j)*X(m,i)
!            END DO
!          END DO
!       END DO
!      END DO
!      
!END SUBROUTINE KppSolveBigTR
!
!
!
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!SUBROUTINE FAC3(A,IPVT,INFO)
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!     FAC3 FACTORS THE MATRIX A (3,3) BY
!!           GAUSS ELIMINATION WITH PARTIAL PIVOTING
!!     LINPACK - LIKE 
!!
!!     Remove comments to perform pivoting
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!
!      REAL(kind=dp) :: A(3,3)
!      INTEGER       :: IPVT(3),INFO
!!      INTEGER       :: L
!!      REAL(kind=dp) :: t, dmax, da, TMP(3)
!      REAL(kind=dp), PARAMETER :: ZERO = 0.0, ONE = 1.0
!
!      info = 0
!!      t = TINY(da)
!!      
!!      da = ABS(A(1,1)); L = 1
!!      IF ( ABS(A(2,1))>da ) THEN
!!        da = ABS(A(2,1)); L = 2
!!        IF ( ABS(A(3,1))>da ) THEN
!!          L = 3
!!        END IF  
!!      END IF  
!!      IPVT(1)  = L
!!      IF (L /=1 ) THEN
!!         TMP(1:3) = A(L,1:3)
!!         A(L,1:3) = A(1,1:3)
!!         A(1,1:3) = TMP(1:3)
!!      END IF
!!      IF (ABS(A(1,1)) < t) THEN
!!         info = 1
!!         return
!!      END IF   
!!
!      A(2,1) = A(2,1)/A(1,1)
!      A(2,2) = A(2,2) - A(2,1)*A(1,2)
!      A(2,3) = A(2,3) - A(2,1)*A(1,3)
!      A(3,1) = A(3,1)/A(1,1)
!      A(3,2) = A(3,2) - A(3,1)*A(1,2)
!      A(3,3) = A(3,3) - A(3,1)*A(1,3)
!      
!!      IPVT(2)  = 2
!!      IF (ABS(A(3,2))>ABS(A(2,2))) THEN
!!         IPVT(2)  = 3
!!         TMP(2:3) = A(3,2:3)
!!         A(3,2:3) = A(2,2:3)
!!         A(2,2:3) = TMP(2:3)
!!      END IF
!!      IF (ABS(A(2,2)) < t) THEN
!!         info = 1
!!         return
!!      END IF   
!!      
!      A(3,2)   = A(3,2)/A(2,2)
!      A(3,3)   = A(3,3) - A(3,2)*A(2,3)
!      IPVT(3)  = 3
!      
!END SUBROUTINE FAC3
!
!
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!SUBROUTINE SOL3(Trans,A,IPVT,b)
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!     SOL3 solves the system 3x3
!!     A * x = b  or  trans(a) * x = b
!!     using the factors computed by WGEFA.
!!
!!     Trans      = 'N'   to solve  A*x = b ,
!!                = 'T'   to solve  transpose(A)*x = b
!!     LINPACK - LIKE 
!!
!!     Remove comments to use pivoting
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
!      CHARACTER     :: Trans
!      REAL(kind=dp) :: a(3,3),b(3)
!      INTEGER       :: IPVT(3)
!!      INTEGER       :: L
!!      REAL(kind=dp) :: TMP
!      
!      SELECT CASE (Trans)
!
!      CASE ('n','N')  !  Solve  A * x = b
!
!!     Solve  L*y = b
!!         L = IPVT(1)
!!         IF (L /= 1) THEN
!!            TMP = B(1); B(1) = B(L); B(L) = TMP
!!         END IF
!         b(2) = b(2)-A(2,1)*b(1)
!         b(3) = b(3)-A(3,1)*b(1)
!         
!!         L = IPVT(2)
!!         IF (L /= 2) THEN
!!            TMP = B(2); B(2) = B(L); B(L) = TMP
!!         END IF
!         b(3) = b(3)-A(3,2)*b(2)
!
!!     Solve  U*x = y
!         b(3) = b(3)/A(3,3)
!         b(2) = (b(2)-A(2,3)*b(3))/A(2,2)
!         b(1) = (b(1)-A(1,3)*b(3)-A(1,2)*b(2))/A(1,1)
!      
!      
!      CASE ('t','T')  !  Solve transpose(A) * x = b
!
!!      Solve transpose(U)*y = b
!         b(1) = b(1)/A(1,1)
!         b(2) = (b(2)-A(1,2)*b(1))/A(2,2)
!         b(3) = (b(3)-A(1,3)*b(1)-A(2,3)*b(2))/A(3,3)
!
!!      Solve transpose(L)*x = y
!         b(2) = b(2)-A(3,2)*b(3)
!!         L = ipvt(2)
!!         IF (L /= 2) THEN
!!            TMP = B(2); B(2) = B(L); B(L) = TMP
!!         END IF
!         b(1) = b(1)-A(3,1)*b(3)-A(2,1)*b(2)
!!         L = ipvt(1)
!!         IF (L /= 1) THEN
!!            TMP = B(1); B(1) = B(L); B(L) = TMP
!!         END IF
!   
!      END SELECT
!
!END SUBROUTINE SOL3

! End of SPARSE_UTIL function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! KppSolve - sparse back substitution
!   Arguments :
!      JVS       - sparse Jacobian of variables
!      X         - Vector for variables
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUBROUTINE KppSolve ( JVS, X )

! JVS - sparse Jacobian of variables
  REAL(kind=dp) :: JVS(LU_NONZERO)
! X - Vector for variables
  REAL(kind=dp) :: X(NVAR)

  X(4) = X(4)-JVS(9)*X(3)
  X(5) = X(5)-JVS(15)*X(1)
  X(6) = X(6)-JVS(21)*X(2)
  X(8) = X(8)-JVS(30)*X(6)-JVS(31)*X(7)
  X(9) = X(9)-JVS(37)*X(2)-JVS(38)*X(5)-JVS(39)*X(6)-JVS(40)*X(7)-JVS(41)*X(8)
  X(10) = X(10)-JVS(46)*X(3)-JVS(47)*X(4)-JVS(48)*X(7)-JVS(49)*X(9)
  X(11) = X(11)-JVS(53)*X(3)-JVS(54)*X(5)-JVS(55)*X(8)-JVS(56)*X(9)-JVS(57)*X(10)
  X(12) = X(12)-JVS(60)*X(1)-JVS(61)*X(4)-JVS(62)*X(7)-JVS(63)*X(9)-JVS(64)*X(10)-JVS(65)*X(11)
  X(12) = X(12)/JVS(66)
  X(11) = (X(11)-JVS(59)*X(12))/(JVS(58))
  X(10) = (X(10)-JVS(51)*X(11)-JVS(52)*X(12))/(JVS(50))
  X(9) = (X(9)-JVS(43)*X(10)-JVS(44)*X(11)-JVS(45)*X(12))/(JVS(42))
  X(8) = (X(8)-JVS(33)*X(9)-JVS(34)*X(10)-JVS(35)*X(11)-JVS(36)*X(12))/(JVS(32))
  X(7) = (X(7)-JVS(28)*X(9)-JVS(29)*X(10))/(JVS(27))
  X(6) = (X(6)-JVS(23)*X(7)-JVS(24)*X(9)-JVS(25)*X(10)-JVS(26)*X(11))/(JVS(22))
  X(5) = (X(5)-JVS(17)*X(8)-JVS(18)*X(9)-JVS(19)*X(11)-JVS(20)*X(12))/(JVS(16))
  X(4) = (X(4)-JVS(11)*X(7)-JVS(12)*X(10)-JVS(13)*X(11)-JVS(14)*X(12))/(JVS(10))
  X(3) = (X(3)-JVS(7)*X(10)-JVS(8)*X(11))/(JVS(6))
  X(2) = (X(2)-JVS(4)*X(6)-JVS(5)*X(9))/(JVS(3))
  X(1) = (X(1)-JVS(2)*X(12))/(JVS(1))
      
END SUBROUTINE KppSolve

! End of KppSolve function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! KppSolveTR - sparse, transposed back substitution
!   Arguments :
!      JVS       - sparse Jacobian of variables
!      X         - Vector for variables
!      XX        - Vector for output variables
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUBROUTINE KppSolveTR ( JVS, X, XX )

! JVS - sparse Jacobian of variables
  REAL(kind=dp) :: JVS(LU_NONZERO)
! X - Vector for variables
  REAL(kind=dp) :: X(NVAR)
! XX - Vector for output variables
  REAL(kind=dp) :: XX(NVAR)

  XX(1) = X(1)/JVS(1)
  XX(2) = X(2)/JVS(3)
  XX(3) = X(3)/JVS(6)
  XX(4) = X(4)/JVS(10)
  XX(5) = X(5)/JVS(16)
  XX(6) = (X(6)-JVS(4)*XX(2))/(JVS(22))
  XX(7) = (X(7)-JVS(11)*XX(4)-JVS(23)*XX(6))/(JVS(27))
  XX(8) = (X(8)-JVS(17)*XX(5))/(JVS(32))
  XX(9) = (X(9)-JVS(5)*XX(2)-JVS(18)*XX(5)-JVS(24)*XX(6)-JVS(28)*XX(7)-JVS(33)*XX(8))/(JVS(42))
  XX(10) = (X(10)-JVS(7)*XX(3)-JVS(12)*XX(4)-JVS(25)*XX(6)-JVS(29)*XX(7)-JVS(34)*XX(8)-JVS(43)*XX(9))/(JVS(50))
  XX(11) = (X(11)-JVS(8)*XX(3)-JVS(13)*XX(4)-JVS(19)*XX(5)-JVS(26)*XX(6)-JVS(35)*XX(8)-JVS(44)*XX(9)-JVS(51)*XX(10))&
             &/(JVS(58))
  XX(12) = (X(12)-JVS(2)*XX(1)-JVS(14)*XX(4)-JVS(20)*XX(5)-JVS(36)*XX(8)-JVS(45)*XX(9)-JVS(52)*XX(10)-JVS(59)*XX(11))&
             &/(JVS(66))
  XX(12) = XX(12)
  XX(11) = XX(11)-JVS(65)*XX(12)
  XX(10) = XX(10)-JVS(57)*XX(11)-JVS(64)*XX(12)
  XX(9) = XX(9)-JVS(49)*XX(10)-JVS(56)*XX(11)-JVS(63)*XX(12)
  XX(8) = XX(8)-JVS(41)*XX(9)-JVS(55)*XX(11)
  XX(7) = XX(7)-JVS(31)*XX(8)-JVS(40)*XX(9)-JVS(48)*XX(10)-JVS(62)*XX(12)
  XX(6) = XX(6)-JVS(30)*XX(8)-JVS(39)*XX(9)
  XX(5) = XX(5)-JVS(38)*XX(9)-JVS(54)*XX(11)
  XX(4) = XX(4)-JVS(47)*XX(10)-JVS(61)*XX(12)
  XX(3) = XX(3)-JVS(9)*XX(4)-JVS(46)*XX(10)-JVS(53)*XX(11)
  XX(2) = XX(2)-JVS(21)*XX(6)-JVS(37)*XX(9)
  XX(1) = XX(1)-JVS(15)*XX(5)-JVS(60)*XX(12)
      
END SUBROUTINE KppSolveTR

! End of KppSolveTR function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! BLAS_UTIL - BLAS-LIKE utility functions
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!--------------------------------------------------------------
!
! BLAS/LAPACK-like subroutines used by the integration algorithms
! It is recommended to replace them by calls to the optimized
!      BLAS/LAPACK library for your machine
!
!  (C) Adrian Sandu, Aug. 2004
!      Virginia Polytechnic Institute and State University
!--------------------------------------------------------------


!--------------------------------------------------------------
      SUBROUTINE WCOPY(N,X,incX,Y,incY)
!--------------------------------------------------------------
!     copies a vector, x, to a vector, y:  y <- x
!     only for incX=incY=1
!     after BLAS
!     replace this by the function from the optimized BLAS implementation:
!         CALL  SCOPY(N,X,1,Y,1)   or   CALL  DCOPY(N,X,1,Y,1)
!--------------------------------------------------------------
!     USE messy_mecca_kpp_Precision
      
      INTEGER  :: i,incX,incY,M,MP1,N
      REAL(kind=dp) :: X(N),Y(N)

      IF (N.LE.0) RETURN

      M = MOD(N,8)
      IF( M .NE. 0 ) THEN
        DO i = 1,M
          Y(i) = X(i)
        END DO
        IF( N .LT. 8 ) RETURN
      END IF    
      MP1 = M+1
      DO i = MP1,N,8
        Y(i) = X(i)
        Y(i + 1) = X(i + 1)
        Y(i + 2) = X(i + 2)
        Y(i + 3) = X(i + 3)
        Y(i + 4) = X(i + 4)
        Y(i + 5) = X(i + 5)
        Y(i + 6) = X(i + 6)
        Y(i + 7) = X(i + 7)
      END DO

      END SUBROUTINE WCOPY


!--------------------------------------------------------------
      SUBROUTINE WAXPY(N,Alpha,X,incX,Y,incY)
!--------------------------------------------------------------
!     constant times a vector plus a vector: y <- y + Alpha*x
!     only for incX=incY=1
!     after BLAS
!     replace this by the function from the optimized BLAS implementation:
!         CALL SAXPY(N,Alpha,X,1,Y,1) or  CALL DAXPY(N,Alpha,X,1,Y,1)
!--------------------------------------------------------------

      INTEGER  :: i,incX,incY,M,MP1,N
      REAL(kind=dp) :: X(N),Y(N),Alpha
      REAL(kind=dp), PARAMETER :: ZERO = 0.0_dp

      IF (Alpha .EQ. ZERO) RETURN
      IF (N .LE. 0) RETURN

      M = MOD(N,4)
      IF( M .NE. 0 ) THEN
        DO i = 1,M
          Y(i) = Y(i) + Alpha*X(i)
        END DO
        IF( N .LT. 4 ) RETURN
      END IF
      MP1 = M + 1
      DO i = MP1,N,4
        Y(i) = Y(i) + Alpha*X(i)
        Y(i + 1) = Y(i + 1) + Alpha*X(i + 1)
        Y(i + 2) = Y(i + 2) + Alpha*X(i + 2)
        Y(i + 3) = Y(i + 3) + Alpha*X(i + 3)
      END DO
      
      END SUBROUTINE WAXPY



!--------------------------------------------------------------
      SUBROUTINE WSCAL(N,Alpha,X,incX)
!--------------------------------------------------------------
!     constant times a vector: x(1:N) <- Alpha*x(1:N) 
!     only for incX=incY=1
!     after BLAS
!     replace this by the function from the optimized BLAS implementation:
!         CALL SSCAL(N,Alpha,X,1) or  CALL DSCAL(N,Alpha,X,1)
!--------------------------------------------------------------

      INTEGER  :: i,incX,M,MP1,N
      REAL(kind=dp)  :: X(N),Alpha
      REAL(kind=dp), PARAMETER  :: ZERO=0.0_dp, ONE=1.0_dp

      IF (Alpha .EQ. ONE) RETURN
      IF (N .LE. 0) RETURN

      M = MOD(N,5)
      IF( M .NE. 0 ) THEN
        IF (Alpha .EQ. (-ONE)) THEN
          DO i = 1,M
            X(i) = -X(i)
          END DO
        ELSEIF (Alpha .EQ. ZERO) THEN
          DO i = 1,M
            X(i) = ZERO
          END DO
        ELSE
          DO i = 1,M
            X(i) = Alpha*X(i)
          END DO
        END IF
        IF( N .LT. 5 ) RETURN
      END IF
      MP1 = M + 1
      IF (Alpha .EQ. (-ONE)) THEN
        DO i = MP1,N,5
          X(i)     = -X(i)
          X(i + 1) = -X(i + 1)
          X(i + 2) = -X(i + 2)
          X(i + 3) = -X(i + 3)
          X(i + 4) = -X(i + 4)
        END DO
      ELSEIF (Alpha .EQ. ZERO) THEN
        DO i = MP1,N,5
          X(i)     = ZERO
          X(i + 1) = ZERO
          X(i + 2) = ZERO
          X(i + 3) = ZERO
          X(i + 4) = ZERO
        END DO
      ELSE
        DO i = MP1,N,5
          X(i)     = Alpha*X(i)
          X(i + 1) = Alpha*X(i + 1)
          X(i + 2) = Alpha*X(i + 2)
          X(i + 3) = Alpha*X(i + 3)
          X(i + 4) = Alpha*X(i + 4)
        END DO
      END IF

      END SUBROUTINE WSCAL

!--------------------------------------------------------------
      REAL(kind=dp) FUNCTION WLAMCH( C )
!--------------------------------------------------------------
!     returns epsilon machine
!     after LAPACK
!     replace this by the function from the optimized LAPACK implementation:
!          CALL SLAMCH('E') or CALL DLAMCH('E')
!--------------------------------------------------------------
!      USE messy_mecca_kpp_Precision

      CHARACTER ::  C
      INTEGER    :: i
      REAL(kind=dp), SAVE  ::  Eps
      REAL(kind=dp)  ::  Suma
      REAL(kind=dp), PARAMETER  ::  ONE=1.0_dp, HALF=0.5_dp
      LOGICAL, SAVE   ::  First=.TRUE.
      
      IF (First) THEN
        First = .FALSE.
        Eps = HALF**(16)
        DO i = 17, 80
          Eps = Eps*HALF
          CALL WLAMCH_ADD(ONE,Eps,Suma)
          IF (Suma.LE.ONE) GOTO 10
        END DO
        PRINT*,'ERROR IN WLAMCH. EPS < ',Eps
        RETURN
10      Eps = Eps*2
        i = i-1      
      END IF

      WLAMCH = Eps

      END FUNCTION WLAMCH
     
      SUBROUTINE WLAMCH_ADD( A, B, Suma )
!      USE messy_mecca_kpp_Precision
      
      REAL(kind=dp) A, B, Suma
      Suma = A + B

      END SUBROUTINE WLAMCH_ADD
!--------------------------------------------------------------


!--------------------------------------------------------------
      SUBROUTINE SET2ZERO(N,Y)
!--------------------------------------------------------------
!     copies zeros into the vector y:  y <- 0
!     after BLAS
!--------------------------------------------------------------
      
      INTEGER ::  i,M,MP1,N
      REAL(kind=dp) ::  Y(N)
      REAL(kind=dp), PARAMETER :: ZERO = 0.0d0

      IF (N.LE.0) RETURN

      M = MOD(N,8)
      IF( M .NE. 0 ) THEN
        DO i = 1,M
          Y(i) = ZERO
        END DO
        IF( N .LT. 8 ) RETURN
      END IF    
      MP1 = M+1
      DO i = MP1,N,8
        Y(i)     = ZERO
        Y(i + 1) = ZERO
        Y(i + 2) = ZERO
        Y(i + 3) = ZERO
        Y(i + 4) = ZERO
        Y(i + 5) = ZERO
        Y(i + 6) = ZERO
        Y(i + 7) = ZERO
      END DO

      END SUBROUTINE SET2ZERO


!--------------------------------------------------------------
      REAL(kind=dp) FUNCTION WDOT (N, DX, incX, DY, incY) 
!--------------------------------------------------------------
!     dot produce: wdot = x(1:N)*y(1:N) 
!     only for incX=incY=1
!     after BLAS
!     replace this by the function from the optimized BLAS implementation:
!         CALL SDOT(N,X,1,Y,1) or  CALL DDOT(N,X,1,Y,1)
!--------------------------------------------------------------
!      USE messy_mecca_kpp_Precision
!--------------------------------------------------------------
      IMPLICIT NONE
      INTEGER :: N, incX, incY
      REAL(kind=dp) :: DX(N), DY(N) 

      ! LK: changed as arithmetic IFs are a deleted Fortran feature.
      !     The respective line is: IF (incX .EQ. incY) IF (incX-1) 5,20,60
      
      WDOT = DOT_PRODUCT(DX, DY)
      
!       INTEGER :: i, IX, IY, M, MP1, NS
!                                 
!       WDOT = 0.0D0 
!       IF (N .LE. 0) RETURN 
!       IF (incX .EQ. incY) IF (incX-1) 5,20,60 
! !                                                                       
! !     Code for unequal or nonpositive increments.                       
! !                                                                       
!     5 IX = 1 
!       IY = 1 
!       IF (incX .LT. 0) IX = (-N+1)*incX + 1 
!       IF (incY .LT. 0) IY = (-N+1)*incY + 1 
!       DO i = 1,N 
!         WDOT = WDOT + DX(IX)*DY(IY) 
!         IX = IX + incX 
!         IY = IY + incY 
!       END DO 
!       RETURN 
! !                                                                       
! !     Code for both increments equal to 1.                              
! !                                                                       
! !     Clean-up loop so remaining vector length is a multiple of 5.      
! !                                                                       
!    20 M = MOD(N,5) 
!       IF (M .EQ. 0) GO TO 40 
!       DO i = 1,M 
!          WDOT = WDOT + DX(i)*DY(i) 
!       END DO 
!       IF (N .LT. 5) RETURN 
!    40 MP1 = M + 1 
!       DO i = MP1,N,5 
!           WDOT = WDOT + DX(i)*DY(i) + DX(i+1)*DY(i+1) + DX(i+2)*DY(i+2) +  &
!                    DX(i+3)*DY(i+3) + DX(i+4)*DY(i+4)                   
!       END DO 
!       RETURN 
! !                                                                       
! !     Code for equal, positive, non-unit increments.                    
! !                                                                       
!    60 NS = N*incX 
!       DO i = 1,NS,incX 
!         WDOT = WDOT + DX(i)*DY(i) 
!       END DO 

      END FUNCTION WDOT                                          


!--------------------------------------------------------------
      SUBROUTINE WADD(N,X,Y,Z)
!--------------------------------------------------------------
!     adds two vectors: z <- x + y
!     BLAS - like
!--------------------------------------------------------------
!     USE messy_mecca_kpp_Precision
      
      INTEGER :: i, M, MP1, N
      REAL(kind=dp) :: X(N),Y(N),Z(N)

      IF (N.LE.0) RETURN

      M = MOD(N,5)
      IF( M /= 0 ) THEN
         DO i = 1,M
            Z(i) = X(i) + Y(i)
         END DO
         IF( N < 5 ) RETURN
      END IF    
      MP1 = M+1
      DO i = MP1,N,5
         Z(i)     = X(i)     + Y(i)
         Z(i + 1) = X(i + 1) + Y(i + 1)
         Z(i + 2) = X(i + 2) + Y(i + 2)
         Z(i + 3) = X(i + 3) + Y(i + 3)
         Z(i + 4) = X(i + 4) + Y(i + 4)
      END DO

      END SUBROUTINE WADD
      
      
      
!--------------------------------------------------------------
      SUBROUTINE WGEFA(N,A,Ipvt,info)
!--------------------------------------------------------------
!     WGEFA FACTORS THE MATRIX A (N,N) BY
!           GAUSS ELIMINATION WITH PARTIAL PIVOTING
!     LINPACK - LIKE 
!--------------------------------------------------------------
!
      INTEGER       :: N,Ipvt(N),info
      REAL(kind=dp) :: A(N,N)
      REAL(kind=dp) :: t, dmax, da
      INTEGER       :: j,k,l
      REAL(kind=dp), PARAMETER :: ZERO = 0.0, ONE = 1.0

      info = 0

size: IF (n > 1) THEN
      
col:  DO k = 1, n-1

!        find l = pivot index
!        l = idamax(n-k+1,A(k,k),1) + k - 1
         l = k; dmax = abs(A(k,k))
         DO j = k+1,n
            da = ABS(A(j,k))
            IF (da > dmax) THEN
              l = j; dmax = da
            END IF
         END DO
         Ipvt(k) = l

!        zero pivot implies this column already triangularized
         IF (ABS(A(l,k)) < TINY(ZERO)) THEN
            info = k
            return
         ELSE   
            IF (l /= k) THEN
               t = A(l,k); A(l,k) = A(k,k); A(k,k) = t
            END IF
            t = -ONE/A(k,k)
            CALL WSCAL(n-k,t,A(k+1,k),1)
            DO j = k+1, n
               t = A(l,j)
               IF (l /= k) THEN
                  A(l,j) = A(k,j); A(k,j) = t
               END IF
               CALL WAXPY(n-k,t,A(k+1,k),1,A(k+1,j),1)
            END DO         
         END IF
         
       END DO col
       
      END IF size
      
      Ipvt(N) = N
      IF (ABS(A(N,N)) == ZERO) info = N
      
      END SUBROUTINE WGEFA


!--------------------------------------------------------------
      SUBROUTINE WGESL(Trans,N,A,Ipvt,b)
!--------------------------------------------------------------
!     WGESL solves the system
!     a * x = b  or  trans(a) * x = b
!     using the factors computed by WGEFA.
!
!     Trans      = 'N'   to solve  A*x = b ,
!                = 'T'   to solve  transpose(A)*x = b
!     LINPACK - LIKE 
!--------------------------------------------------------------

      INTEGER       :: N,Ipvt(N)
      CHARACTER     :: trans
      REAL(kind=dp) :: A(N,N),b(N)
      REAL(kind=dp) :: t
      INTEGER       :: k,kb,l

      
      SELECT CASE (Trans)

      CASE ('n','N')  !  Solve  A * x = b

!        first solve  L*y = b
         IF (n >= 2) THEN
          DO k = 1, n-1
            l = Ipvt(k)
            t = b(l)
            IF (l /= k) THEN
               b(l) = b(k)
               b(k) = t
            END IF
            CALL WAXPY(n-k,t,a(k+1,k),1,b(k+1),1)
          END DO
         END IF
!        now solve  U*x = y
         DO kb = 1, n
            k = n + 1 - kb
            b(k) = b(k)/a(k,k)
            t = -b(k)
            CALL WAXPY(k-1,t,a(1,k),1,b(1),1)
         END DO
      
      CASE ('t','T')  !  Solve transpose(A) * x = b

!        first solve  trans(U)*y = b
         DO k = 1, n
            t = WDOT(k-1,a(1,k),1,b(1),1)
            b(k) = (b(k) - t)/a(k,k)
         END DO
!        now solve trans(L)*x = y
         IF (n >= 2) THEN
         DO kb = 1, n-1
            k = n - kb
            b(k) = b(k) + WDOT(n-k,a(k+1,k),1,b(k+1),1)
            l = Ipvt(k)
            IF (l /= k) THEN
               t = b(l); b(l) = b(k); b(k) = t
            END IF
         END DO
         END IF
   
      END SELECT

      END SUBROUTINE WGESL
! End of BLAS_UTIL function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



 END MODULE messy_mecca_kpp_linearalgebra 


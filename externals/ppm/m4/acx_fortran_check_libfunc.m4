dnl acx_fortran_check_libfunc.m4 --- Check whether calling a certain Fortran
dnl                                  routine succeeds
dnl
dnl Copyright  (C)  2010  Thomas Jahns <jahns@dkrz.de>
dnl
dnl Version: 1.0
dnl Keywords: Fortran library routine support
dnl Author: Thomas Jahns <jahns@dkrz.de>
dnl Maintainer: Thomas Jahns <jahns@dkrz.de>
dnl URL: https://www.dkrz.de/redmine/projects/scales-ppm
dnl
dnl Redistribution and use in source and binary forms, with or without
dnl modification, are  permitted provided that the following conditions are
dnl met:
dnl
dnl Redistributions of source code must retain the above copyright notice,
dnl this list of conditions and the following disclaimer.
dnl
dnl Redistributions in binary form must reproduce the above copyright
dnl notice, this list of conditions and the following disclaimer in the
dnl documentation and/or other materials provided with the distribution.
dnl
dnl Neither the name of the DKRZ GmbH nor the names of its contributors
dnl may be used to endorse or promote products derived from this software
dnl without specific prior written permission.
dnl
dnl THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
dnl IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
dnl TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
dnl PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
dnl OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
dnl EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
dnl PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
dnl PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
dnl LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
dnl NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
dnl SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
dnl
dnl Commentary:
dnl
dnl
dnl
dnl Code:
dnl
dnl ACX_FORTRAN_CHECK_LIBFUNC(SUBROUTINE, ROUTINE-CALL,
dnl   ACTION-IF-TRUE, ACTION-IF-FALSE, [OPTIONAL-PROLOGUE])
dnl   Defines HAVE_FORTRAN_ROUTINE_SUBROUTINE if SUBROUTINE is present
dnl   and a fortran program with ROUTINE-CALL compiles and links
dnl   (after the optional PROLOGUE).
dnl   Also runs shell commands ACTION-IF-* accordingly.
AC_DEFUN([ACX_FORTRAN_CHECK_LIBFUNC],
  [AS_VAR_PUSHDEF([have_fortran_routine],
    [AS_TR_SH([acx_cv_fortran_have_routine_$1])])dnl
   AC_CACHE_CHECK([Fortran subroutine $1], [have_fortran_routine],[
     AC_LANG_PUSH([Fortran])
     AC_LINK_IFELSE([AC_LANG_PROGRAM(,m4_ifval([$5],[      $5
])[      $2])],
       [AS_VAR_SET([have_fortran_routine], [yes])],
       [AS_VAR_SET([have_fortran_routine], [no])])
     AC_LANG_POP([Fortran])])
   AS_IF([test x"AS_VAR_GET([have_fortran_routine])" = xyes],
     [AC_DEFINE(AS_TR_CPP([HAVE_FORTRAN_ROUTINE_$1]), 1,
        [Defined if Fortran routine $1 is available])
        $3],
     [$4])
   AS_VAR_POPDEF([have_fortran_routine])dnl
  ])
dnl Local Variables:
dnl mode: autoconf
dnl license-project-url: "https://www.dkrz.de/redmine/projects/scales-ppm"
dnl license-default: "bsd"
dnl End:

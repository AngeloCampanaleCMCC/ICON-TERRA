from templates import gen_c, gen_c_properties
from structs import glob

print("""/* @authors 11/2023 :: ICON Community Interface  <comin@icon-model.org>

   SPDX-License-Identifier: BSD-3-Clause

   Please see the file LICENSE in the root of the source tree for this code.
   Where software is supplied by third parties, it is indicated in the
   headers of the routines.

*** DO NOT EDIT MANUALLY!  Generated by python script in utils/. DO NOT EDIT MANUALLY! *** */
#ifdef __cplusplus
extern "C"{
#endif""")


gen_c("global", glob, False)
gen_c_properties("global", glob, False)

print("""
#ifdef __cplusplus
} // extern C
#endif""")

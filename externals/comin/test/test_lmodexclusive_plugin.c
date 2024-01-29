#include <string.h>
#include <stdio.h>
#include "comin.h"

void comin_main(){

  int ierr = 0;

  int ilen = -1;
  const char* plugin_name = NULL;
  comin_current_get_plugin_name(&plugin_name, &ilen, &ierr);
  if (ierr != 0) comin_plugin_finish("test_lmodexclusive_plugin: comin_main", "comin_current_get_plugin_info failed for plugin_info");

  struct t_comin_var_descriptor foo_descr = {.id = 1};
  strncpy(foo_descr.name, "foo", MAX_LEN_VAR_NAME);

  struct t_comin_var_descriptor foo_exc_descr = {.id = 1};
  strncpy(foo_exc_descr.name, "foo_exc", MAX_LEN_VAR_NAME);

  int my_id = comin_current_get_plugin_id();
  if(my_id == 1){
    comin_var_request_add(foo_descr, false, &ierr);

    comin_var_request_add(foo_exc_descr, true, &ierr);
  }else{
    // 1. Variable was requested exclusive and is requested again
    comin_var_request_add(foo_exc_descr, false, &ierr);
    if(ierr != COMIN_ERROR_VAR_REQUEST_EXISTS_IS_LMODEXCLUSIVE){
      comin_plugin_finish("test_lmodexclusive: comin_main",
                   "Request lmodexclusive check (variable exists lmodexclusive) broken");
    }else{
      fprintf(stderr, "Check successful: variables cannot be requested if exist with lmodexclusive=true\n");
    }

    // 2. Variable exists and is now requested exclusive
    comin_var_request_add(foo_descr, true, &ierr);
    if(ierr != COMIN_ERROR_VAR_REQUEST_EXISTS_REQUEST_LMODEXCLUSIVE){
      comin_plugin_finish("simple_fortran_plugin: comin_main",
                   "Request lmodexclusive check (variable exists) broken");
    }else{
      fprintf(stderr, "Check successful: variables cannot be requested lmodexclusive=true if exists\n");
    }
  }
}

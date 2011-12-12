/**
 * Similar to GError from GLib.
 */

#include <stdlib.h>		/* malloc, free */

#include "psem_error.h"

struct error {
  int error_source;
  int error_number;
};

error_t *
error_alloc()
{
  return (error_t *) malloc(sizeof (error_t));
}

void
error_free(error_t *err)
{
  free(err);
}

void
error_set(error_t *err, int source, int value)
{
  err->error_source = source;
  err->error_number = value;
}

void
error_new(error_t **err, int source, int value)
{
  if (err != NULL) {
    if (*err == NULL) {
      *err = error_alloc();
      error_set(*err, source, value);
    } else {
      /* tried to create a new error atop an existing error... */
    }
  } else {
    /* error is being ignored by caller */
  }
}

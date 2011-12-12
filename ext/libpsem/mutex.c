#include <stdlib.h>		/* malloc, free */

#include "mutex.h"

size_t sizeof_mutex_t = sizeof (mutex_t);

mutex_t *
mutex_alloc(void) {
  return malloc(sizeof(mutex_t));
}

void
mutex_free(mutex_t * mutex) {
  free(mutex);
}

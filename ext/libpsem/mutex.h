#ifndef __MUTEX_H__
#define __MUTEX_H__

#include "bsem.h"

struct mutex {
  bsem_t *bsem;
};

typedef struct mutex mutex_t;

extern size_t sizeof_mutex_t;

#endif /* __MUTEX_H__ */

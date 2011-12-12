#ifndef __BSEM_H__
#define __BSEM_H__

#include "psem.h"
#include "psem_error.h"

struct bsem {
  psem_t psem;
  psem_t lock;
  int maxvalue;
};

typedef struct bsem bsem_t;

extern size_t sizeof_bsem_t;

bsem_t * bsem_alloc();
void bsem_free(bsem_t *bsem);

int bsem_open(bsem_t *, const char *, unsigned int, unsigned int, error_t **);
int bsem_close(bsem_t *, error_t **);
int bsem_unlink(const char *, error_t **);

int bsem_post(bsem_t *, error_t **);
int bsem_wait(bsem_t *, error_t **);
int bsem_trywait(bsem_t *, error_t **);
int bsem_timedwait(bsem_t *, float, error_t **);

int bsem_getvalue(bsem_t *, int *, error_t **);

#endif /* __BSEM_H__ */


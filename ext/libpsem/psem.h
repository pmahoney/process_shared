#ifndef __PSEM_H__
#define __PSEM_H__

/**
 * Portable semaphore interface focusing on cross-process use.
 */

#ifdef HAVE_SEM_OPEN
#include "psem_posix.h"
#endif

#include "psem_error.h"

typedef struct psem psem_t;

extern size_t sizeof_psem_t;

extern int OK;
extern int ERROR;

extern int E_SOURCE_SYSTEM;
extern int E_SOURCE_PSEM;

extern int E_NAME_TOO_LONG;

int psem_errno();

psem_t * psem_alloc();
void psem_free(psem_t *);

int psem_open(psem_t *, const char *, unsigned int, error_t **);
int psem_close(psem_t *, error_t **);
int psem_unlink(const char *, error_t **);

int psem_post(psem_t *, error_t **);

int psem_wait(psem_t *, error_t **);
int psem_trywait(psem_t *, error_t **);
int psem_timedwait(psem_t *, float, error_t **);

int psem_getvalue(psem_t *, int *, error_t **);

#endif /* __PSEM_H__ */

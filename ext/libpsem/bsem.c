/*
 * Extensions atop psem.  Recursive mutex, bounded semaphore.
 */

#include <stdlib.h>		/* malloc, free */

#include "mempcpy.h"            /* includes string.h */
#include "psem.h"
#include "psem_error.h"
#include "bsem.h"

#define MAX_NAME 128            /* This is much less the POSIX max
                                   name. Users of this library must
                                   not use longer names. */

static const char bsem_lock_suffix[] = "-bsem-lock";

#define MAX_LOCK_NAME (MAX_NAME + strlen(bsem_lock_suffix) + 1)

/**
 * Assumes dest has sufficient space to hold "[MAX_NAME]-bsem-lock".
 */
static int
make_lockname(char *dest, const char *name, error_t **err)
{
  int namelen;

  namelen = strlen(name);
  if (namelen > MAX_NAME) {
    error_new(err, E_SOURCE_PSEM, E_NAME_TOO_LONG);
    return ERROR;
  }

  *((char *) mempcpy(mempcpy(dest, name, namelen),
                     bsem_lock_suffix,
                     strlen(bsem_lock_suffix))) = '\0';
}

size_t sizeof_bsem_t = sizeof (bsem_t);

bsem_t *
bsem_alloc(void) {
  return malloc(sizeof(bsem_t));
}

void
bsem_free(bsem_t *bsem) {
  free(bsem);
}

#define call_or_return(exp)					\
  do { if ((exp) == ERROR) { return ERROR; } } while (0)

#define bsem_lock_or_return(bsem, err) call_or_return(bsem_lock((bsem), (err)))

#define bsem_unlock_or_return(bsem, err) call_or_return(bsem_unlock((bsem), (err)))

int
bsem_open(bsem_t *bsem, const char *name, unsigned int maxvalue, unsigned int value, error_t **err)
{
  char lockname[MAX_LOCK_NAME];

  call_or_return(psem_open(&bsem->psem, name, value, err));
  call_or_return(make_lockname(lockname, name, err));
  call_or_return(psem_open(&bsem->lock, lockname, 1, err));

  bsem->maxvalue = maxvalue;
  
  return OK;
}

static int
bsem_lock(bsem_t *bsem, error_t **err)
{
  call_or_return(psem_wait(&bsem->lock, err));
  return OK;
}

static int
bsem_unlock(bsem_t *bsem, error_t **err)
{
  call_or_return(psem_post(&bsem->lock, err));
  return OK;
}

int
bsem_close(bsem_t *bsem, error_t **err)
{
  bsem_lock_or_return(bsem, err);

  if (psem_close(&bsem->psem, err) == ERROR) {
    bsem_unlock(bsem, NULL);
    return ERROR;
  }

  bsem_unlock_or_return(bsem, err);

  call_or_return(psem_close(&bsem->lock, err));
  return OK;
}

int
bsem_unlink(const char *name, error_t **err)
{
  char lockname[MAX_LOCK_NAME];

  call_or_return(psem_unlink(name, err));
  call_or_return(make_lockname(lockname, name, err));
  call_or_return(psem_unlink(lockname, err));
  return OK;
}

int
bsem_post(bsem_t *bsem, error_t **err)
{
  int sval;

  bsem_lock_or_return(bsem, err);

  /* FIXME: maxvalue is broken on some systems... (cygwin? mac?) */
  if (psem_getvalue(&bsem->psem, &sval, err) == ERROR) {
    bsem_unlock(bsem, err);
    return ERROR;
  }

  if (sval >= bsem->maxvalue) {
    /* ignored silently */
    bsem_unlock(bsem, err);
    return OK;
  }

  if (psem_post(&bsem->psem, err) == ERROR) {
    bsem_unlock(bsem, err);
    return ERROR;
  }

  bsem_unlock_or_return(bsem, err);
  return OK;
}

int
bsem_wait(bsem_t *bsem, error_t **err)
{
  call_or_return(psem_wait(&bsem->psem, err));
  return OK;
}

int
bsem_trywait(bsem_t *bsem, error_t **err)
{
  bsem_lock_or_return(bsem, err);

  if (psem_trywait(&bsem->psem, err) == ERROR) {
    bsem_unlock(bsem, NULL);
    return ERROR;
  }

  bsem_unlock_or_return(bsem, err);
  return OK;
}

int
bsem_timedwait(bsem_t *bsem, float timeout_s, error_t **err)
{
  bsem_lock_or_return(bsem, err);

  if (psem_timedwait(&bsem->psem, timeout_s, err) == ERROR) {
    bsem_unlock(bsem, NULL);
    return ERROR;
  }

  bsem_unlock_or_return(bsem, err);
  return OK;
}

int
bsem_getvalue(bsem_t *bsem, int *sval, error_t **err)
{
  bsem_lock_or_return(bsem, err);

  if (psem_getvalue(&bsem->psem, sval, err) == ERROR) {
    bsem_unlock(bsem, NULL);
    return ERROR;
  }

  bsem_unlock_or_return(bsem, err);
  return OK;
}

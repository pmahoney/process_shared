/*
 *  A type which wraps a semaphore
 *
 *  semaphore.c
 *
 *  Copyright (c) 2006-2008, R Oudkerk
 *
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above
 *     copyright notice, this list of conditions and the following
 *     disclaimer in the documentation and/or other materials provided
 *     with the distribution.
 *
 *  3. Neither the name of author nor the names of any contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR
 *  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 *  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 *  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Modifications Copyright (c) 2011, Patrick Mahoney
 */

#include <errno.h>
#include <fcntl.h>		/* For O_* constants */
#include <sys/stat.h>		/* For mode constants */
#include <semaphore.h>
#include <stdlib.h>		/* malloc, free */
#include <math.h>		/* floorf */
#include <time.h>		/* timespec */

#include "psem.h"
#include "psem_posix.h"

psem_t *
psem_alloc(void) {
  return (psem_t *) malloc(sizeof(psem_t));
}

void
psem_free(psem_t *psem) {
  free(psem);
}

#define errcheck_val(expr, errval, err)			\
  do {							\
    if ((expr) == (errval)) {				\
      error_new((err), E_SOURCE_SYSTEM, errno);		\
      return ERROR;					\
    }							\
    return OK;						\
  } while (0)

#define errcheck(expr, err) errcheck_val((expr), -1, (err))

int
psem_open(psem_t *psem, const char *name, unsigned int value, error_t **err)
{
  errcheck_val(psem->sem = sem_open(name, O_CREAT | O_EXCL, 0600, value),
	       SEM_FAILED,
	       err);
}

int
psem_close(psem_t *psem, error_t **err)
{
  errcheck(sem_close(psem->sem), err);
}

int
psem_unlink(const char *name, error_t **err)
{
  errcheck(sem_unlink(name), err);
}

int
psem_post(psem_t *psem, error_t **err)
{
  errcheck(sem_post(psem->sem), err);
}

int
psem_wait(psem_t *psem, error_t **err)
{
  errcheck(sem_wait(psem->sem), err);
}

int
psem_trywait(psem_t *psem, error_t **err)
{
  errcheck(sem_trywait(psem->sem), err);
}

int
psem_timedwait(psem_t *psem, float timeout_s, error_t **err)
{
  struct timespec abs_timeout;

  abs_timeout.tv_sec = floorf(timeout_s);
  abs_timeout.tv_nsec =
    floorf((timeout_s - abs_timeout.tv_sec) * (1000 * 1000 * 1000));

  errcheck(sem_timedwait(psem->sem, &abs_timeout), err);
}

int
psem_getvalue(psem_t *psem, int *sval, error_t **err)
{
  errcheck(sem_getvalue(psem->sem, sval), err);
}

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
  } while (0)

#define errcheck(expr, err) errcheck_val((expr), -1, (err))

int
psem_open(psem_t *psem, const char *name, unsigned int value, error_t **err)
{
  errcheck_val(psem->sem = sem_open(name, O_CREAT | O_EXCL, 0600, value),
	       SEM_FAILED,
	       err);
  return OK;
}

int
psem_close(psem_t *psem, error_t **err)
{
  errcheck(sem_close(psem->sem), err);
  return OK;
}

int
psem_unlink(const char *name, error_t **err)
{
  errcheck(sem_unlink(name), err);
  return OK;
}

int
psem_post(psem_t *psem, error_t **err)
{
  errcheck(sem_post(psem->sem), err);
  return OK;
}

int
psem_wait(psem_t *psem, error_t **err)
{
  errcheck(sem_wait(psem->sem), err);
  return OK;
}

int
psem_trywait(psem_t *psem, error_t **err)
{
  errcheck(sem_trywait(psem->sem), err);
  return OK;
}

#define NS_PER_S (1000 * 1000 * 1000)
#define US_PER_NS (1000)
#define TV_NSEC_MAX (NS_PER_S - 1)

int
psem_timedwait(psem_t *psem, float timeout_s, error_t **err)
{
  struct timeval now;
  struct timespec abs_timeout;

  errcheck(gettimeofday(&now, NULL), err);
  abs_timeout.tv_sec = now.tv_sec;
  abs_timeout.tv_nsec = now.tv_usec * US_PER_NS;

  /* Fun with rounding: careful adding reltive timeout to abs time */
  {
    time_t sec;		/* relative timeout */
    long nsec;
  
    sec = floorf(timeout_s);
    nsec = floorf((timeout_s - floorf(timeout_s)) * NS_PER_S);

    abs_timeout.tv_sec += sec;
    abs_timeout.tv_nsec += nsec;

    while (abs_timeout.tv_nsec > TV_NSEC_MAX) {
      abs_timeout.tv_sec += 1;
      abs_timeout.tv_nsec -= NS_PER_S;
    }
  }

  errcheck(sem_timedwait(psem->sem, &abs_timeout), err);
  return OK;
}

int
psem_getvalue(psem_t *psem, int *sval, error_t **err)
{
  errcheck(sem_getvalue(psem->sem, sval), err);
  return OK;
}


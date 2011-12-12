#ifndef __PSEM_POSIX_H__
#define __PSEM_POSIX_H__

#include <semaphore.h>

struct psem {
  sem_t *sem;
};

#endif  /* __PSEM_POSIX_H__ */

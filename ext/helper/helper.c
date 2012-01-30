/****************************/
/* File descriptor controls */
/****************************/

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
extern int o_rdwr;
int o_rdwr = O_RDWR;
extern int o_creat;
int o_creat = O_CREAT;
extern int o_excl;
int o_excl = O_EXCL;
#endif

/************************/
/* Memory Map constants */
/************************/

#ifdef HAVE_SYS_MMAN_H
#include <sys/mman.h>

extern int prot_read;
extern int prot_write;
extern int prot_exec;
extern int prot_none;

extern void * map_failed;
extern int map_shared;
extern int map_private;

int prot_read = PROT_READ;
int prot_write = PROT_WRITE;
int prot_exec = PROT_EXEC;
int prot_none = PROT_NONE;

void * map_failed = MAP_FAILED;
int map_shared = MAP_SHARED;
int map_private = MAP_PRIVATE;
#endif

/****************************************/
/* PThread and related types and macros */
/****************************************/

#ifdef HAVE_PTHREAD_H
#include <pthread.h>
extern int pthread_process_shared;
int pthread_process_shared = PTHREAD_PROCESS_SHARED;
#endif

#ifdef HAVE_TYPE_PTHREAD_MUTEX_T
extern size_t sizeof_pthread_mutex_t;
size_t sizeof_pthread_mutex_t = sizeof (pthread_mutex_t);
size_t sizeof_pthread_mutexattr_t = sizeof (pthread_mutexattr_t);
#endif

#ifdef HAVE_TYPE_PTHREAD_MUTEXATTR_T
extern size_t sizeof_pthread_mutexattr_t;
#endif

/******************/
/* Semaphore type */
/******************/

#ifdef HAVE_TYPE_SEM_T
#include <semaphore.h>
extern size_t sizeof_sem_t;
size_t sizeof_sem_t = sizeof (sem_t);
#endif


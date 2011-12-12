#include "psem.h"

int OK = 0;
int ERROR = -1;

int E_SOURCE_SYSTEM = 1;
int E_SOURCE_PSEM = 2;

int E_NAME_TOO_LONG = 1;

#ifdef HAVE_SEM_OPEN
#include "psem_posix.c"
#endif

size_t sizeof_psem_t = sizeof (psem_t);

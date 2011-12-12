/**
 * Define and extern various constants defined as macros.
 */

#include <sys/mman.h>		/* PROT_*, MAP_* */
#include <fcntl.h>		/* O_* */

#include "constants.h"

int o_rdwr = O_RDWR;
int o_creat = O_CREAT;
int o_excl = O_EXCL;

int prot_read = PROT_READ;
int prot_write = PROT_WRITE;
int prot_exec = PROT_EXEC;
int prot_none = PROT_NONE;

void * map_failed = MAP_FAILED;

int map_shared = MAP_SHARED;
int map_private = MAP_PRIVATE;

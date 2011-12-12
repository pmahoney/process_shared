#ifndef __MEMPCPY_H__
#define __MEMPCPY_H__

#ifdef HAVE_MEMPCPY
#define __USE_GNU
#else
#include <stdlib.h>
void *mempcpy(void *, const void *, size_t);
#endif

#include <string.h>

#endif	/* __MEMPCPY_H__ */

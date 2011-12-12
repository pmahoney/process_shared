#ifndef __PSEM_ERROR_H__
#define __PSEM_ERROR_H__

typedef struct error error_t;

error_t * error_alloc();
void error_free(error_t *);

void error_set(error_t *, int, int);

#endif	/* __PSEM_ERROR_H__ */

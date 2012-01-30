require 'mkmf'

have_header('fcntl.h')

have_header('sys/mman.h')

have_header('semaphore.h')
have_type('sem_t', 'semaphore.h')

have_header('pthread.h')
have_type('pthread_mutex_t', 'pthread.h')
have_type('pthread_mutexattr_t', 'pthread.h')

create_makefile('helper')

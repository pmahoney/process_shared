require 'mkmf'

$objs = []

# posix semaphores
if have_func('sem_open', 'semaphore.h')
  have_func('floorf', 'math.h') or abort("Missing required floorf() in math.h")
  have_library('m', 'floorf')

  unless have_func('mempcpy', 'string.h')
    $objs << 'mempcpy.o'
  end

  have_library('rt', 'sem_open')
end

c_sources = ['psem.c', 'psem_error.c', 'psem_posix.c', 'bsem.c', 'constants.c']
$objs += ['psem.o', 'psem_error.o', 'bsem.o', 'constants.o']

depend_rules <<-END
psem.c: psem.h psem_posix.c
psem_error.c: psem_error.h

bsem.h: psem.h psem_error.h
bsem.c: psem.h psem_error.h bsem.h

constants.c: constants.h
mempcpy.c: mempcpy.h

#{$objs.map { |o| "#{o}: #{o.chomp(".o")}.c" }.join("\n")}

libpsem.o: #{$objs.join(' ')}
END


create_makefile('libpsem')

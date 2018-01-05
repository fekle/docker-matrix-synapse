// see https://github.com/esnme/ultrajson/issues/254#issuecomment-314862445

#include <dlfcn.h>
#include <pthread.h>

typedef int (*func_t)(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void*), void *arg);

int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void*), void *arg) {
  pthread_attr_t local;
  int used = 0, ret;

  if (!attr) {
    used = 1;
    pthread_attr_init(&local);
    attr = &local;
  }
  pthread_attr_setstacksize((void*)attr, 4 * 1024 * 1024);

  func_t orig = (func_t)dlsym(RTLD_NEXT, "pthread_create");

  ret = orig(thread, attr, start_routine, arg);

  if (used) {
    pthread_attr_destroy(&local);
  }

  return ret;
}

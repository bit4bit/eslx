#include "libesl.h"

#define MUST_STATE(env) if(env->state == NULL) return unifex_raise(env, "not initialize state, please call `init` first")

UNIFEX_TERM global_set_default_logger(UnifexEnv* env, LoggerLevel level) {
  int esl_level = ESL_LOG_LEVEL_INFO;

  switch(level) {
  case LOGGER_LEVEL_EMERG:
    esl_level = ESL_LOG_LEVEL_EMERG;
    break;
  case LOGGER_LEVEL_ALERT:
    esl_level = ESL_LOG_LEVEL_ALERT;
    break;
  case LOGGER_LEVEL_CRIT:
    esl_level = ESL_LOG_LEVEL_CRIT;
    break;
  case LOGGER_LEVEL_ERROR:
    esl_level = ESL_LOG_LEVEL_ERROR;
    break;
  case LOGGER_LEVEL_WARNING:
    esl_level = ESL_LOG_LEVEL_WARNING;
    break;
  case LOGGER_LEVEL_NOTICE:
    esl_level = ESL_LOG_LEVEL_NOTICE;
    break;
  case LOGGER_LEVEL_INFO:
    esl_level = ESL_LOG_LEVEL_INFO;
    break;
  case LOGGER_LEVEL_DEBUG:
    esl_level = ESL_LOG_LEVEL_DEBUG;
    break;
  default:
    esl_level = ESL_LOG_LEVEL_INFO;
  }

  esl_global_set_default_logger(esl_level);

  return global_set_default_logger_result(env);
}

UNIFEX_TERM connect_timeout(UnifexEnv *env, char *host, int port, char *user, char *password, int timeout) {
  MUST_STATE(env);
  esl_status_t status;
  State *state = (State *)env->state;

  if (strcmp(user, "") == 0) {
    status = esl_connect_timeout(&state->handle, host, port, NULL, password, timeout);
  } else {
    status = esl_connect_timeout(&state->handle, host, port, user, password, timeout);
  }

  switch(status) {
  case ESL_SUCCESS:
    return connect_timeout_result(env);
  case ESL_FAIL:
    return connect_timeout_result_error(env, "fail");
  case ESL_BREAK:
    return connect_timeout_result_error(env, "break");
  case ESL_DISCONNECTED:
    return connect_timeout_result_error(env, "disconnected");
  case ESL_GENERR:
    return connect_timeout_result_error(env, "generr");
  }
}

UNIFEX_TERM init(UnifexEnv *env) {
  State *state = (State *)unifex_alloc_state(env);

  return init_result_ok(env, state);
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  unifex_release_state(env, state);
}

#include "libesl_events.h"

#define MUST_STATE(env) if(env->state == NULL) return unifex_raise(env, "not initialize state, please call `init` first")
#define check_esl_status(env, status, result)        \
  {                                                  \
  State *state = (State *)env->state;                \
  switch(status) {                                   \
  case ESL_FAIL:                                     \
    return result ## _result_error(env, "fail");     \
  case ESL_BREAK:                                    \
    return result ## _result_error(env, "break");     \
  case ESL_DISCONNECTED:                                  \
    return result ## _result_error(env, "disconnected");  \
  case ESL_GENERR:                                        \
    return result ## _result_error(env, "generr");        \
  }\
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

  check_esl_status(env, status, connect_timeout);
  if(status == ESL_SUCCESS)
    state->polling_events = 1;
  return connect_timeout_result(env);
}

UNIFEX_TERM events(UnifexEnv *env, char *values) {
  MUST_STATE(env);
  State *state = (State *)env->state;

  esl_status_t status = esl_events(&state->handle, ESL_EVENT_TYPE_PLAIN, values);
  check_esl_status(env, status, events);
  return events_result(env);
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  unifex_release_state(env, state);
}

int handle_main(int argc, char **argv) {
  UnifexEnv env;

  if (unifex_cnode_init(argc, argv, &env)) {
    return 1;
  }

  State *state = (State *)unifex_alloc_state(&env);
  state->polling_events = 0;
  env.state = state;

  // TODO: when this fail LibESL.Events blocks the process why?
  // reproducible? run multiple times the test
  while (!unifex_cnode_receive(&env)) {
    if (state->polling_events == 0)
      continue;
    esl_status_t status = esl_recv_timed(&state->handle, 5);
    if (status == ESL_FAIL || status == ESL_DISCONNECTED || status == ESL_GENERR) {
      break;
    }

    if (status == ESL_SUCCESS) {
      const char *type = esl_event_get_header(state->handle.last_event, "content-type");
      if (type && !strcasecmp(type, "text/disconnect-notice")) {
        break;
      }
      char *json;
      esl_event_serialize_json(state->handle.last_ievent, &json);
      send_esl_event(&env, *(env.reply_to), 0, json);
      if (json)
        free(json);
    }
  }
  esl_disconnect(&state->handle);
  unifex_cnode_destroy(&env);
  return 0;
}

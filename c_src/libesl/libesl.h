#pragma once
#include "esl.h"

#include <unifex/unifex.h>

typedef struct State State;
struct State {
  UnifexEnv *env;
  esl_handle_t handle;
};

#include "_generated/libesl.h"

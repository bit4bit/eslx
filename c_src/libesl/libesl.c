#include "libesl.h"

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

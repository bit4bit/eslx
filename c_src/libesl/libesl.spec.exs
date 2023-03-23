module LibESL

interface [CNode]

type logger_level :: :emerg | :alert | :crit | :error | :warning | :notice | :info | :debug

spec global_set_default_logger(level :: logger_level) :: :ok

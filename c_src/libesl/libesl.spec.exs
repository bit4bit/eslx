module LibESL

interface [CNode]

state_type "State"

spec init() :: {:ok :: label, state}

type logger_level :: :emerg | :alert | :crit | :error | :warning | :notice | :info | :debug

spec global_set_default_logger(level :: logger_level) :: :ok
spec connect_timeout(host :: string, port :: int, user :: string, password :: string, timeout :: int) :: :ok | {:error :: label, atom()}

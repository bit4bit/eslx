module(LibESL)

interface([CNode])

callback(:main)

state_type("State")

type(logger_level :: :emerg | :alert | :crit | :error | :warning | :notice | :info | :debug)

spec(global_set_default_logger(level :: logger_level) :: :ok)

spec(
  connect_timeout(host :: string, port :: int, user :: string, password :: string, timeout :: int) ::
    :ok | {:error :: label, atom()}
)

spec(
  send_recv_timed(cmd :: string, timeout :: int) ::
    {:ok :: label, string()} | {:error :: label, atom()}
)

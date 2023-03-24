module(LibESL.Events)

interface([CNode])

callback(:main)

state_type("State")

spec(
  connect_timeout(host :: string, port :: int, user :: string, password :: string, timeout :: int) ::
    :ok | {:error :: label, atom()}
)

spec(events(values :: string) :: :ok | {:error :: label, atom()})

sends({:esl_event :: label, data :: string})

use std::sync::RwLock;
use std::net::TcpStream;
use std::net::SocketAddr;
use std::time::Duration;
use std::sync::Arc;
use std::collections::HashMap;

use rustler::types::atom;
use rustler::types::Encoder;
use rustler::types::LocalPid;
use rustler::thread;
use rustler::{Env, NifResult, Term, Atom};
use rustler::resource::ResourceArc;
use freeswitch_esl_rs as fs;

type FSConn = Arc<RwLock<fs::Client<TcpStream>>>;

struct State {
  client: FSConn
}

#[rustler::nif(schedule = "DirtyIo")]
fn start_link<'a>(env: Env<'a>,
                  listener: LocalPid,
                  host: &'a str, port: i32,
                  password: &'a str,
                  timeout: u64) -> NifResult<ResourceArc<State>> {
  let saddr: SocketAddr = format!("{}:{}", host, port).parse().expect("fails to parse address");
  let Ok(stream) = TcpStream::connect_timeout(&saddr, Duration::from_secs(timeout)) else {
    return Err(rustler::error::Error::Atom("fails to connect"));
  };
  let Ok(_) = stream.set_read_timeout(Some(Duration::from_secs(60))) else {
    return Err(rustler::error::Error::Atom("fails to connect"));
  };

  let conn = fs::Connection::new(stream);
  let mut client = fs::Client::new(conn);

  let Ok(_) = client.auth(password) else {
    return Err(rustler::error::Error::Atom("invalid_password"));
  };

  let client = Arc::new(RwLock::new(client));
  let listener_client = client.clone();
  let state = ResourceArc::new(State{
    client: client
  });
  spawn_dispatcher(env, listener, listener_client);

  Ok(state)
}

#[rustler::nif(schedule = "DirtyIo")]
fn events<'a>(env: Env<'a>, state: ResourceArc<State>, name: &'a str) -> NifResult<Term<'a>> {
  let mut client = state.client.write().unwrap();
  let Ok(_) = client.event(name) else {
    return Err(rustler::error::Error::Atom("invalid_event"));
  };
  Ok(atom::ok().to_term(env))
}

fn spawn_dispatcher(env: Env<'_>, listener: LocalPid, client: FSConn) {
  thread::spawn::<thread::ThreadSpawner, _>(env, move |env: Env<'_>| {
    loop {
      let mut client = client.write().unwrap();
      let result = client.pull_event();
      // TODO: freeswitch-esl-rs must allow multiple writers
      drop(client);

      match result {
        Ok(event) => {
          let dto: HashMap<String, String> = event.into();
          // {:esl_event, %{...}}_
          env.send(&listener, (atom_from_str(env, "eslx"), (atom_from_str(env, "event"), dto)).encode(env));
        }
        Err(error) => {
          let ret_err = match error {
            fs::ClientError::ConnectionClose =>
              //{:eslx, :connection_closed}
              (atom_from_str(env, "eslx"), atom_from_str(env, "connection_closed")).encode(env),
            _ =>
            //{:esl, {:error, "..."}}
              (atom_from_str(env, "eslx"), (atom_from_str(env, "error"), format!("{}", error))).encode(env)
          };
          env.send(&listener, ret_err);
          return ret_err;
        }
      }
    }
  });
}

fn atom_from_str(env: Env, name: &str) -> Atom {
  Atom::from_str(env, name).unwrap()
}

fn load(env: Env, _: Term) -> bool {
  rustler::resource!(State, env);
  true
}

rustler::init!("Elixir.ESLx.FreeswitchESLRs.Events", [start_link, events], load = load);

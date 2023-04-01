use std::sync::RwLock;
use std::net::TcpStream;
use std::net::SocketAddr;
use std::time::Duration;
use std::sync::Arc;

use rustler::types::Encoder;
use rustler::{Env, NifResult, Term, Atom};
use rustler::resource::ResourceArc;
use freeswitch_esl_rs as fs;

type FSConn = Arc<RwLock<fs::Client<TcpStream>>>;

struct State {
  client: FSConn
}

#[rustler::nif(schedule = "DirtyIo")]
fn start_link<'a>(env: Env<'a>,
                  host: &'a str,
                  port: i32,
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

  let state = ResourceArc::new(State{
    client: Arc::new(RwLock::new(client))
  });

  Ok(state)
}

#[rustler::nif(schedule = "DirtyIo")]
fn api<'a>(env: Env<'a>, state: ResourceArc<State>, cmd: &'a str, arg: &'a str, _timeout: u64) -> NifResult<Term<'a>> {
  let mut client = state.client.write().unwrap();
  match client.api(cmd, arg) {
    Ok(result) =>
      Ok((atom_from_str(env, "ok"), result).encode(env)),
    Err(error) =>
      match error {
        fs::ClientError::ConnectionClose =>
          Ok((atom_from_str(env, "connection_closed")).encode(env)),
        fs::ClientError::IOError(_) =>
          Ok((atom_from_str(env, "error"), atom_from_str(env, "io_error")).encode(env)),
        fs::ClientError::ParseError(_) =>
          Ok((atom_from_str(env, "error"), atom_from_str(env, "argument_error")).encode(env))
      }
  }
}

#[rustler::nif(schedule = "DirtyIo")]
fn close<'a>(env: Env<'a>, state: ResourceArc<State>) -> NifResult<Term<'a>> {
  drop(state);

  Ok(atom_from_str(env, "ok").encode(env))
}

fn atom_from_str(env: Env, name: &str) -> Atom {
  Atom::from_str(env, name).unwrap()
}

fn load(env: Env, _: Term) -> bool {
  rustler::resource!(State, env);
  true
}


rustler::init!("Elixir.ESLx.FreeswitchESLRs.API", [start_link, api, close], load = load);

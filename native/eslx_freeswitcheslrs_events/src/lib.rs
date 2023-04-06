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

type FSConn = fs::Client<TcpStream>;

#[rustler::nif(schedule = "DirtyIo")]
fn start_link<'a>(env: Env<'a>,
                  listener: LocalPid,
                  host: &'a str, port: i32,
                  password: &'a str,
                  events: &'a str,
                  timeout: u64) -> NifResult<()> {
  let saddr: SocketAddr = format!("{}:{}", host, port).parse().expect("fails to parse address");
  let Ok(stream) = TcpStream::connect_timeout(&saddr, Duration::from_secs(timeout)) else {
    return Err(rustler::error::Error::Atom("fails to connect"));
  };
  let Ok(stream_params) = stream.try_clone() else {
    return Err(rustler::error::Error::Atom("fails clone stream"));
  };

  let Ok(_) = stream_params.set_read_timeout(Some(Duration::from_secs(5))) else {
    return Err(rustler::error::Error::Atom("set timeout"));
  };

  let conn = fs::Connection::new(stream);
  let mut client = fs::Client::new(conn);

  let Ok(_) = client.auth(password) else {
    return Err(rustler::error::Error::Atom("invalid_password"));
  };

  let Ok(_) = client.event(events) else {
    return Err(rustler::error::Error::Atom("invalid_event"));
  };

  let Ok(_) = stream_params.set_read_timeout(Some(Duration::from_secs(45))) else {
    return Err(rustler::error::Error::Atom("set timeout"));
  };
  spawn_dispatcher(env, listener, client);

  Ok(())
}

fn spawn_dispatcher(env: Env<'_>, listener: LocalPid, mut client: FSConn) {
  thread::spawn::<thread::ThreadSpawner, _>(env, move |env: Env<'_>| {
    let client = &mut client;
    loop {
      let result = client.pull_event();

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
  true
}

rustler::init!("Elixir.ESLx.FreeswitchESLRs.Events", [start_link], load = load);

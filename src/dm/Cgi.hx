// Copyright 06-Jun-2021 ºDeme
// GNU General Public License - V3 <http://www.gnu.org/licenses/>

package dm;

import dm.Path;
import dm.Cryp;
import dm.Opt;
import dm.Dt;

private class User {
  public final id: String;
  public final pass: String;
  public final level: String;

  public function new (id: String, pass: String, level: String) {
    this.id = id;
    this.pass = pass;
    this.level = level;
  }

  public function toJs (): Js {
    return Js.wa([
      Js.ws(id),
      Js.ws(pass),
      Js.ws(level)
    ]);
  }

  public static function fromJs (js: Js): User {
    final a = js.ra();
    return new User(
      a[0].rs(),
      a[1].rs(),
      a[2].rs()
    );
  }
}

private class Session {
  public final id: String;
  public final comKey: String;
  public final conKey: String;
  public final user: String;
  public final level: String;
  public final time: Float;
  public final lapse: Int;

  public function new (
    id: String, comKey: String, conKey: String,
    user: String, level: String,
    time: Float, lapse: Int
  ) {
    this.id = id;
    this.comKey = comKey;
    this.conKey = conKey;
    this.user = user;
    this.level = level;
    this.time = time;
    this.lapse = lapse;
  }

  public function toJs (): Js {
    return Js.wa([
      Js.ws(id),
      Js.ws(comKey),
      Js.ws(conKey),
      Js.ws(user),
      Js.ws(level),
      Js.wf(time),
      Js.wi(lapse)
    ]);
  }

  public static function fromJs (js: Js): Session {
    final a = js.ra();
    return new Session(
      a[0].rs(),
      a[1].rs(),
      a[2].rs(),
      a[3].rs(),
      a[4].rs(),
      a[5].rf(),
      a[6].ri()
    );
  }
}

/// Utilities for HTML conections between client - server.
class Cgi {
  /// Standard password length.
  public static final klen = 300;
  /// Seconds == 30 days
  public static final tNoExpiration = 2592000;
  public static final demeKey =
    "nkXliX8lg2kTuQSS/OoLXCk8eS4Fwmc+N7l6TTNgzM1vdKewO0cjok51vcdl" +
    "OKVXyPu83xYhX6mDeDyzapxL3dIZuzwyemVw+uCNCZ01WDw82oninzp88Hef" +
    "bn3pPnSMqEaP2bOdX+8yEe6sGkc3IO3e38+CqSOyDBxHCqfrZT2Sqn6SHWhR" +
    "KqpJp4K96QqtVjmXwhVcST9l+u1XUPL6K9HQfEEGMGcToMGUrzNQxCzlg2g+" +
    "Hg55i7iiKbA0ogENhEIFjMG+wmFDNzgjvDnNYOaPTQ7l4C8aaPsEfl3sugiw";
  public static final noSessionKey = "nosession";

  public static var home(default, null): String;

  // File password.
  static final fkey = Cryp.key(demeKey, demeKey.length);
  static var tExpiration: Int;

  // PRIVATE FUNCTIONS -------------------------------------------------------

  // USERS

  static function writeUsers (users: Array<User>): Void {
    final js = Js.wArray(users, u -> u.toJs());
    File.write(Path.cat([home, "users.db"]), Cryp.cryp(fkey, js.to()));
  }

  static function readUsers (): Array<User> {
    final js = Js.from(Cryp.decryp(
      fkey, File.read(Path.cat([home, "users.db"]))
    ));
    return js.rArray(User.fromJs);
  }

  // SESSIONS

  // If 's' is in time, returns a new session with 's.time' updated. Otherwise
  // return None.
  static function updateSession (s: Session): Option<Session> {
    final now = Date.now().getTime() / 1000.0;
    if (s.time + cast(s.lapse, Float) < now) return None;
    return Some(new Session(
      s.id, s.comKey, s.conKey, s.user, s.level, now, s.lapse
    ));
  }

  static function writeSessions (ss: Array<Session>): Void {
    final js = Js.wArray(ss, s -> s.toJs());
    File.write(Path.cat([home, "sessions.db"]), Cryp.cryp(fkey, js.to()));
  }

  static function readSessions (): Array<Session> {
    final js = Js.from(Cryp.decryp(
      fkey, File.read(Path.cat([home, "sessions.db"]))
    ));
    return js.rArray(Session.fromJs);
  }

  // Adds session and purges sessions.
  static function addSession (
    sessionId: String, comKey: String, conKey: String,
    user: String, level: String, lapse: Int
  ): Void {
    final now = Date.now().getTime() / 1000.0;
    final newSessions = readSessions().filter(s ->
      s.time + cast(s.lapse, Float) >= now
    );
    newSessions.push(
      new Session(sessionId, comKey, conKey, user, level, now, lapse)
    );
    writeSessions(newSessions);
  }

  // Replace one session
  static function replaceSession (s: Session): Void {
    final newSessions = readSessions().filter(oldS -> oldS.id != s.id);
    newSessions.push(s);
    writeSessions(newSessions);
  }

  // PUBLIC FUNCTIONS --------------------------------------------------------

  /// Initializes a new interface of commnications and returns 'true' if
  /// the home directory does not existe when it is called.
  ///   home       : Abslute path of application directory. For example:
  ///                   "/peter/wwwcgi/dmcgi/JsMon"
  ///                   or
  ///                   "/home/deme/.dmCApp/JsMon".
  ///   tExpiration: Time in seconds.
  public static function init (home: String, tExpiration: Int): Bool {
    Cgi.home = home;
    Cgi.tExpiration = tExpiration;

    final create = !File.exists(home);
    if (create) {
      File.mkdir(home);
      writeUsers([]);
      putUser("admin", demeKey, "0");
      writeSessions([]);
    }
    return create;
  }

  // USERS


  /// Adds or modifies an user.
  public static function putUser (
    id: String, pass: String, level: String
  ): Void {
    pass = Cryp.key(pass, klen);
    final users = readUsers();
    final newUser = new User(id, pass, level);
    var add = true;
    for (i in 0...users.length) {
      final u = users[i];
      if (u.id == id) {
        add = false;
        users[i] = newUser;
      }
    }
    if (add) users.push(newUser);
    writeUsers(users);
  }

  /// Removes an user.
  public static function delUser (id: String): Void {
    final users = readUsers();
    writeUsers(users.filter(u -> u.id != id));
  }

  /// Check user password and returns:
  ///   - If user exsits and password is correct, the user level.
  ///   - Otherwise, an empty string.
  public static function checkUser (id: String, pass: String): String {
    pass = Cryp.key(pass, klen);
    for (u in readUsers()) {
      if (u.id == id && u.pass == pass) return u.level;
    }
    return "";
  }

  // MANAGEMENT

  /// Sends to client 'communicationKey', 'userId' and 'userLevel'. If
  /// conection fails every one is "".
  ///   sessionId: Session identifier.
  ///   return   : Response with next fields:
  ///                 key   : String
  ///                 conKey:String
  ///                 user  : String
  ///                 level : String.
  public static function connect (sessionId: String): String {
    final failRp = rp(sessionId, [
      "key" => Js.ws(""),
      "conKey" => Js.ws(""),
      "user" => Js.ws(""),
      "level" => Js.ws("")
    ]);
    switch (It.from(readSessions()).find(s -> s.id == sessionId)) {
      case Some(s): {
        switch (updateSession(s)) {
          case Some(s): {
            final conKey = Cryp.genK(klen);
            replaceSession(new Session(
              s.id, s.comKey, conKey, s.user, s.level, s.time, s.lapse
            ));
            return rp(sessionId, [
              "key" => Js.ws(s.comKey),
              "conKey" => Js.ws(conKey),
              "user" => Js.ws(s.user),
              "level" => Js.ws(s.level)
            ]);
          }
          case None: return failRp;
        }
      }
      case None: return failRp;
    }
  }

  /// Sends to client 'sessionId', 'communicationKey' and 'userLevel'. If
  /// conection fails every one is "".
  ///   key           : Communication key
  ///   user          : User id.
  ///   pass          : User password.
  ///   withExpiration: If is set to false, session will expire after 30 days.
  ///   return        : Response with next fields:
  ///                     sessionId: String
  ///                     key      : String
  ///                     conKey   : String
  ///                     level    : String
  public static function authentication (
    key: String, user: String, pass: String, withExpiration: Bool
  ): String {
    var sessionId = "";
    var comKey = "";
    var conKey = "";
    var level = checkUser(user, pass);

    if (level != "") {
      sessionId = Cryp.genK(klen);
      comKey = Cryp.genK(klen);
      conKey = Cryp.genK(klen);
      final lapse = withExpiration ? tExpiration : tNoExpiration;

      addSession(sessionId, comKey, conKey, user, level, lapse);
    }

    return rp(key, [
      "sessionId" => Js.ws(sessionId),
      "key" => Js.ws(comKey),
      "conKey" => Js.ws(conKey),
      "level" => Js.ws(level),
    ]);
  }

  /// Returns the session communication key if ssId is a valid session.
  ///	  ssId  : Session identifier.
  ///   conKey: Connection key. If its value is "", this parameter is not used.
  public static function getComKey (
    ssId: String, conKey: String
  ): Option<String> {
    switch (It.from(readSessions()).find(s -> s.id == ssId)) {
      case Some(s): {
        if (conKey != "" && conKey != s.conKey) return None;

        switch (updateSession(s)) {
          case Some(s): return Some(s.comKey);
          case None: return None;
        }
      }
      case None: return None;
    }
  }

  /// Changes user password.
  /// The operation will fail if 'user' authentication fails.
  ///    ck     : Communication key
  ///    user   : User id to change password.
  ///    oldPass: Old password.
  ///    newPass: New password.
  ///    return : Response with next field:
  ///               ok: Bool ('true' if operation succeds)
  public static function changePass (
    ck: String, user: String, oldPass: String, newPass: String
  ): String {
    var ok = false;
    final us = readUsers();
    for (i in 0...us.length) {
      final u = us[i];
      if (u.id == user) {
        if (Cryp.key(oldPass, klen) == u.pass) {
          us[i] = new User(u.id, Cryp.key(newPass, klen), u.level);
          writeUsers(us);
          ok = true;
        }
        break;
      }
    }
    return rp(ck, ["ok" => Js.wb(ok)]);
  }

  /// Deletes 'sessionId' and returns an empty response.
  ///    ck      : Communication key
  ///	  sessionId: Session identifier.
  public static function delSession (ck: String, sessionId: String): String {
    writeSessions(readSessions().filter(s -> s.id != sessionId));
    return rpEmpty(ck);
  }

  // RESPONSES

  // Returns a generic response to send to client.
  //	 ck: Communication key.
  //	 rp: Response.
  public static function rp (ck: String, rp: Map<String, Js>): String {
    return Cryp.cryp(ck, Js.wo(rp).to());
  }

  // Returns an empty response.
  //	 ck: Communication key.
  public static function rpEmpty (ck: String): String {
    return rp(ck, []);
  }

  // Returns a message with an only field "error" with value 'msg'.
  //	 ck: Communication key.
  public static function rpError (ck: String, msg: String): String {
    return rp(ck, ["error" => Js.ws(msg)]);
  }

  // Returns a message with an only field "expired" with value 'true',
  // codified with the key 'noSessionKey' ("nosession")
  public static function rpExpired (): String {
    return rp(noSessionKey, ["expired" => Js.wb(true)]);
  }

  // REQUESTS

  // Reads a Bool value
  public static function rqBool (rq: Map<String, Js>, key: String): Bool {
    final js = rq.get(key);
    if (js == null) {
      throw new haxe.Exception('Key "$key" not found in request');
    }
    return js.rb();
  }

  // Reads an Int value
  public static function rqInt (rq: Map<String, Js>, key: String): Int {
    final js = rq.get(key);
    if (js == null) {
      throw new haxe.Exception('Key "$key" not found in request');
    }
    return js.ri();
  }

  // Reads a Float value
  public static function rqFloat (rq: Map<String, Js>, key: String): Float {
    final js = rq.get(key);
    if (js == null) {
      throw new haxe.Exception('Key "$key" not found in request');
    }
    return js.rf();
  }

  // Reads a String value
  public static function rqString (rq: Map<String, Js>, key: String): String {
    final js = rq.get(key);
    if (js == null) {
      throw new haxe.Exception('Key "$key" not found in request');
    }
    return js.rs();
  }
}

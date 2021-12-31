// Copyright 03-Mar-2021 ºDeme
// GNU General Public License - V3 <http://www.gnu.org/licenses/>

using StringTools;

import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import dm.Test;
import dm.File;
import dm.Dt;

class FileTest {
  public static function main () {
    final t = new Test("File");
    final dataDir = "/dm/dmHaxe/lib/svhxlib/tests/data";
    File.cd(dataDir);
    t.yes(File.cwd().endsWith(dataDir + "/"));

    final fileDir = dataDir + "/file";
    final tmpDir = fileDir + "/tmp";

    File.mkdir(tmpDir);
    File.mkdir(tmpDir);
    t.yes(File.exists(tmpDir));
    t.yes(File.isDirectory(tmpDir));

    final tx = "A text\nof two lines";
    final bs = Bytes.ofString(tx);
    final fileTxt = fileDir + "/tmp.txt";
    final fileTxtCopy = fileDir + "/tmpCopy.txt";
    final fileBin = fileDir + "/tmp.bin";

    File.write(fileTxt, "A text\nof two lines");
    t.eq(File.read(fileTxt), tx);
    File.copy(fileTxt, fileTxtCopy);
    t.eq(File.read(fileTxtCopy), tx);

    var tx2: Array<String> = [];
    final ftx = File.ropen(fileTxt);
    File.readLines(ftx, l -> tx2.push(l));
    ftx.close();
    t.eq(tx2.join("\n"), tx);

    var fwbin = File.wopen(fileBin);
    File.writeBytes(fwbin, bs);
    fwbin.close();

    var fbin = File.ropen(fileBin);
    var bs2 = File.readAll(fbin);
    fbin.close();
    t.eq(bs2.toString(), tx);

    for (len in [10, 100]) {
      fbin = File.ropen(fileBin);
      var bf = new BytesBuffer();
      while (true) {
        final tmp = File.readBytes(fbin, len);
        bf.add(tmp);
        if (tmp.length < len) break;
      }
      fbin.close();
      t.eq(bf.getBytes().toString(), tx);
    }

    final dirList = File.dir(fileDir);
    t.eq(dirList.length, 4);
    for (e in File.dir(fileDir)) {
      if (e == "tmp") {
        t.yes(File.isDirectory(fileDir + "/" + e));
      } else {
        final binStat = File.stat(fileDir + "/tmp.bin");
        if (e == "tmp.bin") {
          t.yes(Dt.eqTime(File.stat(fileDir + "/" + e).ctime, binStat.ctime));
          t.yes(Dt.eqTime(File.stat(fileDir + "/" + e).atime, binStat.atime));
          t.yes(Dt.eqTime(File.stat(fileDir + "/" + e).mtime, binStat.mtime));
        }
        t.yes(File.stat(fileDir + "/" + e).uid == binStat.uid);
        t.yes(File.stat(fileDir + "/" + e).size == 19);
      }
    }

    File.del(fileDir);
    t.yes(!File.exists(fileDir));

    t.log();
  }
}

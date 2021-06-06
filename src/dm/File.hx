// Copyright 03-Mar-2021 ºDeme
// GNU General Public License - V3 <http://www.gnu.org/licenses/>

package dm;

import sys.FileSystem;
import sys.FileStat;
import sys.io.File as HxFile;
import sys.io.FileOutput;
import sys.io.FileInput;
import haxe.io.Bytes;

/// Utilities for file management.
class File {
  /// Returns true if 'path' exists in the file system.
  inline public static function exists (path: String): Bool {
    return sys.FileSystem.exists(path);
  }

  /// Returns true if 'path' is a Directory of the file system.
  inline public static function isDirectory (path: String): Bool {
    return sys.FileSystem.isDirectory(path);
  }

  /// Sets the working directory
  inline public static function cd (path: String): Void {
    Sys.setCwd(path);
  }

  /// Returns the working directory
  inline public static function cwd (): String {
    return Sys.getCwd();
  }

  /// Makes a directory.
  /// If parent directory does not exist it creates it.
  /// If 'path' already exists it does nothing.
  inline public static function mkdir (path: String): Void {
    FileSystem.createDirectory(path);
  }

  /// Returns a list with the directory entries.
  /// Values '.' and '..' are not in return.
  inline public static function dir (path: String): Array<String> {
    return FileSystem.readDirectory(path);
  }

  /// Returns data from a file. Among others:
  ///   .size (Int) - Bytes of file.
  ///   .mtime (Date) - Last modificatoin date.
  ///   .atime (Date) - Last access date.
  ///   .ctime (Date) - Last creation date.
  ///   .uid (Int) - User id.
  ///   .gid (Int) - Group id.
  inline public static function stat (path: String): FileStat {
    return FileSystem.stat(path);
  }

  /// Read a text file.
  /// This function opens, reads and closes file.
  inline public static function read (path: String): String {
    return HxFile.getContent(path);
  }

  /// Write a text file.
  /// This function opens, writes and closes file.
  inline public static function write (path: String, tx: String): Void {
    HxFile.saveContent(path, tx);
  }

  /// Copy source to target.
  inline public static function copy (source: String, target: String): Void {
    HxFile.copy(source, target);
  }

  /// Remove recursively 'path'.
  inline public static function del (path: String): Void {
    if (isDirectory(path)) {
      for (e in dir(path)) {
        del(path + "/" + e);
      }
      FileSystem.deleteDirectory(path);
    } else {
      FileSystem.deleteFile(path);
    }
  }

  /// Open a file for writing.
  /// 'FileOutput' must be closed.
  ///
  ///   final f = wopen("file");
  ///   ...
  ///   f.close();
  inline public static function wopen (path: String): FileOutput {
    return HxFile.write(path);
  }

  /// Open a file for appending.
  /// 'FileOutput' must be closed.
  ///
  ///   final f = aopen("file");
  ///   ...
  ///   f.close();
  inline public static function aopen (path: String): FileOutput {
    return HxFile.append(path);
  }

  /// Write bytes in FileOutput.
  inline public static function writeBytes (fo: FileOutput, bs: Bytes): Void {
    fo.write(bs);
  }

  /// Write a text in FileOutput.
  inline public static function writeText (fo: FileOutput, tx: String): Void {
    fo.writeString(tx);
  }

  /// Open a file for reading.
  /// 'FileInput' must be closed.
  ///
  ///   final f = ropen("file");
  ///   ...
  ///   f.close();

  inline public static function ropen (path: String): FileInput {
    return HxFile.read(path);
  }

  /// Read 'buf' bytes.
  /// If the returned Bytes length is less than 'buf', reading is finished.
  inline public static function readBytes (
    fi: FileInput, buf = 8192
  ): Bytes {
    var bs = Bytes.alloc(buf);
    final len = fi.readBytes(bs, 0, buf);
    if (len < buf) {
      final bs2 = Bytes.alloc(len);
      bs2.blit(0, bs, 0, len);
      bs = bs2;
    }
    return bs;
  }

  /// Read all the remain bytes of 'fi'.
  inline public static function readAll (fi: FileInput): Bytes {
    return fi.readAll();
  }

  /// Read a text line, removing the line separator.
  /// When end of file is reached, readLine throws a haxe.io.Eof.
  inline public static function readLine (fi: FileInput): String {
    return fi.readLine();
  }

  /// Runs 'fn' with each line of 'fi' (The file separator is removed)
  inline public static function readLines (
    fi: FileInput, fn: String -> Void
  ): Void {
    while (true) {
      try {
        fn(fi.readLine());
      } catch (ex: haxe.io.Eof) {
        break;
      }
    }
  }

}

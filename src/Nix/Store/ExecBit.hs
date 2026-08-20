-- | The executable bit, on a platform that does not have one.
--
-- A NAR records, for every regular file, whether it is executable, and a
-- store path's identity is the hash of that serialization.  On Unix the
-- bit is the file's own mode and there is nothing to arrange.  Windows has
-- no such bit: NTFS carries a @FILE_EXECUTE@ right in the DACL, but it is
-- a per-principal ACE inherited from the parent directory rather than a
-- property of the file, git does not set it, and
-- 'System.Directory.getPermissions' does not read it -- on Windows that
-- function answers from the file's EXTENSION.  So a checked-out @configure@
-- serializes as non-executable and a tracked @foo.exe@ serializes as
-- executable, whatever either one actually is.
--
-- The consequences are not cosmetic.  The substituter unpacks a downloaded
-- NAR and requires the tree to reproduce the hash the narinfo declares;
-- with the bit lost on unpack it cannot, so any cached path holding an
-- executable without an executable extension is downloaded, rejected, and
-- deleted.  Measured, not deduced: the same NAR round-trips byte-identically
-- on Linux and differs on Windows.
--
-- So the bit is stored where the filesystem will keep it: an NTFS alternate
-- data stream named 'execStreamName' on the file itself.  Its presence IS
-- the bit; the contents are never read.  A stream is addressable through
-- ordinary file IO (@path:stream@), is invisible to 'Dir.listDirectory' so
-- it never appears as a tree entry of its own, does not change the file's
-- size or contents, and is removed with the file.
--
-- Two constraints come with it, both load-bearing:
--
--   * A stream cannot be written to a read-only file, so a mark must be set
--     BEFORE a store path is sealed.  Reading one back from a read-only file
--     is fine, which is the direction that matters afterwards.
--
--   * 'Dir.copyFile' copies only the unnamed stream, so a copy drops the
--     mark.  'copyExecMark' carries it across explicitly, and every copy
--     into the store goes through it.
--
-- On Unix all of this collapses to the mode bit, and 'serialiseFromPath' is
-- exactly nova-cache's -- the correction pass does not run at all.
module Nix.Store.ExecBit
  ( isExecutable,
    markExecutable,
    copyExecMark,
    serialiseFromPath,
    execStreamName,
  )
where

import Control.Monad (when)
import qualified Data.ByteString.Char8 as BS8
import qualified NovaCache.NAR as NAR
import qualified System.Directory as Dir
import System.FilePath ((</>))
import qualified System.Info

-- | The alternate data stream whose presence marks a file executable.
-- Named for this project so it cannot collide with @Zone.Identifier@ or
-- another tool's stream.
execStreamName :: String
execStreamName = "nova.exec"

-- | Whether the exec bit needs the stream representation.  A plain
-- comparison rather than CPP: the same binary is not built for both, but
-- keeping one code path means the Unix branch is type-checked on Windows
-- and vice versa.
usesStream :: Bool
usesStream = System.Info.os == "mingw32"

-- | The stream that marks a file, addressable through ordinary file IO.
execStreamPath :: FilePath -> FilePath
execStreamPath path = path ++ ":" ++ execStreamName

-- | Whether a regular file is executable, by whichever representation the
-- platform keeps it in.
isExecutable :: FilePath -> IO Bool
isExecutable path
  | usesStream = Dir.doesFileExist (execStreamPath path)
  | otherwise = Dir.executable <$> Dir.getPermissions path

-- | Mark a regular file executable.  Must be called before the file is made
-- read-only: a stream cannot be created on a read-only file.
markExecutable :: FilePath -> IO ()
markExecutable path
  | usesStream = BS8.writeFile (execStreamPath path) (BS8.pack "1")
  | otherwise = do
      perms <- Dir.getPermissions path
      Dir.setPermissions path (Dir.setOwnerExecutable True perms)

-- | Carry a file's exec mark from one path to another.  'Dir.copyFile'
-- copies the unnamed stream only, so without this a copy silently
-- de-executables its result.
copyExecMark :: FilePath -> FilePath -> IO ()
copyExecMark from to = do
  exec <- isExecutable from
  when exec (markExecutable to)

-- | 'NovaCache.NAR.serialiseFromPath', with every regular file's executable
-- flag taken from 'isExecutable' rather than from the file's permissions.
--
-- The walk is nova-cache's own -- name safety, case-hack folding and entry
-- ordering are subtle and belong there -- and this only rewrites the flags
-- it produced.  On Unix those flags are already right, so the tree is
-- returned untouched.
serialiseFromPath :: FilePath -> IO NAR.NarEntry
serialiseFromPath path = do
  entry <- NAR.serialiseFromPath path
  if usesStream then correct path entry else pure entry
  where
    correct p (NAR.NarRegular _ contents) = do
      exec <- isExecutable p
      pure (NAR.NarRegular exec contents)
    correct p (NAR.NarDirectory entries) =
      -- The on-disk child is the entry's name: nova-cache folds a name only
      -- when the platform would collide on it, and a folded name is the one
      -- the directory actually holds.
      NAR.NarDirectory <$> mapM (\(n, e) -> (,) n <$> correct (p </> BS8.unpack n) e) entries
    correct _ e@(NAR.NarSymlink _) = pure e

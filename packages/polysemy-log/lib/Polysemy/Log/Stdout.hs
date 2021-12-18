-- |Description: Internal
module Polysemy.Log.Stdout where

import qualified Data.Text.IO as Text
import Polysemy.Async (Async)
import Polysemy.Conc (Race)
import Polysemy.Resource (Resource)
import Polysemy.Time (GhcTime, interpretTimeGhc)

import Polysemy.Log.Data.DataLog (DataLog)
import Polysemy.Log.Data.Log (Log)
import Polysemy.Log.Data.LogEntry (LogEntry)
import Polysemy.Log.Data.LogMessage (LogMessage)
import Polysemy.Log.Format (formatLogEntry)
import Polysemy.Log.Log (interpretDataLog, interpretLogDataLog, interpretLogDataLogConc)
import Polysemy.Log.Data.Severity (Severity)
import Polysemy.Log.Level (setLogLevel)

-- |Interpret 'DataLog' by printing to stdout, converting messages to 'Text' with the supplied function.
interpretDataLogStdoutWith ::
  Member (Embed IO) r =>
  (a -> Text) ->
  InterpreterFor (DataLog a) r
interpretDataLogStdoutWith fmt =
  interpretDataLog \ msg -> embed (Text.hPutStrLn stdout (fmt msg))
{-# inline interpretDataLogStdoutWith #-}

-- |Interpret 'DataLog' by printing to stdout, converting messages to 'Text' by using 'Show'.
interpretDataLogStdout ::
  Show a =>
  Member (Embed IO) r =>
  InterpreterFor (DataLog a) r
interpretDataLogStdout =
  interpretDataLogStdoutWith show
{-# inline interpretDataLogStdout #-}

-- |Interpret 'Log' by printing to stdout, converting messages to 'Text' with the supplied function.
interpretLogStdoutWith ::
  Members [Embed IO, GhcTime] r =>
  (LogEntry LogMessage -> Text) ->
  InterpreterFor Log r
interpretLogStdoutWith fmt =
  interpretDataLogStdoutWith fmt .
  interpretTimeGhc .
  interpretLogDataLog .
  raiseUnder2
{-# inline interpretLogStdoutWith #-}

-- |Like 'interpretLogStdoutWith', but setting a log level.
-- 'Nothing' causes no messages to be logged.
interpretLogStdoutLevelWith ::
  Members [Embed IO, GhcTime] r =>
  (LogEntry LogMessage -> Text) ->
  Maybe Severity ->
  InterpreterFor Log r
interpretLogStdoutLevelWith fmt level =
  interpretDataLogStdoutWith fmt .
  setLogLevel level .
  interpretTimeGhc .
  interpretLogDataLog .
  raiseUnder2
{-# inline interpretLogStdoutLevelWith #-}

-- |Interpret 'Log' by printing to stdout, using the default formatter.
--
-- Since this adds a timestamp, it has a dependency on 'GhcTime'.
-- Use 'interpretLogStdout'' for a variant that interprets 'GhcTime' in-place.
interpretLogStdout ::
  Members [Embed IO, GhcTime] r =>
  InterpreterFor Log r
interpretLogStdout =
  interpretLogStdoutWith formatLogEntry
{-# inline interpretLogStdout #-}

-- |Like 'interpretLogStdout', but setting a log level.
-- 'Nothing' causes no messages to be logged.
interpretLogStdoutLevel ::
  Members [Embed IO, GhcTime] r =>
  Maybe Severity ->
  InterpreterFor Log r
interpretLogStdoutLevel =
  interpretLogStdoutLevelWith formatLogEntry
{-# inline interpretLogStdoutLevel #-}

-- |Interpret 'Log' by printing to stdout, using the default formatter, then interpreting 'GhcTime'.
interpretLogStdout' ::
  Member (Embed IO) r =>
  InterpreterFor Log r
interpretLogStdout' =
  interpretTimeGhc .
  interpretLogStdout .
  raiseUnder
{-# inline interpretLogStdout' #-}

-- |Like 'interpretLogStdout', but process messages concurrently.
interpretLogStdoutConc ::
  Members [Resource, Async, Race, Embed IO] r =>
  InterpreterFor Log r
interpretLogStdoutConc =
  interpretTimeGhc .
  interpretDataLogStdoutWith formatLogEntry .
  interpretLogDataLogConc 64 .
  raiseUnder2
{-# inline interpretLogStdoutConc #-}

-- |Like 'interpretLogStdout', but process messages concurrently.
interpretLogStdoutLevelConc ::
  Members [Resource, Async, Race, Embed IO] r =>
  Maybe Severity ->
  InterpreterFor Log r
interpretLogStdoutLevelConc level =
  interpretTimeGhc .
  interpretDataLogStdoutWith formatLogEntry .
  setLogLevel level .
  interpretLogDataLogConc 64 .
  raiseUnder2
{-# inline interpretLogStdoutLevelConc #-}

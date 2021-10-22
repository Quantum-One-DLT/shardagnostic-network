{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE BangPatterns        #-}
{-# LANGUAGE GADTs               #-}
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving  #-}

module Shardagnostic.Network.Protocol.LocalTxSubmission.Examples (
    localTxSubmissionClient,
    localTxSubmissionServer,
  ) where

import           Shardagnostic.Network.Protocol.LocalTxSubmission.Client
import           Shardagnostic.Network.Protocol.LocalTxSubmission.Server



--
-- Example client
--

-- | An example @'LocalTxSubmissionClient'@ which submits a fixed list of
-- transactions. The result is those transactions annotated with whether they
-- were accepted or rejected.
--
localTxSubmissionClient
  :: forall tx reject m.
     Applicative m
  => [tx]
  -> LocalTxSubmissionClient tx reject m [(tx, SubmitResult reject)]
localTxSubmissionClient =
    LocalTxSubmissionClient . pure . client []
  where
    client acc [] =
      SendMsgDone (reverse acc)

    client acc (tx:txs) =
      SendMsgSubmitTx tx $ \mreject -> pure (client ((tx, mreject):acc) txs)


--
-- Example server
--

localTxSubmissionServer
  :: forall tx reject m.
     Applicative m
  => (tx -> SubmitResult reject)
  -> LocalTxSubmissionServer tx reject m [(tx, SubmitResult reject)]
localTxSubmissionServer p =
    server []
  where
    server acc = LocalTxSubmissionServer {
      recvMsgSubmitTx = \tx ->
        let mreject = p tx in
        pure (mreject, server ((tx, mreject) : acc)),

      recvMsgDone = reverse acc
    }


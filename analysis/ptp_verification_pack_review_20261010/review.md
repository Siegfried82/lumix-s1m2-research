# Supplied PTP verification pack review

The supplied S1RM2 experiment logs have matching transaction identifiers for all commands and final OK responses: 11 clock-run transactions, 7 configuration-run transactions. Independently decoded DATA headers show clock years 2030, 2030, 2031, 2030 at transactions 3, 5, 7, 9. This addresses the earlier stale-response concern for these recorded runs.

Configuration import transaction 4 receives its own OK; transactions 3 and 5 export 9,197,337-byte payloads and the log reports equal SHA-256 and byte equality. This supports accepted identity import in the reported run. It does not demonstrate modified settings being applied or persisted across reboot.

ZIP contains text logs and scripts, but no complete binary snapshots. Container headers and clock bytes were independently parsed; full configuration hashes and equality remain log-reported, not independently recomputed. Logs are supplied evidence, not an independently witnessed device test.

The revised client reads through a response, resolving the original early-return flaw. Remaining robustness issues: mismatched response is warned but accepted; DATA tid/opcode are not validated; truncated containers are not rejected; trailing coalesced containers are discarded; timeout breaks do not increment the no-response counter; caller decisions do not require final OK. These do not contradict the matching responses visible in the supplied successful runs.

Scope: S1RM2 USB/Tether; no proof for S1M2, serial-number changes, generic firmware writes, full protocol recovery, security-key extraction or firmware plaintext. No vendor script executed and no camera accessed.

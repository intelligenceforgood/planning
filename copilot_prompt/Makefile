SAVE_SESSION=save-session
REHYDRATE=rehydrate

.PHONY: $(SAVE_SESSION) $(REHYDRATE)

save-session:
	@./session_snapshot.sh

rehydrate:
	@./session_rehydrate.sh

help:
	@echo "Makefile targets for Copilot snapshot/rehydration"
	@echo "  save-session: write a copilot snapshot to COPILOT_SESSION.md"
	@echo "  rehydrate: print the COPILOT_SESSION.md snapshot"

.PHONY: update
update:
	@nix flake update

# Might need sudo
.PHONY: system
system:
	@darwin-rebuild switch --flake .#hostname

result: .build-timestamp
	@# result symlink already created by .build-timestamp rule

.build-timestamp: flake.nix darwin-configuration.nix home.nix
	@darwin-rebuild build --flake .#hostname
	@touch .build-timestamp

.PHONY: diff
diff: result
	@echo "nvd:"
	@nix shell 'nixpkgs#nvd' --command nvd diff /run/current-system ./result

	@echo ""
	@echo "nix-diff:"
	@nix shell 'nixpkgs#nix-diff' --command nix-diff /run/current-system ./result

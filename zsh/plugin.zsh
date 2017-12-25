source ~/.zsh/antigen.zsh

# Bundles from the default repo 
antigen bundles <<EOBUNDLES
	# Bundles from the default repo
	git

	# Syntax highlighting bundle.
	zsh-users/zsh-syntax-highlighting

	# Fish-like auto suggestions
	zsh-users/zsh-autosuggestions

	# Extra zsh completions
	zsh-users/zsh-completions

	# autoenv
	kennethreitz/autoenv

	# zsh-history-substring-search
	zsh-users/zsh-history-substring-search

EOBUNDLES

# Tell antigen that you're done.
antigen apply

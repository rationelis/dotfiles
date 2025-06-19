vim.g.rustaceanvim = {
	server = {
		default_settings = {
			["rust-analyzer"] = {
				rustc = {
					source = "discover",
				},
				cargo = {
					allFeatures = true,
				},
			},
		},
	},
}
